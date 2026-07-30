#!/usr/bin/env bash
set -euo pipefail

NRB_VERSION="v1.5.0"
XRAY_BIN="${XRAY_BIN:-/usr/local/bin/xray}"
XRAY_CONFIG="${XRAY_CONFIG:-/etc/xray/config.json}"
XRAY_SERVICE="${XRAY_SERVICE:-/etc/systemd/system/xray.service}"
SUPERVISOR_PROGRAM="${SUPERVISOR_PROGRAM:-nat-reality-bridge-xray}"
SUPERVISOR_CONFIG="${SUPERVISOR_CONFIG:-/etc/supervisor/conf.d/${SUPERVISOR_PROGRAM}.conf}"
STATE_FILE="${STATE_FILE:-/var/lib/nat-reality-bridge/install-state}"
BACKUP_ROOT="${BACKUP_ROOT:-/root/xray-backups}"
MANAGED_MARKER="${MANAGED_MARKER:-/etc/nat-reality-bridge/managed.marker}"

[ "$(id -u)" = "0" ] || { echo "This update helper must run as root." >&2; exit 1; }

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

state_value() {
  local key="$1"
  [ -f "$STATE_FILE" ] || return 0
  awk -F= -v key="$key" '$1 == key {sub($1 "=", ""); print; exit}' "$STATE_FILE"
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

backup_item() {
  local source="$1"
  local target_name="$2"
  [ -e "$source" ] || return 0
  install -m 0600 "$source" "$backup_dir/$target_name"
}

echo "NAT Reality Bridge update helper ${NRB_VERSION}"
backend="$(detect_service_backend)"
echo "Service backend: ${backend}"
echo "Install state: $(state_value status || echo not_found) ($(state_value stage || echo unknown))"

if ! is_valid_managed_marker; then
  echo "No valid NAT Reality Bridge ownership marker was found." >&2
  echo "Update aborted; existing Xray configuration will not be treated as tool-managed." >&2
  exit 1
fi

[ -f "$XRAY_CONFIG" ] || { echo "Config not found: $XRAY_CONFIG" >&2; exit 1; }
if ! is_supported_single_node_config; then
  echo "Detected existing advanced Xray configuration." >&2
  echo "Update aborted to avoid overwrite." >&2
  exit 1
fi

backup_dir="$BACKUP_ROOT/pre-update-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$backup_dir"
chmod 700 "$backup_dir"
backup_item "$XRAY_CONFIG" "config.json"
backup_item "$XRAY_BIN" "xray"
backup_item "$STATE_FILE" "install-state"
backup_item "$MANAGED_MARKER" "managed.marker"
[ "$backend" = "systemd" ] && backup_item "$XRAY_SERVICE" "xray.service"
[ "$backend" = "supervisor" ] && backup_item "$SUPERVISOR_CONFIG" "${SUPERVISOR_PROGRAM}.conf"
echo "Backup created: $backup_dir"

if [ -x "$XRAY_BIN" ]; then
  echo "Current Xray version: $($XRAY_BIN version | sed -n '1p')"
  "$XRAY_BIN" run -test -config "$XRAY_CONFIG"
  echo "Verification: PASS"
else
  echo "Xray binary not found: $XRAY_BIN" >&2
  exit 1
fi

echo "Update: NOT APPLIED"
echo "Automatic Xray-core replacement is intentionally disabled. No production binary or configuration was changed."
