#!/usr/bin/env bash
set -euo pipefail

NRB_VERSION="v1.5.1"
XRAY_BIN="${XRAY_BIN:-/usr/local/bin/xray}"
XRAY_CONFIG="${XRAY_CONFIG:-/etc/xray/config.json}"
STATE_FILE="${STATE_FILE:-/var/lib/nat-reality-bridge/install-state}"
SUPERVISOR_PROGRAM="${SUPERVISOR_PROGRAM:-nat-reality-bridge-xray}"
MANAGED_MARKER="${MANAGED_MARKER:-/etc/nat-reality-bridge/managed.marker}"

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

detect_service_backend() {
  local pid1
  pid1="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')"
  if [ "$pid1" = "systemd" ] && command -v systemctl >/dev/null 2>&1; then
    if systemctl show --property=Version --value >/dev/null 2>&1 && \
       systemctl list-units --type=service --no-legend --no-pager >/dev/null 2>&1; then
      printf '%s\n' "systemd"
      return
    fi
  fi
  if command -v supervisorctl >/dev/null 2>&1 && supervisorctl status >/dev/null 2>&1; then
    printf '%s\n' "supervisor"
    return
  fi
  printf '%s\n' "unknown"
}

state_value() {
  local key="$1"
  [ -f "$STATE_FILE" ] || return 0
  awk -F= -v key="$key" '$1 == key {sub($1 "=", ""); print; exit}' "$STATE_FILE"
}

configured_ports() {
  [ -f "$XRAY_CONFIG" ] || return 0
  awk '
    /"inbounds"/ { inside=1; next }
    inside && /"outbounds"/ { exit }
    inside && /"port"[[:space:]]*:/ {
      value=$0
      sub(/.*"port"[[:space:]]*:[[:space:]]*/, "", value)
      sub(/[^0-9].*/, "", value)
      if (value != "") print value
    }
  ' "$XRAY_CONFIG" | sort -u
}

service_status() {
  local backend="$1"
  case "$backend" in
    systemd)
      systemctl is-active --quiet xray && printf '%s\n' "RUNNING" || printf '%s\n' "NOT RUNNING"
      ;;
    supervisor)
      if supervisorctl status "$SUPERVISOR_PROGRAM" 2>/dev/null | grep -q RUNNING; then
        printf '%s\n' "RUNNING"
      else
        printf '%s\n' "NOT RUNNING"
      fi
      ;;
    *)
      if pgrep -x xray >/dev/null 2>&1; then
        printf '%s\n' "RUNNING (process only)"
      else
        printf '%s\n' "UNKNOWN"
      fi
      ;;
  esac
}

echo "NAT Reality Bridge Health Check"
echo
echo "Version: ${NRB_VERSION}"

backend="$(detect_service_backend)"
echo "Service Backend: ${backend}"
if is_valid_managed_marker; then
  echo "Ownership: MANAGED"
else
  echo "Ownership: UNMANAGED (no valid NAT Reality Bridge marker)"
fi
echo "Xray: $(service_status "$backend")"

if [ -x "$XRAY_BIN" ]; then
  echo "Xray Binary: PRESENT"
  echo "Xray Version: $($XRAY_BIN version 2>/dev/null | sed -n '1p' || echo unavailable)"
else
  echo "Xray Binary: MISSING"
fi

if [ -f "$XRAY_CONFIG" ]; then
  echo "Config: PRESENT"
  if [ -x "$XRAY_BIN" ] && "$XRAY_BIN" run -test -config "$XRAY_CONFIG" >/dev/null 2>&1; then
    echo "Config Syntax: VALID"
  else
    echo "Config Syntax: INVALID OR NOT TESTED"
  fi
else
  echo "Config: MISSING"
fi

ports="$(configured_ports || true)"
if [ -z "$ports" ]; then
  echo "Inbound: NOT DETECTED"
elif ! command -v ss >/dev/null 2>&1; then
  echo "Inbound: NOT TESTED (ss is unavailable)"
else
  listening="yes"
  while IFS= read -r port; do
    if ! ss -tnlp | grep -Eq ":${port}[[:space:]]"; then
      listening="no"
      break
    fi
  done <<< "$ports"
  [ "$listening" = "yes" ] && echo "Inbound: LISTENING (${ports//$'\n'/, })" || echo "Inbound: NOT LISTENING (${ports//$'\n'/, })"
fi

if [ -f "$XRAY_CONFIG" ] && grep -Eq '"tag"[[:space:]]*:[[:space:]]*"isp-socks5"' "$XRAY_CONFIG"; then
  echo "ISP SOCKS5: NOT TESTED (run scripts/test-outbound.sh for direct credential verification)"
  echo "Reality End-to-End: NOT TESTED (direct SOCKS5 reachability is not a Reality node test)"
else
  echo "ISP SOCKS5: NOT APPLICABLE"
  echo "Reality End-to-End: NOT TESTED"
fi

if [ -f "$STATE_FILE" ]; then
  echo "Install State: $(state_value status || echo unknown) ($(state_value stage || echo unknown))"
else
  echo "Install State: NOT FOUND"
fi
