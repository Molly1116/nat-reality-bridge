#!/usr/bin/env bash
set -euo pipefail

XRAY_BIN="${XRAY_BIN:-/usr/local/bin/xray}"
XRAY_CONFIG="${XRAY_CONFIG:-/etc/xray/config.json}"
SERVICE_NAME="${SERVICE_NAME:-xray}"

echo "== NAT Reality Bridge health check =="

echo
echo "Service:"
if command -v systemctl >/dev/null; then
  systemctl is-active "$SERVICE_NAME" || true
  systemctl --no-pager --full status "$SERVICE_NAME" | sed -n '1,25p' || true
else
  echo "systemctl is not available"
fi

echo
echo "Xray version:"
if [ -x "$XRAY_BIN" ]; then
  "$XRAY_BIN" version | sed -n '1,3p'
else
  echo "$XRAY_BIN not found"
fi

echo
echo "Config test:"
if [ -x "$XRAY_BIN" ] && [ -f "$XRAY_CONFIG" ]; then
  "$XRAY_BIN" run -test -config "$XRAY_CONFIG" || true
else
  echo "Config or xray binary not found"
fi

echo
echo "Listening ports:"
if command -v ss >/dev/null; then
  ss -tnlp | grep -E 'xray|:443|:8443|:24443' || true
else
  echo "ss is not available"
fi

echo
echo "Memory usage:"
if command -v ps >/dev/null; then
  ps -o pid,rss,comm -C xray || true
else
  echo "ps is not available"
fi

echo
echo "Current exit IP:"
if command -v curl >/dev/null; then
  curl -fsS --max-time 10 https://api.ipify.org || true
  echo
else
  echo "curl is not available"
fi
