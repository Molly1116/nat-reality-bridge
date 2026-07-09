#!/usr/bin/env bash
set -euo pipefail

NRB_VERSION="v1.2.0"
XRAY_BIN="${XRAY_BIN:-/usr/local/bin/xray}"
XRAY_CONFIG="${XRAY_CONFIG:-/etc/xray/config.json}"
BACKUP_ROOT="${BACKUP_ROOT:-/root/xray-backups}"

if [ "$(id -u)" != "0" ]; then
  echo "This update helper must run as root." >&2
  exit 1
fi

echo "NAT Reality Bridge update helper ${NRB_VERSION}"
echo
echo "This helper does not replace Xray-core automatically."
echo "Automatic binary replacement is intentionally disabled to avoid compatibility surprises."
echo

if [ -x "$XRAY_BIN" ]; then
  echo "Current Xray version:"
  "$XRAY_BIN" version | sed -n '1,3p'
else
  echo "Xray binary not found at: $XRAY_BIN"
fi

if [ -f "$XRAY_CONFIG" ]; then
  mkdir -p "$BACKUP_ROOT"
  backup_file="$BACKUP_ROOT/pre-update-config-$(date -u +%Y%m%dT%H%M%SZ).json"
  install -m 0600 "$XRAY_CONFIG" "$backup_file"
  echo "Config backup created: $backup_file"

  if [ -x "$XRAY_BIN" ]; then
    echo "Config test:"
    "$XRAY_BIN" run -test -config "$XRAY_CONFIG"
  fi
else
  echo "Config not found: $XRAY_CONFIG"
fi

cat <<'EOF'

Next steps:
- Review Xray-core release notes before upgrading.
- Back up /etc/xray/config.json before any manual binary replacement.
- Keep SOCKS5 credentials and Reality privateKey out of public repositories.
- Re-run scripts/health-check.sh after any manual update.
EOF
