#!/usr/bin/env bash
set -euo pipefail

XRAY_CONFIG="${XRAY_CONFIG:-/etc/xray/config.json}"
BACKUP_ROOT="${BACKUP_ROOT:-/root/xray-backups}"

if [ "$(id -u)" != "0" ]; then
  echo "This backup script must run as root." >&2
  exit 1
fi

if [ ! -f "$XRAY_CONFIG" ]; then
  echo "Config not found: $XRAY_CONFIG" >&2
  exit 1
fi

mkdir -p "$BACKUP_ROOT"
backup_file="$BACKUP_ROOT/config-$(date -u +%Y%m%dT%H%M%SZ).json"
install -m 0600 "$XRAY_CONFIG" "$backup_file"

echo "Backup created: $backup_file"
