#!/usr/bin/env bash
set -euo pipefail

NRB_VERSION="v1.5.1"
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
  awk -F= -v key="$key" '$1 == key {sub($1 "=", ""); print; exit}' "$NODE_FILE"
}

read_secret() {
  local prompt="$1"
  printf '%s: ' "$prompt" >&2
  stty -echo
  IFS= read -r value
  stty echo
  printf '\n' >&2
  printf '%s' "$value"
}

echo "NAT Reality Bridge Outbound Test"
echo "Version: ${NRB_VERSION}"
echo

MODE="${MODE:-$(read_node_value MODE)}"
MODE="${MODE:-basic}"

if ! command -v curl >/dev/null 2>&1; then
  echo "Direct SOCKS5: NOT TESTED (curl is required)"
  echo "Through Xray: NOT TESTED"
  exit 0
fi

case "$MODE" in
  isp)
    SOCKS5_HOST="${SOCKS5_HOST:-$(read_node_value SOCKS5_HOST)}"
    SOCKS5_PORT="${SOCKS5_PORT:-$(read_node_value SOCKS5_PORT)}"
    if [ -z "$SOCKS5_HOST" ] || [ -z "$SOCKS5_PORT" ]; then
      echo "Direct SOCKS5: NOT TESTED (missing host or port)"
      echo "Through Xray: NOT TESTED"
      exit 0
    fi
    if [ -z "$SOCKS5_USER" ]; then
      printf 'SOCKS5 Username: ' >&2
      IFS= read -r SOCKS5_USER
    fi
    if [ -z "$SOCKS5_PASSWORD" ]; then
      SOCKS5_PASSWORD="$(read_secret 'SOCKS5 Password')"
    fi
    if exit_ip="$(curl --socks5-hostname "${SOCKS5_USER}:${SOCKS5_PASSWORD}@${SOCKS5_HOST}:${SOCKS5_PORT}" -fsS --max-time 20 https://api.ipify.org 2>/dev/null)"; then
      echo "Direct SOCKS5: PASS"
      echo "SOCKS5 outbound reachable"
      echo "Exit IP: ${exit_ip}"
    else
      echo "Direct SOCKS5: FAIL"
      echo "SOCKS5 outbound unreachable or authentication failed"
    fi
    ;;
  basic)
    echo "Direct SOCKS5: NOT APPLICABLE (Basic Mode uses the VPS native exit)"
    ;;
  *)
    echo "Direct SOCKS5: NOT TESTED (unknown mode: ${MODE})"
    ;;
esac

echo "Through Xray: NOT TESTED"
echo "Note: direct SOCKS5 reachability does not verify a Reality handshake or client node availability."
