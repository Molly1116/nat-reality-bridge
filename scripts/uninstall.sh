#!/usr/bin/env bash
set -euo pipefail

XRAY_BIN="${XRAY_BIN:-/usr/local/bin/xray}"
XRAY_CONFIG_DIR="${XRAY_CONFIG_DIR:-/etc/xray}"
XRAY_SHARE_DIR="${XRAY_SHARE_DIR:-/usr/local/share/xray}"
XRAY_SERVICE="${XRAY_SERVICE:-/etc/systemd/system/xray.service}"
APP_DIR="${APP_DIR:-/root/nat-reality-bridge}"
BACKUP_ROOT="${BACKUP_ROOT:-/root/xray-backups}"

if [ "$(id -u)" != "0" ]; then
  echo "This uninstall script must run as root." >&2
  exit 1
fi

cat <<EOF
NAT Reality Bridge uninstall

This will remove:
- xray systemd service
- ${XRAY_CONFIG_DIR}
- ${XRAY_BIN}
- ${XRAY_SHARE_DIR}/geoip.dat
- ${XRAY_SHARE_DIR}/geosite.dat

This will keep by default:
- ${BACKUP_ROOT}
- ${APP_DIR}

SSH configuration and other system services will not be touched.
EOF

printf "Continue uninstall? Type yes: " >&2
IFS= read -r answer
[ "$answer" = "yes" ] || { echo "Aborted."; exit 0; }

if command -v systemctl >/dev/null; then
  systemctl stop xray 2>/dev/null || true
  systemctl disable xray 2>/dev/null || true
fi

rm -f "$XRAY_SERVICE"
rm -f "$XRAY_BIN"
rm -f "$XRAY_SHARE_DIR/geoip.dat" "$XRAY_SHARE_DIR/geosite.dat"
rm -rf "$XRAY_CONFIG_DIR"

if command -v systemctl >/dev/null; then
  systemctl daemon-reload || true
fi

echo "Uninstall completed. Backups were kept at: ${BACKUP_ROOT}"
echo "Client files were kept at: ${APP_DIR}"
