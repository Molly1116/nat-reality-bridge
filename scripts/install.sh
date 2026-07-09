#!/usr/bin/env bash
set -euo pipefail

# NAT Reality Bridge v1.1.0 installer.
# Review before running. Sensitive values are collected interactively.

XRAY_VERSION="${XRAY_VERSION:-v26.3.27}"
XRAY_BIN="/usr/local/bin/xray"
XRAY_CONFIG_DIR="/etc/xray"
XRAY_CONFIG="/etc/xray/config.json"
XRAY_CONFIG_TMP="/etc/xray/config.json.tmp"
XRAY_SHARE_DIR="/usr/local/share/xray"
XRAY_SERVICE="/etc/systemd/system/xray.service"
BACKUP_ROOT="/root/xray-backups"
NODE_OUTPUT="/root/nat-reality-bridge-node.txt"

PUBLIC_HOST=""
PUBLIC_PORT=""
INTERNAL_PORT="443"
LISTEN_ADDRESS=""
NODE_NAME="NAT-Reality-Bridge"
DEPLOY_MODE=""
REALITY_SERVER_NAME="www.cloudflare.com"
REALITY_DEST="www.cloudflare.com:443"
REALITY_SPIDER_X="/"
FLOW="xtls-rprx-vision"
ISP_SOCKS5_HOST=""
ISP_SOCKS5_PORT=""
ISP_SOCKS5_USER=""
ISP_SOCKS5_PASSWORD=""
UUID_VALUE=""
REALITY_PRIVATE_KEY=""
REALITY_PUBLIC_KEY=""
REALITY_SHORT_ID=""
LAST_BACKUP_DIR=""

banner() {
  cat <<'EOF'
================================
 NAT Reality Bridge Installer
================================
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

need_root() {
  [ "$(id -u)" = "0" ] || die "This installer must run as root."
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

preflight() {
  echo
  echo "== preflight checks =="
  command -v curl >/dev/null || die "curl is required."
  command -v unzip >/dev/null || die "unzip is required."
  command -v sha256sum >/dev/null || die "sha256sum is required."
  command -v systemctl >/dev/null || die "systemd is required."
  command -v ss >/dev/null || echo "Warning: ss is not available; listen checks may be limited." >&2

  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) echo "Architecture: $arch" ;;
    *) die "Unsupported architecture: $arch. This installer targets x86_64/amd64." ;;
  esac

  if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "OS: ${PRETTY_NAME:-unknown}"
    if [ "${ID:-}" != "debian" ]; then
      die "Unsupported OS: ${PRETTY_NAME:-unknown}. Debian 12/13 is expected."
    fi
    case "${VERSION_ID:-}" in
      12|13) ;;
      *) echo "Warning: Debian 12/13 is recommended; detected VERSION_ID=${VERSION_ID:-unknown}." >&2 ;;
    esac
  else
    die "/etc/os-release is missing."
  fi

  mem_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
  disk_kb="$(df -Pk /usr/local 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)"
  echo "Memory: $((mem_kb / 1024)) MB"
  echo "Free disk under /usr/local: $((disk_kb / 1024)) MB"
  [ "$mem_kb" -ge 90000 ] || echo "Warning: memory is below 90 MB; Xray may still run, but margin is small." >&2
  [ "$disk_kb" -ge 51200 ] || die "At least 50 MB free disk under /usr/local is required."
}

choose_mode() {
  cat <<'EOF'

Please choose deployment mode:

[1] Basic Mode
    Use VPS native exit.
    - Simplest setup
    - No extra proxy required
    - Automatically generates a Reality node
    Note: exit IP quality depends on the VPS itself.

[2] ISP Residential Exit Mode
    Use SOCKS5 ISP/Residential exit.
    - Separate entry and exit
    - Improve egress IP quality
    - Replace exit independently
EOF

  while :; do
    mode="$(read_required "Select 1 or 2")"
    case "$mode" in
      1) DEPLOY_MODE="basic"; break ;;
      2) DEPLOY_MODE="isp"; break ;;
      *) echo "Please enter 1 or 2." >&2 ;;
    esac
  done
}

collect_common_inputs() {
  echo
  echo "== node parameters =="
  PUBLIC_HOST="$(read_required "Public host or domain")"
  PUBLIC_PORT="$(read_required "Public NAT port")"
  printf "Internal Xray port [443]: " >&2
  IFS= read -r maybe_port
  INTERNAL_PORT="${maybe_port:-443}"
  printf "Listen address [empty means all interfaces]: " >&2
  IFS= read -r LISTEN_ADDRESS
  printf "Node name [NAT-Reality-Bridge]: " >&2
  IFS= read -r maybe_name
  NODE_NAME="${maybe_name:-NAT-Reality-Bridge}"
}

collect_isp_inputs() {
  if [ "$DEPLOY_MODE" != "isp" ]; then
    return
  fi
  echo
  echo "== SOCKS5 ISP/Residential exit =="
  ISP_SOCKS5_HOST="$(read_required "SOCKS5 Host")"
  ISP_SOCKS5_PORT="$(read_required "SOCKS5 Port")"
  ISP_SOCKS5_USER="$(read_required "Username")"
  ISP_SOCKS5_PASSWORD="$(read_secret "Password")"
}

show_plan() {
  echo
  cat <<EOF
== planned operations ==
- Download official Xray-core ${XRAY_VERSION}
- Verify release digest
- Back up existing files under ${BACKUP_ROOT}
- Generate UUID, Reality keypair, and shortId
- Write temporary config: ${XRAY_CONFIG_TMP}
- Run Xray config test before replacing active config
- Replace active config only after test passes
- Write systemd service: ${XRAY_SERVICE}
- Restart xray.service
- Generate VLESS URI without printing Reality privateKey

Mode: ${DEPLOY_MODE}
Public endpoint: ${PUBLIC_HOST}:${PUBLIC_PORT}
Internal port: ${INTERNAL_PORT}
Reality target: ${REALITY_SERVER_NAME} -> ${REALITY_DEST}
EOF
  if [ "$DEPLOY_MODE" = "isp" ]; then
    echo "SOCKS5 exit: ${ISP_SOCKS5_HOST}:${ISP_SOCKS5_PORT}"
  else
    echo "Exit: VPS Native Exit"
  fi
  printf "Continue? Type yes: " >&2
  IFS= read -r answer
  [ "$answer" = "yes" ] || die "Aborted."
}

backup_existing() {
  mkdir -p "$BACKUP_ROOT"
  LAST_BACKUP_DIR="$BACKUP_ROOT/backup-$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "$LAST_BACKUP_DIR"
  for p in "$XRAY_CONFIG" "$XRAY_SERVICE" "$XRAY_BIN" "$XRAY_SHARE_DIR/geoip.dat" "$XRAY_SHARE_DIR/geosite.dat" "$NODE_OUTPUT"; do
    if [ -e "$p" ]; then
      cp -a "$p" "$LAST_BACKUP_DIR/$(echo "$p" | sed 's#^/##; s#/#_#g')"
    fi
  done
  echo "Backup directory: $LAST_BACKUP_DIR"
}

rollback() {
  if [ -z "$LAST_BACKUP_DIR" ] || [ ! -d "$LAST_BACKUP_DIR" ]; then
    echo "No rollback backup is available." >&2
    return 1
  fi
  echo "Rolling back from $LAST_BACKUP_DIR" >&2
  [ -f "$LAST_BACKUP_DIR/etc_xray_config.json" ] && cp -a "$LAST_BACKUP_DIR/etc_xray_config.json" "$XRAY_CONFIG"
  [ -f "$LAST_BACKUP_DIR/etc_systemd_system_xray.service" ] && cp -a "$LAST_BACKUP_DIR/etc_systemd_system_xray.service" "$XRAY_SERVICE"
  [ -f "$LAST_BACKUP_DIR/root_nat-reality-bridge-node.txt" ] && cp -a "$LAST_BACKUP_DIR/root_nat-reality-bridge-node.txt" "$NODE_OUTPUT"
  systemctl daemon-reload || true
  systemctl restart xray || true
}

on_error() {
  echo "Installation failed. Attempting rollback." >&2
  rollback || true
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
  grep -qi "$calc" "$asset.dgst" || die "SHA256 verification failed."
  unzip -q "$asset" -d unpack
  install -m 0755 unpack/xray "$XRAY_BIN"
  mkdir -p "$XRAY_SHARE_DIR" "$XRAY_CONFIG_DIR"
  install -m 0644 unpack/geoip.dat "$XRAY_SHARE_DIR/geoip.dat"
  install -m 0644 unpack/geosite.dat "$XRAY_SHARE_DIR/geosite.dat"
}

generate_reality_values() {
  UUID_VALUE="$($XRAY_BIN uuid)"
  keys="$($XRAY_BIN x25519)"
  REALITY_PRIVATE_KEY="$(printf '%s\n' "$keys" | awk -F': *' 'tolower($1) ~ /^private ?key$/ {print $2; exit}')"
  REALITY_PUBLIC_KEY="$(printf '%s\n' "$keys" | awk -F': *' 'tolower($1) ~ /^(public ?key|password \(publickey\))$/ {print $2; exit}')"
  REALITY_SHORT_ID="$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
  [ -n "$UUID_VALUE" ] && [ -n "$REALITY_PRIVATE_KEY" ] && [ -n "$REALITY_PUBLIC_KEY" ] && [ -n "$REALITY_SHORT_ID" ] || die "Failed to generate Reality values."
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_temp_config() {
  listen_line=""
  if [ -n "$LISTEN_ADDRESS" ]; then
    listen_line="\"listen\": \"$(json_escape "$LISTEN_ADDRESS")\","
  fi

  if [ "$DEPLOY_MODE" = "isp" ]; then
    outbound_block="{
      \"tag\": \"isp-socks5\",
      \"protocol\": \"socks\",
      \"settings\": {
        \"servers\": [
          {
            \"address\": \"$(json_escape "$ISP_SOCKS5_HOST")\",
            \"port\": ${ISP_SOCKS5_PORT},
            \"users\": [ { \"user\": \"$(json_escape "$ISP_SOCKS5_USER")\", \"pass\": \"$(json_escape "$ISP_SOCKS5_PASSWORD")\" } ]
          }
        ]
      }
    }"
    routing_block="\"routing\": {
    \"domainStrategy\": \"AsIs\",
    \"rules\": [ { \"type\": \"field\", \"network\": \"tcp,udp\", \"outboundTag\": \"isp-socks5\" } ]
  },"
  else
    outbound_block="{ \"tag\": \"direct\", \"protocol\": \"freedom\" }"
    routing_block=""
  fi

  cat > "$XRAY_CONFIG_TMP" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "tag": "vless-reality-in",
      ${listen_line}
      "port": ${INTERNAL_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "${UUID_VALUE}", "flow": "${FLOW}" } ],
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
          "privateKey": "${REALITY_PRIVATE_KEY}",
          "shortIds": [ "${REALITY_SHORT_ID}" ]
        }
      }
    }
  ],
  ${routing_block}
  "outbounds": [
    ${outbound_block},
    { "tag": "block", "protocol": "blackhole" }
  ]
}
EOF
  chmod 600 "$XRAY_CONFIG_TMP"
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
  "$XRAY_BIN" run -test -config "$XRAY_CONFIG_TMP"
}

activate_config() {
  install -m 0600 "$XRAY_CONFIG_TMP" "$XRAY_CONFIG"
  rm -f "$XRAY_CONFIG_TMP"
}

restart_service() {
  systemctl daemon-reload
  systemctl enable xray >/dev/null
  systemctl restart xray
  sleep 2
  systemctl --no-pager --full status xray | sed -n '1,45p'
}

generate_uri() {
  spx_encoded="%2F"
  vless_uri="vless://${UUID_VALUE}@${PUBLIC_HOST}:${PUBLIC_PORT}?encryption=none&flow=${FLOW}&security=reality&sni=${REALITY_SERVER_NAME}&fp=chrome&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}&type=tcp&headerType=none&spx=${spx_encoded}#${NODE_NAME}"
  cat > "$NODE_OUTPUT" <<EOF
MODE=${DEPLOY_MODE}
PUBLIC_HOST=${PUBLIC_HOST}
PUBLIC_PORT=${PUBLIC_PORT}
UUID=${UUID_VALUE}
PUBLIC_KEY=${REALITY_PUBLIC_KEY}
SHORT_ID=${REALITY_SHORT_ID}
SERVER_NAME=${REALITY_SERVER_NAME}
DEST=${REALITY_DEST}
SPIDER_X=${REALITY_SPIDER_X}
FLOW=${FLOW}
VLESS_URI=${vless_uri}
EOF
  chmod 600 "$NODE_OUTPUT"

  echo
  echo "Deployment complete"
  if [ "$DEPLOY_MODE" = "isp" ]; then
    echo "Current mode: ISP Residential Exit Mode"
    echo "Exit: SOCKS5 ISP/Residential Exit"
  else
    echo "Current mode: Basic Mode"
    echo "Exit: VPS Native Exit"
  fi
  echo
  echo "VLESS URI:"
  echo "$vless_uri"
}

test_isp_exit() {
  if [ "$DEPLOY_MODE" != "isp" ]; then
    return
  fi
  echo
  echo "== ISP exit test =="
  if curl --socks5-hostname "${ISP_SOCKS5_USER}:${ISP_SOCKS5_PASSWORD}@${ISP_SOCKS5_HOST}:${ISP_SOCKS5_PORT}" -fsS --max-time 20 https://api.ipify.org; then
    echo
    echo "ISP exit test successful"
  else
    echo
    echo "Warning: ISP exit test failed. Check SOCKS5 credentials and provider reachability." >&2
  fi
}

main() {
  banner
  need_root
  preflight
  choose_mode
  collect_common_inputs
  collect_isp_inputs
  show_plan
  trap on_error ERR
  backup_existing
  install_xray
  generate_reality_values
  write_temp_config
  config_test
  activate_config
  write_service
  restart_service
  test_isp_exit
  generate_uri
  trap - ERR
}

main "$@"
