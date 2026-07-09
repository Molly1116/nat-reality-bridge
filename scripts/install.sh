#!/usr/bin/env bash
set -euo pipefail

# NAT Reality Bridge installer for a new Debian NAT VPS.
# Review before running. Sensitive values are collected interactively.

XRAY_VERSION="${XRAY_VERSION:-v26.3.27}"
XRAY_BIN="/usr/local/bin/xray"
XRAY_CONFIG_DIR="/etc/xray"
XRAY_CONFIG="/etc/xray/config.json"
XRAY_SHARE_DIR="/usr/local/share/xray"
XRAY_SERVICE="/etc/systemd/system/xray.service"
BACKUP_ROOT="/root/xray-config-backups"

PUBLIC_HOST=""
PUBLIC_PORT=""
INTERNAL_PORT="443"
LISTEN_ADDRESS=""
NODE_NAME="NAT-Reality-Bridge"
REALITY_SERVER_NAME="www.cloudflare.com"
REALITY_DEST="www.cloudflare.com:443"
REALITY_SPIDER_X="/"
ISP_SOCKS5_HOST=""
ISP_SOCKS5_PORT=""
ISP_SOCKS5_USER=""
ISP_SOCKS5_PASSWORD=""
LAST_BACKUP_DIR=""

need_root() {
  if [ "$(id -u)" != "0" ]; then
    echo "This installer must run as root." >&2
    exit 1
  fi
}

read_required() {
  local prompt="$1"
  local value=""
  while [ -z "$value" ]; do
    printf "%s: " "$prompt" >&2
    IFS= read -r value
  done
  printf "%s" "$value"
}

read_secret() {
  local prompt="$1"
  local value=""
  while [ -z "$value" ]; do
    printf "%s: " "$prompt" >&2
    stty -echo
    IFS= read -r value
    stty echo
    printf "\n" >&2
  done
  printf "%s" "$value"
}

collect_inputs() {
  echo "== interactive setup =="
  PUBLIC_HOST="$(read_required "Public host or domain")"
  PUBLIC_PORT="$(read_required "Public NAT port")"
  printf "Internal Xray port [443]: " >&2
  IFS= read -r maybe_port
  INTERNAL_PORT="${maybe_port:-443}"
  printf "Listen address [empty means Xray default/all interfaces]: " >&2
  IFS= read -r LISTEN_ADDRESS
  printf "Node name [NAT-Reality-Bridge]: " >&2
  IFS= read -r maybe_name
  NODE_NAME="${maybe_name:-NAT-Reality-Bridge}"
  ISP_SOCKS5_HOST="$(read_required "ISP SOCKS5 host")"
  ISP_SOCKS5_PORT="$(read_required "ISP SOCKS5 port")"
  ISP_SOCKS5_USER="$(read_required "ISP SOCKS5 username")"
  ISP_SOCKS5_PASSWORD="$(read_secret "ISP SOCKS5 password")"
}

preflight() {
  echo "== preflight =="
  command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }
  command -v unzip >/dev/null || { echo "unzip is required." >&2; exit 1; }
  command -v sha256sum >/dev/null || { echo "sha256sum is required." >&2; exit 1; }
  command -v systemctl >/dev/null || { echo "systemd is required." >&2; exit 1; }

  arch="$(uname -m)"
  if [ "$arch" != "x86_64" ]; then
    echo "Unsupported architecture: $arch. This template expects x86_64." >&2
    exit 1
  fi

  if [ -r /etc/os-release ]; then
    . /etc/os-release
    case "${ID:-}:${VERSION_ID:-}" in
      debian:12|debian:13) ;;
      *) echo "Warning: expected Debian 12/13, got ${PRETTY_NAME:-unknown}." >&2 ;;
    esac
  fi

  mem_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
  if [ "$mem_kb" -lt 100000 ]; then
    echo "Warning: memory is very low. Continue only if this is expected." >&2
  fi
}

show_plan() {
  cat <<EOF
== planned operations ==
- Download official Xray-core ${XRAY_VERSION}
- Verify release digest
- Back up existing Xray files under ${BACKUP_ROOT}
- Install ${XRAY_BIN}
- Write ${XRAY_CONFIG}
- Write ${XRAY_SERVICE}
- Run Xray config test
- Enable and restart xray.service

Public endpoint: ${PUBLIC_HOST}:${PUBLIC_PORT}
Internal port: ${INTERNAL_PORT}
Reality target: ${REALITY_SERVER_NAME} -> ${REALITY_DEST}
SOCKS5 host: ${ISP_SOCKS5_HOST}:${ISP_SOCKS5_PORT}
EOF
  printf "Continue? Type yes: " >&2
  IFS= read -r answer
  [ "$answer" = "yes" ] || { echo "Aborted."; exit 1; }
}

backup_existing() {
  mkdir -p "$BACKUP_ROOT"
  LAST_BACKUP_DIR="$BACKUP_ROOT/backup-$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "$LAST_BACKUP_DIR"
  for p in "$XRAY_CONFIG" "$XRAY_SERVICE" "$XRAY_BIN" "$XRAY_SHARE_DIR/geoip.dat" "$XRAY_SHARE_DIR/geosite.dat"; do
    if [ -e "$p" ]; then
      cp -a "$p" "$LAST_BACKUP_DIR/$(echo "$p" | sed 's#^/##; s#/#_#g')"
    fi
  done
  echo "backup_dir=$LAST_BACKUP_DIR"
}

rollback() {
  if [ -z "$LAST_BACKUP_DIR" ] || [ ! -d "$LAST_BACKUP_DIR" ]; then
    echo "No rollback backup available." >&2
    return 1
  fi
  echo "Rolling back from $LAST_BACKUP_DIR" >&2
  [ -f "$LAST_BACKUP_DIR/etc_xray_config.json" ] && cp -a "$LAST_BACKUP_DIR/etc_xray_config.json" "$XRAY_CONFIG"
  [ -f "$LAST_BACKUP_DIR/etc_systemd_system_xray.service" ] && cp -a "$LAST_BACKUP_DIR/etc_systemd_system_xray.service" "$XRAY_SERVICE"
  systemctl daemon-reload || true
}

install_xray() {
  workdir="/tmp/nat-reality-bridge-install-$$"
  asset="Xray-linux-64.zip"
  base_url="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}"
  mkdir -p "$workdir"
  trap 'rm -rf "$workdir"' EXIT
  cd "$workdir"
  curl -fL --connect-timeout 20 --retry 2 --retry-delay 2 -o "$asset" "$base_url/$asset"
  curl -fL --connect-timeout 20 --retry 2 --retry-delay 2 -o "$asset.dgst" "$base_url/$asset.dgst"
  calc="$(sha256sum "$asset" | awk '{print $1}')"
  grep -qi "$calc" "$asset.dgst" || { echo "SHA256 verification failed." >&2; exit 1; }
  unzip -q "$asset" -d unpack
  install -m 0755 unpack/xray "$XRAY_BIN"
  mkdir -p "$XRAY_SHARE_DIR" "$XRAY_CONFIG_DIR"
  install -m 0644 unpack/geoip.dat "$XRAY_SHARE_DIR/geoip.dat"
  install -m 0644 unpack/geosite.dat "$XRAY_SHARE_DIR/geosite.dat"
}

write_config() {
  uuid="$($XRAY_BIN uuid)"
  keys="$($XRAY_BIN x25519)"
  private_key="$(printf '%s\n' "$keys" | awk -F': ' '/^PrivateKey:/ {print $2}')"
  public_key="$(printf '%s\n' "$keys" | awk -F': ' '/^Password \(PublicKey\):/ {print $2}')"
  short_id="$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
  [ -n "$private_key" ] && [ -n "$public_key" ] && [ -n "$short_id" ] || { echo "Failed to generate Reality values." >&2; exit 1; }

  listen_line=""
  if [ -n "$LISTEN_ADDRESS" ]; then
    listen_line="\"listen\": \"${LISTEN_ADDRESS}\","
  fi

  cat > "$XRAY_CONFIG" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "tag": "vless-reality-in",
      ${listen_line}
      "port": ${INTERNAL_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "${uuid}", "flow": "xtls-rprx-vision" } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${REALITY_DEST}",
          "xver": 0,
          "serverNames": [ "${REALITY_SERVER_NAME}" ],
          "privateKey": "${private_key}",
          "shortIds": [ "${short_id}" ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "isp-socks5",
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "${ISP_SOCKS5_HOST}",
            "port": ${ISP_SOCKS5_PORT},
            "users": [ { "user": "${ISP_SOCKS5_USER}", "pass": "${ISP_SOCKS5_PASSWORD}" } ]
          }
        ]
      }
    },
    { "tag": "block", "protocol": "blackhole" }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [ { "type": "field", "network": "tcp,udp", "outboundTag": "isp-socks5" } ]
  }
}
EOF
  chmod 600 "$XRAY_CONFIG"

  cat > /root/nat-reality-bridge-node.txt <<EOF
PUBLIC_HOST=${PUBLIC_HOST}
PUBLIC_PORT=${PUBLIC_PORT}
UUID=${uuid}
PUBLIC_KEY=${public_key}
SHORT_ID=${short_id}
SERVER_NAME=${REALITY_SERVER_NAME}
SPIDER_X=${REALITY_SPIDER_X}
VLESS_URI=vless://${uuid}@${PUBLIC_HOST}:${PUBLIC_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SERVER_NAME}&fp=chrome&pbk=${public_key}&sid=${short_id}&type=tcp&headerType=none&spx=%2F#${NODE_NAME}
EOF
  chmod 600 /root/nat-reality-bridge-node.txt
}

write_service() {
  cat > "$XRAY_SERVICE" <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network-online.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=${XRAY_BIN} run -config ${XRAY_CONFIG}
Restart=on-failure
RestartSec=5s
LimitNOFILE=65535
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
  chmod 644 "$XRAY_SERVICE"
}

config_test() {
  "$XRAY_BIN" run -test -config "$XRAY_CONFIG"
}

start_service() {
  systemctl daemon-reload
  systemctl enable --now xray
  sleep 2
  systemctl --no-pager --full status xray | sed -n '1,45p'
}

main() {
  need_root
  collect_inputs
  preflight
  show_plan
  backup_existing
  install_xray
  write_config
  write_service
  if ! config_test; then
    rollback || true
    exit 1
  fi
  start_service
  echo "Node values saved to /root/nat-reality-bridge-node.txt"
}

main "$@"
