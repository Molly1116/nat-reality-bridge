#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/root/nat-reality-bridge}"
NODE_FILE="${NODE_FILE:-${APP_DIR}/node.txt}"

MODE="${MODE:-}"
SOCKS5_HOST="${SOCKS5_HOST:-}"
SOCKS5_PORT="${SOCKS5_PORT:-}"
SOCKS5_USER="${SOCKS5_USER:-}"
SOCKS5_PASSWORD="${SOCKS5_PASSWORD:-}"

read_node_value() {
  local key="$1"
  [ -f "$NODE_FILE" ] || return 0
  awk -F= -v k="$key" '$1 == k {sub($1"=",""); print; exit}' "$NODE_FILE"
}

detect_mode() {
  if [ -z "$MODE" ]; then
    MODE="$(read_node_value MODE)"
  fi
  [ -n "$MODE" ] || MODE="basic"
}

fetch_ip_meta() {
  local ip="$1"
  country="$(curl -fsS --max-time 8 "https://ipapi.co/${ip}/country_name/" 2>/dev/null || true)"
  asn="$(curl -fsS --max-time 8 "https://ipapi.co/${ip}/asn/" 2>/dev/null || true)"
  echo "Exit IP: $ip"
  [ -n "$country" ] && echo "Country: $country" || echo "Country: unavailable"
  [ -n "$asn" ] && echo "ASN: $asn" || echo "ASN: unavailable"
}

test_basic() {
  echo "Mode: Basic Mode"
  if ip="$(curl -fsS --max-time 20 https://api.ipify.org 2>/dev/null)"; then
    echo "Native exit: ok"
    fetch_ip_meta "$ip"
  else
    echo "Native exit: failed"
    echo "Reason: cannot reach public IP test endpoint from this VPS."
    exit 1
  fi
}

test_isp() {
  echo "Mode: ISP Residential Exit Mode"
  if [ -z "$SOCKS5_HOST" ]; then
    SOCKS5_HOST="$(read_node_value SOCKS5_HOST)"
  fi
  if [ -z "$SOCKS5_PORT" ]; then
    SOCKS5_PORT="$(read_node_value SOCKS5_PORT)"
  fi
  if [ -z "$SOCKS5_USER" ]; then
    printf "SOCKS5 Username: " >&2
    IFS= read -r SOCKS5_USER
  fi
  if [ -z "$SOCKS5_PASSWORD" ]; then
    printf "SOCKS5 Password: " >&2
    stty -echo
    IFS= read -r SOCKS5_PASSWORD
    stty echo
    printf "\n" >&2
  fi
  if [ -z "$SOCKS5_HOST" ] || [ -z "$SOCKS5_PORT" ]; then
    echo "SOCKS5 connection: failed"
    echo "Reason: missing SOCKS5 host or port. Set SOCKS5_HOST and SOCKS5_PORT, or run after installation."
    exit 1
  fi
  proxy="${SOCKS5_HOST}:${SOCKS5_PORT}"
  if ip="$(curl --socks5-hostname "${SOCKS5_USER}:${SOCKS5_PASSWORD}@${proxy}" -fsS --max-time 20 https://api.ipify.org 2>/dev/null)"; then
    echo "SOCKS5 connection: ok"
    fetch_ip_meta "$ip"
  else
    echo "SOCKS5 connection: failed"
    echo "Reason: authentication failed, provider is unreachable, or the test endpoint timed out."
    exit 1
  fi
}

command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }

detect_mode
case "$MODE" in
  isp) test_isp ;;
  basic) test_basic ;;
  *)
    echo "Unknown mode: $MODE"
    echo "Use MODE=basic or MODE=isp."
    exit 1
    ;;
esac
