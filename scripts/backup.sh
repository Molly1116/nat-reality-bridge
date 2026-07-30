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

[ "$(id -u)" = "0" ] || { echo "This backup script must run as root." >&2; exit 1; }

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

backup_item() {
  local source="$1"
  local target_name="$2"
  [ -e "$source" ] || return 0
  install -m 0600 "$source" "$backup_dir/$target_name"
}

backup_dir="$BACKUP_ROOT/maintenance-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$backup_dir"
chmod 700 "$backup_dir"

backend="$(detect_service_backend)"
backup_item "$XRAY_CONFIG" "config.json"
backup_item "$XRAY_BIN" "xray"
backup_item "$STATE_FILE" "install-state"
backup_item "$MANAGED_MARKER" "managed.marker"

case "$backend" in
  systemd)
    backup_item "$XRAY_SERVICE" "xray.service"
    ;;
  supervisor)
    backup_item "$SUPERVISOR_CONFIG" "${SUPERVISOR_PROGRAM}.conf"
    ;;
  *)
    backup_item "$XRAY_SERVICE" "xray.service"
    backup_item "$SUPERVISOR_CONFIG" "${SUPERVISOR_PROGRAM}.conf"
    ;;
esac

echo "NAT Reality Bridge ${NRB_VERSION} backup created."
if is_valid_managed_marker; then
  echo "Ownership: MANAGED"
else
  echo "Ownership: UNMANAGED (backup is non-destructive; no configuration was changed)"
fi
echo "Service backend: ${backend}"
echo "Backup directory: ${backup_dir}"
