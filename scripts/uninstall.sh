#!/usr/bin/env bash
set -euo pipefail

NRB_VERSION="v1.5.1"
XRAY_BIN="${XRAY_BIN:-/usr/local/bin/xray}"
XRAY_CONFIG_DIR="${XRAY_CONFIG_DIR:-/etc/xray}"
XRAY_CONFIG="${XRAY_CONFIG:-${XRAY_CONFIG_DIR}/config.json}"
XRAY_SHARE_DIR="${XRAY_SHARE_DIR:-/usr/local/share/xray}"
XRAY_SERVICE="${XRAY_SERVICE:-/etc/systemd/system/xray.service}"
SUPERVISOR_PROGRAM="${SUPERVISOR_PROGRAM:-nat-reality-bridge-xray}"
SUPERVISOR_CONFIG="${SUPERVISOR_CONFIG:-/etc/supervisor/conf.d/${SUPERVISOR_PROGRAM}.conf}"
STATE_DIR="${STATE_DIR:-/var/lib/nat-reality-bridge}"
STATE_FILE="${STATE_FILE:-${STATE_DIR}/install-state}"
APP_DIR="${APP_DIR:-/root/nat-reality-bridge}"
BACKUP_ROOT="${BACKUP_ROOT:-/root/xray-backups}"
MANAGED_DIR="${MANAGED_DIR:-/etc/nat-reality-bridge}"
MANAGED_MARKER="${MANAGED_MARKER:-${MANAGED_DIR}/managed.marker}"

[ "$(id -u)" = "0" ] || { echo "This uninstall script must run as root." >&2; exit 1; }

detect_service_backend() {
  local pid1
  pid1="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')"
  if [ "$pid1" = "systemd" ] && command -v systemctl >/dev/null 2>&1 && \
     systemctl show --property=Version --value >/dev/null 2>&1 && \
     systemctl list-units --type=service --no-legend --no-pager >/dev/null 2>&1; then
    printf '%s\n' "systemd"
  elif command -v supervisorctl >/dev/null 2>&1 && supervisorctl status >/dev/null 2>&1; then
    printf '%s\n' "supervisor"
  else
    printf '%s\n' "unknown"
  fi
}

marker_value() {
  local key="$1"
  [ -f "$MANAGED_MARKER" ] || return 0
  awk -F= -v key="$key" '$1 == key {sub($1 "=", ""); print; exit}' "$MANAGED_MARKER"
}

is_valid_managed_marker() {
  local marker_id
  [ -f "$MANAGED_MARKER" ] || return 1
  [ ! -L "$MANAGED_MARKER" ] || return 1
  [ -O "$MANAGED_MARKER" ] || return 1
  [ "$(stat -c '%a' "$MANAGED_MARKER" 2>/dev/null || true)" = "600" ] || return 1
  [ "$(marker_value project)" = "NAT Reality Bridge" ] || return 1
  [ "$(marker_value marker_format)" = "1" ] || return 1
  [ -n "$(marker_value installed_at)" ] || return 1
  marker_id="$(marker_value install_id)"
  [[ "$marker_id" =~ ^[a-f0-9]{32}$ ]]
}

section_protocol_count() {
  local section="$1"
  local next_section="$2"
  awk -v section="\"${section}\"" -v next_section="\"${next_section}\"" '
    $0 ~ section { inside=1; next }
    inside && $0 ~ next_section { exit }
    inside && /"protocol"[[:space:]]*:/ { count++ }
    END { print count + 0 }
  ' "$XRAY_CONFIG"
}

is_supported_single_node_config() {
  [ -f "$XRAY_CONFIG" ] || return 0
  local inbound_count outbound_count
  inbound_count="$(section_protocol_count inbounds outbounds)"
  outbound_count="$(section_protocol_count outbounds routing)"
  if [ "$outbound_count" -eq 0 ]; then
    outbound_count="$(awk '/"outbounds"/ { inside=1; next } inside && /"protocol"[[:space:]]*:/ { count++ } END { print count + 0 }' "$XRAY_CONFIG")"
  fi
  [ "$inbound_count" -eq 1 ] && [ "$outbound_count" -eq 2 ] && \
    grep -Eq '"tag"[[:space:]]*:[[:space:]]*"vless-reality-in"' "$XRAY_CONFIG" && \
    grep -Eq '"protocol"[[:space:]]*:[[:space:]]*"vless"' "$XRAY_CONFIG" && \
    grep -Eq '"tag"[[:space:]]*:[[:space:]]*"(direct|isp-socks5)"' "$XRAY_CONFIG"
}

is_nrb_systemd_service() {
  [ -f "$XRAY_SERVICE" ] || return 1
  grep -Fq "ExecStart=${XRAY_BIN} run -config ${XRAY_CONFIG}" "$XRAY_SERVICE"
}

is_nrb_supervisor_program() {
  [ -f "$SUPERVISOR_CONFIG" ] || return 1
  grep -Fq "[program:${SUPERVISOR_PROGRAM}]" "$SUPERVISOR_CONFIG" && \
    grep -Fq "command=${XRAY_BIN} run -config ${XRAY_CONFIG}" "$SUPERVISOR_CONFIG"
}

backend="$(detect_service_backend)"
runtime_managed="no"
if ! is_valid_managed_marker; then
  echo "No valid NAT Reality Bridge ownership marker was found: ${MANAGED_MARKER}" >&2
  echo "Uninstall aborted. Xray binary, config, and service definitions were preserved." >&2
  exit 1
fi
if [ "$backend" = "systemd" ] && is_nrb_systemd_service; then
  runtime_managed="yes"
elif [ "$backend" = "supervisor" ] && is_nrb_supervisor_program; then
  runtime_managed="yes"
fi
if [ -f "$XRAY_CONFIG" ] && ! is_supported_single_node_config; then
  echo "Detected existing advanced Xray configuration." >&2
  echo "Uninstall aborted to protect user-managed configuration." >&2
  exit 1
fi

cat <<EOF
NAT Reality Bridge ${NRB_VERSION} uninstall

Service backend: ${backend}
This will keep:
- ${BACKUP_ROOT}
- ${APP_DIR}
- SSH configuration and unrelated system services
EOF

if [ "$runtime_managed" = "yes" ]; then
  cat <<EOF
This will remove NAT Reality Bridge runtime files:
- ${XRAY_CONFIG}
- ${XRAY_BIN}
- ${STATE_DIR}
- managed ${backend} definition
EOF
else
  cat <<EOF
The Xray service definition is not recognized as NAT Reality Bridge managed.
This will remove only: ${STATE_FILE}
EOF
fi

printf "Continue uninstall? Type yes: " >&2
IFS= read -r answer
[ "$answer" = "yes" ] || { echo "Aborted."; exit 0; }

case "$backend" in
  systemd)
    if is_nrb_systemd_service; then
      systemctl stop xray 2>/dev/null || true
      systemctl disable xray 2>/dev/null || true
      rm -f "$XRAY_SERVICE"
      systemctl daemon-reload || true
    else
      echo "Preserved unrecognized systemd service definition: ${XRAY_SERVICE}"
    fi
    ;;
  supervisor)
    if is_nrb_supervisor_program; then
      supervisorctl stop "$SUPERVISOR_PROGRAM" 2>/dev/null || true
      rm -f "$SUPERVISOR_CONFIG"
      supervisorctl reread || true
      supervisorctl update || true
    else
      echo "No NAT Reality Bridge Supervisor program found."
    fi
    ;;
  *)
    echo "No recognized service backend. Xray runtime files will be preserved."
    ;;
esac

if [ "$runtime_managed" = "yes" ]; then
  rm -f "$XRAY_CONFIG"
  rmdir "$XRAY_CONFIG_DIR" 2>/dev/null || true
  rm -f "$XRAY_BIN"
  rm -f "$XRAY_SHARE_DIR/geoip.dat" "$XRAY_SHARE_DIR/geosite.dat"
  rmdir "$XRAY_SHARE_DIR" 2>/dev/null || true
  rm -f "$MANAGED_MARKER"
  rmdir "$MANAGED_DIR" 2>/dev/null || true
fi
rm -f "$STATE_FILE"
rmdir "$STATE_DIR" 2>/dev/null || true

echo "Uninstall completed. Backups were kept at: ${BACKUP_ROOT}"
echo "Client files were kept at: ${APP_DIR}"
