#!/usr/bin/env bash
set -euo pipefail

# NAT Reality Bridge v1.5.1 installer.
# Review before running. Sensitive values are collected interactively.

NRB_VERSION="v1.5.1"
XRAY_VERSION="${XRAY_VERSION:-v26.3.27}"
XRAY_BIN="${XRAY_BIN:-/usr/local/bin/xray}"
XRAY_CONFIG_DIR="${XRAY_CONFIG_DIR:-/etc/xray}"
XRAY_CONFIG="${XRAY_CONFIG:-/etc/xray/config.json}"
XRAY_CONFIG_TMP="${XRAY_CONFIG_TMP:-/etc/xray/config.tmp.json}"
XRAY_SHARE_DIR="${XRAY_SHARE_DIR:-/usr/local/share/xray}"
XRAY_SERVICE="${XRAY_SERVICE:-/etc/systemd/system/xray.service}"
SUPERVISOR_CONF_DIR="${SUPERVISOR_CONF_DIR:-/etc/supervisor/conf.d}"
SUPERVISOR_PROGRAM="${SUPERVISOR_PROGRAM:-nat-reality-bridge-xray}"
SUPERVISOR_CONFIG="${SUPERVISOR_CONFIG:-${SUPERVISOR_CONF_DIR}/${SUPERVISOR_PROGRAM}.conf}"
BACKUP_ROOT="${BACKUP_ROOT:-/root/xray-backups}"
APP_DIR="${APP_DIR:-/root/nat-reality-bridge}"
STATE_DIR="${STATE_DIR:-/var/lib/nat-reality-bridge}"
STATE_FILE="${STATE_FILE:-${STATE_DIR}/install-state}"
MANAGED_DIR="${MANAGED_DIR:-/etc/nat-reality-bridge}"
MANAGED_MARKER="${MANAGED_MARKER:-${MANAGED_DIR}/managed.marker}"
NODE_OUTPUT="${APP_DIR}/node.txt"
NODE_LEGACY_OUTPUT="/root/nat-reality-bridge-node.txt"
NODE_PNG="${APP_DIR}/node.png"
CLIENT_README="${APP_DIR}/README.txt"
INSTALL_SUMMARY="${APP_DIR}/install-summary.txt"
INSTALL_LOG="/var/log/nat-reality-bridge-install.log"

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
CONFIG_TEST_RESULT="not_run"
OUTBOUND_TEST_RESULT="not_run"
OUTBOUND_EXIT_IP=""
OUTBOUND_COUNTRY=""
OUTBOUND_ASN=""
XRAY_RUNNING="unknown"
QR_RESULT="not_run"
RESOURCE_MODE="NORMAL"
DOWNLOAD_TOOL=""
SWAP_MB="0"
SERVICE_BACKEND="NO_SERVICE_MANAGER"
PREVIOUS_STATE_STAGE=""
PREVIOUS_STATE_STATUS=""
RESUME_REQUESTED="no"
XRAY_NEW_BIN=""
STATE_WRITES_ENABLED="no"
XRAY_BINARY_ACTIVATED="no"
XRAY_CONFIG_ACTIVATED="no"
SERVICE_ARTIFACT_CREATED="no"
MANAGED_MARKER_ACTIVATED="no"
BACKUP_COMPLETED="no"
FAILURE_HANDLED="no"
TEMP_CONFIG_CREATED="no"
XRAY_NEW_BIN_CREATED="no"

banner() {
  cat <<'EOF'
================================
 NAT Reality Bridge Installer
================================
EOF
}

die() {
  if [ "${STATE_WRITES_ENABLED:-no}" = "yes" ] && [ -n "${STATE_FILE:-}" ] && [ -d "${STATE_DIR:-}" ]; then
    if [ "${BACKUP_COMPLETED:-no}" = "yes" ] || [ "${TEMP_CONFIG_CREATED:-no}" = "yes" ] || [ "${XRAY_NEW_BIN_CREATED:-no}" = "yes" ]; then
      handle_failed_transaction "${CURRENT_STAGE:-PRECHECK}" "installer_aborted"
    else
      state_update "${CURRENT_STAGE:-PRECHECK}" "FAILED" "installer_aborted" || true
    fi
  fi
  echo "ERROR: $*" >&2
  exit 1
}

state_value() {
  local key="$1"
  [ -f "$STATE_FILE" ] || return 0
  awk -F= -v key="$key" '$1 == key {sub($1 "=", ""); print; exit}' "$STATE_FILE"
}

state_update() {
  local stage="$1"
  local status="$2"
  local failure_reason="${3:-none}"
  local state_tmp
  CURRENT_STAGE="$stage"
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  state_tmp="${STATE_FILE}.tmp.$$"
  umask 077
  cat > "$state_tmp" <<EOF
stage=${stage}
updated_at=$(date -Is)
service_backend=${SERVICE_BACKEND}
backup_path=${LAST_BACKUP_DIR}
status=${status}
failure_reason=${failure_reason}
EOF
  chmod 600 "$state_tmp"
  mv -f "$state_tmp" "$STATE_FILE"
}

show_install_state() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "No NAT Reality Bridge install state found at: $STATE_FILE"
    return 0
  fi
  echo "NAT Reality Bridge install state"
  sed -n '1,6p' "$STATE_FILE"
}

describe_existing_config() {
  if [ -f "$XRAY_CONFIG" ]; then
    echo "Existing config: present ($XRAY_CONFIG)"
  else
    echo "Existing config: absent ($XRAY_CONFIG)"
  fi
  if [ -x "$XRAY_BIN" ]; then
    echo "Existing Xray binary: present ($XRAY_BIN)"
  else
    echo "Existing Xray binary: absent ($XRAY_BIN)"
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

write_managed_marker() {
  local marker_tmp install_id
  mkdir -p "$MANAGED_DIR"
  chmod 700 "$MANAGED_DIR"
  install_id="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
  marker_tmp="${MANAGED_MARKER}.tmp.$$"
  umask 077
  cat > "$marker_tmp" <<EOF
project=NAT Reality Bridge
marker_format=1
installed_version=${NRB_VERSION}
installed_at=$(date -Is)
install_id=${install_id}
EOF
  chmod 600 "$marker_tmp"
  mv -f "$marker_tmp" "$MANAGED_MARKER"
  MANAGED_MARKER_ACTIVATED="yes"
}

handle_previous_state() {
  [ -f "$STATE_FILE" ] || {
    if [ "$RESUME_REQUESTED" != "no" ]; then
      STATE_WRITES_ENABLED="no"
      die "No incomplete installation state was found. Run without --restart-interrupted for a new installation."
    fi
    return 0
  }

  PREVIOUS_STATE_STAGE="$(state_value stage)"
  PREVIOUS_STATE_STATUS="$(state_value status)"
  if [ "$PREVIOUS_STATE_STATUS" = "COMPLETE" ]; then
    if [ "$RESUME_REQUESTED" != "no" ]; then
      STATE_WRITES_ENABLED="no"
      die "The previous installation is already complete. Use --status to inspect it."
    fi
    return 0
  fi

  if [ "$RESUME_REQUESTED" = "no" ]; then
    echo "An incomplete NAT Reality Bridge installation was detected." >&2
    show_install_state >&2
    STATE_WRITES_ENABLED="no"
    die "Run '$0 --status' to inspect it or '$0 --restart-interrupted' to start a new protected transaction after confirmation."
  fi

  echo "Incomplete installation detected."
  echo "Current stage: ${PREVIOUS_STATE_STAGE:-unknown}"
  echo "Current status: ${PREVIOUS_STATE_STATUS:-unknown}"
  describe_existing_config
  echo "This does not resume individual stages or preserve newly generated node parameters." >&2
  printf "Restart the interrupted installation as a new protected transaction? Type yes: " >&2
  IFS= read -r answer
  if [ "$answer" != "yes" ]; then
    STATE_WRITES_ENABLED="no"
    die "Resume aborted."
  fi
}

detect_download_tool() {
  if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_TOOL="curl"
  elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_TOOL="wget"
  else
    die "curl or wget is required to download Xray-core. Install one of them first, or copy release files manually on extreme minimal systems."
  fi
}

download_file() {
  local url="$1"
  local output="$2"
  case "$DOWNLOAD_TOOL" in
    curl) curl -fL --connect-timeout 20 --retry 2 --retry-delay 2 -o "$output" "$url" ;;
    wget) wget -O "$output" --timeout=20 --tries=3 "$url" ;;
    *) die "No download tool selected." ;;
  esac
}

fetch_text() {
  local url="$1"
  case "$DOWNLOAD_TOOL" in
    curl) curl -fsS --max-time 20 "$url" ;;
    wget) wget -qO- --timeout=20 --tries=2 "$url" ;;
    *) return 1 ;;
  esac
}

init_paths() {
  mkdir -p "$APP_DIR"
  touch "$INSTALL_LOG"
  chmod 600 "$INSTALL_LOG"
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  STATE_WRITES_ENABLED="yes"
}

init_logging() {
  exec > >(tee -a "$INSTALL_LOG") 2>&1
  echo "== NAT Reality Bridge ${NRB_VERSION} install log =="
  echo "Started at: $(date -Is)"
}

need_root() {
  [ "$(id -u)" = "0" ] || die "This installer must run as root."
}

detect_service_manager() {
  local pid1
  SERVICE_BACKEND="NO_SERVICE_MANAGER"
  pid1="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')"

  if [ "$pid1" = "systemd" ] && command -v systemctl >/dev/null 2>&1; then
    if systemctl show --property=Version --value >/dev/null 2>&1 && \
       systemctl list-units --type=service --no-legend --no-pager >/dev/null 2>&1; then
      SERVICE_BACKEND="SYSTEMD_AVAILABLE"
      echo "Service manager: SYSTEMD_AVAILABLE"
      return 0
    fi
    echo "Service manager: SYSTEMD_UNAVAILABLE (systemd is PID 1, but the system bus is unavailable)" >&2
  else
    echo "Service manager: SYSTEMD_UNAVAILABLE (PID 1 is ${pid1:-unknown})" >&2
  fi

  if command -v supervisord >/dev/null 2>&1 && command -v supervisorctl >/dev/null 2>&1; then
    if supervisorctl status >/dev/null 2>&1; then
      SERVICE_BACKEND="SUPERVISOR_AVAILABLE"
      echo "Service manager: SUPERVISOR_AVAILABLE"
      return 0
    fi
  fi

  echo "Service manager: NO_SERVICE_MANAGER" >&2
  return 1
}

json_section_protocol_count() {
  local section="$1"
  local next_section="$2"
  awk -v section="\"${section}\"" -v next_section="\"${next_section}\"" '
    $0 ~ section { inside=1; next }
    inside && $0 ~ next_section { exit }
    inside && $0 ~ /"protocol"[[:space:]]*:/ { count++ }
    END { print count + 0 }
  ' "$XRAY_CONFIG"
}

is_supported_single_node_config() {
  local inbound_count outbound_count
  inbound_count="$(json_section_protocol_count inbounds outbounds)"
  outbound_count="$(json_section_protocol_count outbounds routing)"
  if [ "$outbound_count" -eq 0 ]; then
    outbound_count="$(awk '
      /"outbounds"/ { inside=1; next }
      inside && /"protocol"[[:space:]]*:/ { count++ }
      END { print count + 0 }
    ' "$XRAY_CONFIG")"
  fi

  [ "$inbound_count" -eq 1 ] || return 1
  [ "$outbound_count" -eq 2 ] || return 1
  grep -Eq '"tag"[[:space:]]*:[[:space:]]*"vless-reality-in"' "$XRAY_CONFIG" || return 1
  grep -Eq '"protocol"[[:space:]]*:[[:space:]]*"vless"' "$XRAY_CONFIG" || return 1
  grep -Eq '"security"[[:space:]]*:[[:space:]]*"reality"' "$XRAY_CONFIG" || return 1
  grep -Eq '"tag"[[:space:]]*:[[:space:]]*"block"' "$XRAY_CONFIG" || return 1
  grep -Eq '"tag"[[:space:]]*:[[:space:]]*"(direct|isp-socks5)"' "$XRAY_CONFIG" || return 1
}

protect_existing_config() {
  [ -f "$XRAY_CONFIG" ] || return 0
  if ! is_valid_managed_marker; then
    echo "Existing Xray config has no valid NAT Reality Bridge ownership marker." >&2
    echo "Installation aborted to avoid overwriting user-managed configuration." >&2
    die "Create a fresh environment or manage the existing configuration manually."
  fi
  if ! is_supported_single_node_config; then
    echo "Detected existing advanced Xray configuration." >&2
    echo "Installation aborted to avoid overwrite." >&2
    die "Existing config is not the supported single-node NAT Reality Bridge structure."
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

preflight() {
  echo
  echo "== preflight checks =="
  detect_download_tool
  echo "Download tool: ${DOWNLOAD_TOOL}"
  case "$XRAY_CONFIG_TMP" in
    *.json) ;;
    *) die "Temporary Xray config path must end in .json: $XRAY_CONFIG_TMP" ;;
  esac
  command -v unzip >/dev/null || die "unzip is required."
  command -v sha256sum >/dev/null || die "sha256sum is required."
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
  swap_kb="$(awk '/SwapTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
  SWAP_MB="$((swap_kb / 1024))"
  disk_kb="$(df -Pk /usr/local 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)"
  echo "Memory: $((mem_kb / 1024)) MB"
  echo "Swap: ${SWAP_MB} MB"
  echo "Free disk under /usr/local: $((disk_kb / 1024)) MB"
  if [ "$mem_kb" -lt 80000 ]; then
    RESOURCE_MODE="EXTREME_LOW_RESOURCE"
  elif [ "$mem_kb" -lt 160000 ]; then
    RESOURCE_MODE="LOW_RESOURCE"
  else
    RESOURCE_MODE="NORMAL"
  fi
  echo "Resource mode: ${RESOURCE_MODE}"
  if [ "$RESOURCE_MODE" = "EXTREME_LOW_RESOURCE" ]; then
    echo "Warning: 64MB-class VPS detected. Skipping non-essential network checks and optional QR package installation." >&2
  elif [ "$RESOURCE_MODE" = "LOW_RESOURCE" ]; then
    echo "Low-resource mode: enabled"
    [ "$swap_kb" -gt 0 ] || echo "Warning: swap is recommended on 128MB-class VPS nodes." >&2
  fi
  [ "$disk_kb" -ge 51200 ] || die "At least 50 MB free disk under /usr/local is required."

  ipv4_addr="$(ip -4 -o addr show scope global 2>/dev/null | awk '{split($4,a,"/"); print a[1]; exit}')"
  if [ -n "$ipv4_addr" ]; then
    echo "IPv4: detected"
    case "$ipv4_addr" in
      10.*|192.168.*|172.16.*|172.17.*|172.18.*|172.19.*|172.20.*|172.21.*|172.22.*|172.23.*|172.24.*|172.25.*|172.26.*|172.27.*|172.28.*|172.29.*|172.30.*|172.31.*|100.64.*|100.65.*|100.66.*|100.67.*|100.68.*|100.69.*|100.70.*|100.71.*|100.72.*|100.73.*|100.74.*|100.75.*|100.76.*|100.77.*|100.78.*|100.79.*|100.80.*|100.81.*|100.82.*|100.83.*|100.84.*|100.85.*|100.86.*|100.87.*|100.88.*|100.89.*|100.90.*|100.91.*|100.92.*|100.93.*|100.94.*|100.95.*|100.96.*|100.97.*|100.98.*|100.99.*|100.100.*|100.101.*|100.102.*|100.103.*|100.104.*|100.105.*|100.106.*|100.107.*|100.108.*|100.109.*|100.110.*|100.111.*|100.112.*|100.113.*|100.114.*|100.115.*|100.116.*|100.117.*|100.118.*|100.119.*|100.120.*|100.121.*|100.122.*|100.123.*|100.124.*|100.125.*|100.126.*|100.127.*)
        echo "NAT environment: likely provider-side NAT or private IPv4"
        ;;
      *)
        echo "NAT environment: public or routed IPv4 detected"
        ;;
    esac
  else
    echo "Warning: no global IPv4 address detected. Provider NAT mapping may still work, but verify it carefully." >&2
  fi

  if ! detect_service_manager; then
    die "No reliable service manager is available. Xray configuration has not been activated. Install and start Supervisor outside this installer, or use a Debian systemd environment."
  fi

  protect_existing_config
  state_update "PRECHECK" "IN_PROGRESS"
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
  for p in "$XRAY_CONFIG" "$XRAY_SERVICE" "$SUPERVISOR_CONFIG" "$XRAY_BIN" "$XRAY_SHARE_DIR/geoip.dat" "$XRAY_SHARE_DIR/geosite.dat" "$NODE_OUTPUT" "$NODE_LEGACY_OUTPUT" "$NODE_PNG" "$CLIENT_README" "$INSTALL_SUMMARY" "$MANAGED_MARKER"; do
    if [ -e "$p" ]; then
      cp -a "$p" "$LAST_BACKUP_DIR/$(echo "$p" | sed 's#^/##; s#/#_#g')"
    fi
  done
  echo "Backup directory: $LAST_BACKUP_DIR"
  state_update "BACKUP_CREATED" "IN_PROGRESS"
  BACKUP_COMPLETED="yes"
}

cleanup_failed_transaction() {
  [ "$TEMP_CONFIG_CREATED" = "yes" ] && rm -f "$XRAY_CONFIG_TMP"
  [ "$XRAY_NEW_BIN_CREATED" = "yes" ] && rm -f "$XRAY_NEW_BIN"
  rm -f "${STATE_FILE}.tmp.$$" "${MANAGED_MARKER}.tmp.$$"

  [ "$BACKUP_COMPLETED" = "yes" ] || return 0

  for spec in \
    "$NODE_OUTPUT|root_nat-reality-bridge_node.txt" \
    "$NODE_LEGACY_OUTPUT|root_nat-reality-bridge-node.txt" \
    "$NODE_PNG|root_nat-reality-bridge_node.png" \
    "$CLIENT_README|root_nat-reality-bridge_README.txt" \
    "$INSTALL_SUMMARY|root_nat-reality-bridge_install-summary.txt"; do
    target="${spec%%|*}"
    backup_name="${spec#*|}"
    [ -f "$LAST_BACKUP_DIR/$backup_name" ] || rm -f "$target"
  done
}

rollback() {
  if [ -z "$LAST_BACKUP_DIR" ] || [ ! -d "$LAST_BACKUP_DIR" ]; then
    echo "No rollback backup is available." >&2
    return 1
  fi
  echo "Rolling back from $LAST_BACKUP_DIR" >&2
  if [ "$XRAY_CONFIG_ACTIVATED" = "yes" ]; then
    if [ -f "$LAST_BACKUP_DIR/etc_xray_config.json" ]; then
      cp -a "$LAST_BACKUP_DIR/etc_xray_config.json" "$XRAY_CONFIG"
    else
      rm -f "$XRAY_CONFIG"
    fi
  fi
  if [ "$SERVICE_BACKEND" = "SYSTEMD_AVAILABLE" ]; then
    if [ -f "$LAST_BACKUP_DIR/etc_systemd_system_xray.service" ]; then
      cp -a "$LAST_BACKUP_DIR/etc_systemd_system_xray.service" "$XRAY_SERVICE"
    elif [ "$SERVICE_ARTIFACT_CREATED" = "yes" ]; then
      rm -f "$XRAY_SERVICE"
    fi
  elif [ "$SERVICE_BACKEND" = "SUPERVISOR_AVAILABLE" ]; then
    if [ -f "$LAST_BACKUP_DIR/etc_supervisor_conf.d_${SUPERVISOR_PROGRAM}.conf" ]; then
      cp -a "$LAST_BACKUP_DIR/etc_supervisor_conf.d_${SUPERVISOR_PROGRAM}.conf" "$SUPERVISOR_CONFIG"
    elif [ "$SERVICE_ARTIFACT_CREATED" = "yes" ]; then
      rm -f "$SUPERVISOR_CONFIG"
    fi
  fi
  if [ "$XRAY_BINARY_ACTIVATED" = "yes" ]; then
    if [ -f "$LAST_BACKUP_DIR/usr_local_bin_xray" ]; then
      cp -a "$LAST_BACKUP_DIR/usr_local_bin_xray" "${XRAY_BIN}.rollback.$$"
      chmod 755 "${XRAY_BIN}.rollback.$$"
      mv -f "${XRAY_BIN}.rollback.$$" "$XRAY_BIN"
    else
      rm -f "$XRAY_BIN"
    fi
  fi
  [ -f "$LAST_BACKUP_DIR/usr_local_share_xray_geoip.dat" ] && cp -a "$LAST_BACKUP_DIR/usr_local_share_xray_geoip.dat" "$XRAY_SHARE_DIR/geoip.dat"
  [ -f "$LAST_BACKUP_DIR/usr_local_share_xray_geosite.dat" ] && cp -a "$LAST_BACKUP_DIR/usr_local_share_xray_geosite.dat" "$XRAY_SHARE_DIR/geosite.dat"
  [ -f "$LAST_BACKUP_DIR/root_nat-reality-bridge_node.txt" ] && cp -a "$LAST_BACKUP_DIR/root_nat-reality-bridge_node.txt" "$NODE_OUTPUT"
  [ -f "$LAST_BACKUP_DIR/root_nat-reality-bridge-node.txt" ] && cp -a "$LAST_BACKUP_DIR/root_nat-reality-bridge-node.txt" "$NODE_LEGACY_OUTPUT"
  [ -f "$LAST_BACKUP_DIR/root_nat-reality-bridge_node.png" ] && cp -a "$LAST_BACKUP_DIR/root_nat-reality-bridge_node.png" "$NODE_PNG"
  [ -f "$LAST_BACKUP_DIR/root_nat-reality-bridge_README.txt" ] && cp -a "$LAST_BACKUP_DIR/root_nat-reality-bridge_README.txt" "$CLIENT_README"
  [ -f "$LAST_BACKUP_DIR/root_nat-reality-bridge_install-summary.txt" ] && cp -a "$LAST_BACKUP_DIR/root_nat-reality-bridge_install-summary.txt" "$INSTALL_SUMMARY"
  if [ "$MANAGED_MARKER_ACTIVATED" = "yes" ]; then
    if [ -f "$LAST_BACKUP_DIR/etc_nat-reality-bridge_managed.marker" ]; then
      mkdir -p "$MANAGED_DIR"
      cp -a "$LAST_BACKUP_DIR/etc_nat-reality-bridge_managed.marker" "$MANAGED_MARKER"
    else
      rm -f "$MANAGED_MARKER"
      rmdir "$MANAGED_DIR" 2>/dev/null || true
    fi
  fi
  case "$SERVICE_BACKEND" in
    SYSTEMD_AVAILABLE)
      systemctl daemon-reload || true
      systemctl restart xray || true
      ;;
    SUPERVISOR_AVAILABLE)
      supervisorctl reread || true
      supervisorctl update || true
      supervisorctl restart "$SUPERVISOR_PROGRAM" || true
      ;;
  esac
}

handle_failed_transaction() {
  local failed_stage="$1"
  local failure_reason="$2"

  [ "$FAILURE_HANDLED" = "yes" ] && return 0
  FAILURE_HANDLED="yes"
  state_update "$failed_stage" "FAILED" "$failure_reason" || true
  rollback || true
  cleanup_failed_transaction
}

on_error() {
  echo "Installation failed. Attempting rollback." >&2
  handle_failed_transaction "${CURRENT_STAGE:-PRECHECK}" "unexpected_error"
}

install_xray() {
  workdir="/tmp/nat-reality-bridge-install-$$"
  asset="Xray-linux-64.zip"
  base_url="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}"
  mkdir -p "$workdir"
  trap 'rm -rf "$workdir"' EXIT
  cd "$workdir"
  download_file "$base_url/$asset" "$asset"
  download_file "$base_url/$asset.dgst" "$asset.dgst"
  calc="$(sha256sum "$asset" | awk '{print $1}')"
  grep -qi "$calc" "$asset.dgst" || die "SHA256 verification failed."
  mkdir -p "$XRAY_SHARE_DIR" "$XRAY_CONFIG_DIR"
  state_update "ARTIFACT_VERIFIED" "IN_PROGRESS"

  XRAY_NEW_BIN="${XRAY_BIN}.new.$$"
  XRAY_NEW_BIN_CREATED="yes"
  umask 077
  unzip -p "$asset" xray > "$XRAY_NEW_BIN"
  chmod 755 "$XRAY_NEW_BIN"
  "$XRAY_NEW_BIN" version >/dev/null
  state_update "BINARY_READY" "IN_PROGRESS"
}

activate_xray_binary() {
  [ -n "$XRAY_NEW_BIN" ] && [ -x "$XRAY_NEW_BIN" ] || die "Validated replacement Xray binary is missing."
  mv -f "$XRAY_NEW_BIN" "$XRAY_BIN"
  XRAY_NEW_BIN=""
  XRAY_NEW_BIN_CREATED="no"
  XRAY_BINARY_ACTIVATED="yes"
}

generate_reality_values() {
  local generator_bin
  generator_bin="${XRAY_NEW_BIN:-$XRAY_BIN}"
  UUID_VALUE="$($generator_bin uuid)"
  keys="$($generator_bin x25519)"
  REALITY_PRIVATE_KEY="$(printf '%s\n' "$keys" | awk -F': *' 'tolower($1) ~ /^private ?key$/ {print $2; exit}')"
  REALITY_PUBLIC_KEY="$(printf '%s\n' "$keys" | awk -F': *' 'tolower($1) ~ /^(public ?key|password \(publickey\))$/ {print $2; exit}')"
  REALITY_SHORT_ID="$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
  [ -n "$UUID_VALUE" ] && [ -n "$REALITY_PRIVATE_KEY" ] && [ -n "$REALITY_PUBLIC_KEY" ] && [ -n "$REALITY_SHORT_ID" ] || die "Failed to generate Reality values."
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_temp_config() {
  [ ! -e "$XRAY_CONFIG_TMP" ] || die "Temporary config path already exists: $XRAY_CONFIG_TMP"
  TEMP_CONFIG_CREATED="yes"
  umask 077
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
  SERVICE_ARTIFACT_CREATED="yes"
}

write_supervisor_program() {
  mkdir -p "$SUPERVISOR_CONF_DIR"
  cat > "$SUPERVISOR_CONFIG" <<EOF
[program:${SUPERVISOR_PROGRAM}]
command=${XRAY_BIN} run -config ${XRAY_CONFIG}
directory=/root
autostart=true
autorestart=true
startsecs=2
startretries=3
user=root
redirect_stderr=true
stdout_logfile=/var/log/${SUPERVISOR_PROGRAM}.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=1
EOF
  chmod 600 "$SUPERVISOR_CONFIG"
  SERVICE_ARTIFACT_CREATED="yes"
}

config_test() {
  local test_bin
  test_bin="${XRAY_NEW_BIN:-$XRAY_BIN}"
  "$test_bin" run -test -config "$XRAY_CONFIG_TMP"
}

activate_config() {
  install -m 0600 "$XRAY_CONFIG_TMP" "$XRAY_CONFIG"
  rm -f "$XRAY_CONFIG_TMP"
  TEMP_CONFIG_CREATED="no"
  XRAY_CONFIG_ACTIVATED="yes"
  state_update "CONFIG_ACTIVATED" "IN_PROGRESS"
}

restart_service() {
  case "$SERVICE_BACKEND" in
    SYSTEMD_AVAILABLE)
      write_service
      systemctl daemon-reload
      systemctl enable xray >/dev/null
      systemctl restart xray
      sleep 2
      if systemctl is-active --quiet xray; then
        XRAY_RUNNING="yes"
      else
        XRAY_RUNNING="no"
      fi
      systemctl --no-pager --full status xray | sed -n '1,45p'
      ;;
    SUPERVISOR_AVAILABLE)
      write_supervisor_program
      supervisorctl reread
      supervisorctl update
      supervisorctl restart "$SUPERVISOR_PROGRAM"
      sleep 2
      if supervisorctl status "$SUPERVISOR_PROGRAM" | grep -q RUNNING; then
        XRAY_RUNNING="yes"
      else
        XRAY_RUNNING="no"
      fi
      supervisorctl status "$SUPERVISOR_PROGRAM"
      ;;
    *)
      die "No reliable service manager was selected."
      ;;
  esac
  [ "$XRAY_RUNNING" = "yes" ] || die "Xray did not reach a running state."
  state_update "SERVICE_STARTED" "IN_PROGRESS"
}

fetch_ip_meta() {
  local ip="$1"
  if [ "$RESOURCE_MODE" = "EXTREME_LOW_RESOURCE" ]; then
    return 0
  fi
  OUTBOUND_COUNTRY="$(fetch_text "https://ipapi.co/${ip}/country_name/" 2>/dev/null || true)"
  OUTBOUND_ASN="$(fetch_text "https://ipapi.co/${ip}/asn/" 2>/dev/null || true)"
}

test_outbound() {
  echo
  echo "== outbound test =="
  if [ "$RESOURCE_MODE" = "EXTREME_LOW_RESOURCE" ]; then
    OUTBOUND_TEST_RESULT="skipped"
    echo "Outbound test skipped in EXTREME_LOW_RESOURCE mode to reduce memory and network overhead."
    return 0
  fi
  if [ "$DEPLOY_MODE" = "isp" ]; then
    if ! command -v curl >/dev/null 2>&1; then
      OUTBOUND_TEST_RESULT="skipped"
      echo "SOCKS5 outbound test skipped because curl is not available."
      echo "Reason: wget does not provide the SOCKS5 test path used by this installer."
      return 0
    fi
    if OUTBOUND_EXIT_IP="$(curl --socks5-hostname "${ISP_SOCKS5_USER}:${ISP_SOCKS5_PASSWORD}@${ISP_SOCKS5_HOST}:${ISP_SOCKS5_PORT}" -fsS --max-time 20 https://api.ipify.org 2>/dev/null)"; then
      OUTBOUND_TEST_RESULT="passed"
      fetch_ip_meta "$OUTBOUND_EXIT_IP"
      echo "SOCKS5 connection: ok"
    else
      OUTBOUND_TEST_RESULT="failed"
      echo "SOCKS5 connection: failed"
      echo "Reason: unable to reach the test endpoint through the SOCKS5 outbound."
      return 0
    fi
  else
    if OUTBOUND_EXIT_IP="$(fetch_text "https://api.ipify.org" 2>/dev/null)"; then
      OUTBOUND_TEST_RESULT="passed"
      fetch_ip_meta "$OUTBOUND_EXIT_IP"
    else
      OUTBOUND_TEST_RESULT="failed"
      echo "Native exit test: failed"
      echo "Reason: unable to reach the public IP test endpoint from this VPS."
      return 0
    fi
  fi
  echo "Exit IP: ${OUTBOUND_EXIT_IP}"
  [ -n "$OUTBOUND_COUNTRY" ] && echo "Country: ${OUTBOUND_COUNTRY}"
  [ -n "$OUTBOUND_ASN" ] && echo "ASN: ${OUTBOUND_ASN}"
}

write_client_readme() {
  cat > "$CLIENT_README" <<EOF
NAT Reality Bridge ${NRB_VERSION}

Files:
- node.txt: VLESS URI and client parameters.
- node.png: QR code for the VLESS URI, if qrencode was available.
- install-summary.txt: installation status summary.

Android:
- Open v2rayNG.
- Use scan QR code or import from clipboard.

Windows:
- Use Nekobox or Karing.
- Import the vless:// URI from node.txt.

iOS:
- Use Karing or another compatible client.
- Scan node.png or import the vless:// URI.

Security:
- Do not publish node.txt or node.png.
- Do not share Reality privateKey. It is never written to this client file.
EOF
  chmod 600 "$CLIENT_README"
}

generate_qr_code() {
  QR_RESULT="skipped"
  if [ "$RESOURCE_MODE" = "EXTREME_LOW_RESOURCE" ]; then
    echo "QR code generation skipped in EXTREME_LOW_RESOURCE mode."
    return 0
  fi
  if ! command -v qrencode >/dev/null 2>&1; then
    echo
    echo "qrencode is not installed."
    echo "QR code generation is optional. Install qrencode manually if you want PNG or terminal QR output."
  fi

  if command -v qrencode >/dev/null 2>&1; then
    echo
    echo "QR code:"
    qrencode -t ANSIUTF8 "$vless_uri" || true
    if qrencode -o "$NODE_PNG" "$vless_uri"; then
      chmod 600 "$NODE_PNG"
      QR_RESULT="generated"
    else
      QR_RESULT="failed"
      echo "PNG QR code generation failed. The node URI is still available in ${NODE_OUTPUT}."
    fi
  else
    echo "QR code skipped. Install qrencode and run: qrencode -o ${NODE_PNG} '<VLESS_URI>'"
  fi
}

write_install_summary() {
  cat > "$INSTALL_SUMMARY" <<EOF
NAT Reality Bridge version: ${NRB_VERSION}
Deployment mode: ${DEPLOY_MODE}
Service backend: ${SERVICE_BACKEND}
Xray running: ${XRAY_RUNNING}
Config test result: ${CONFIG_TEST_RESULT}
Outbound test result: ${OUTBOUND_TEST_RESULT}
Exit IP: ${OUTBOUND_EXIT_IP:-unknown}
Country: ${OUTBOUND_COUNTRY:-unknown}
ASN: ${OUTBOUND_ASN:-unknown}
QR code: ${QR_RESULT}
Installed at: $(date -Is)
EOF
  chmod 600 "$INSTALL_SUMMARY"
}

print_completion_summary() {
  echo
  echo "NAT Reality Bridge ${NRB_VERSION}"
  echo
  echo "Installation completed"
  echo
  echo "Status:"
  [ "$XRAY_RUNNING" = "yes" ] && echo "[OK] Xray running" || echo "[WARN] Xray not running"
  [ "$CONFIG_TEST_RESULT" = "passed" ] && echo "[OK] Configuration valid" || echo "[WARN] Configuration test: ${CONFIG_TEST_RESULT}"
  [ "$OUTBOUND_TEST_RESULT" = "passed" ] && echo "[OK] Outbound test passed" || echo "[WARN] Outbound test: ${OUTBOUND_TEST_RESULT}"
  echo
  echo "Mode: ${DEPLOY_MODE}"
  echo "Reality: VLESS Reality TCP Vision"
  echo "Node file: ${NODE_OUTPUT}"
  echo "QR PNG: ${NODE_PNG}"
  echo "Client README: ${CLIENT_README}"
  echo "Install summary: ${INSTALL_SUMMARY}"
  echo "Install log: ${INSTALL_LOG}"
}

generate_uri() {
  spx_encoded="%2F"
  vless_uri="vless://${UUID_VALUE}@${PUBLIC_HOST}:${PUBLIC_PORT}?encryption=none&flow=${FLOW}&security=reality&sni=${REALITY_SERVER_NAME}&fp=chrome&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}&type=tcp&headerType=none&spx=${spx_encoded}#${NODE_NAME}"
  mkdir -p "$APP_DIR"
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
SOCKS5_HOST=${ISP_SOCKS5_HOST}
SOCKS5_PORT=${ISP_SOCKS5_PORT}
VLESS_URI=${vless_uri}
EOF
  chmod 600 "$NODE_OUTPUT"
  install -m 0600 "$NODE_OUTPUT" "$NODE_LEGACY_OUTPUT"
  write_client_readme
  generate_qr_code

  echo
  echo "Node connection information"
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

main() {
  banner
  case "${1:-}" in
    --status)
      show_install_state
      return 0
      ;;
    --resume|--restart-interrupted)
      RESUME_REQUESTED="yes"
      ;;
    "")
      ;;
    *)
      die "Unknown option: $1. Supported options: --status, --restart-interrupted (or legacy --resume)"
      ;;
  esac
  need_root
  init_paths
  init_logging
  trap on_error ERR
  handle_previous_state
  preflight
  choose_mode
  collect_common_inputs
  collect_isp_inputs
  show_plan
  backup_existing
  install_xray
  generate_reality_values
  write_temp_config
  if config_test; then
    CONFIG_TEST_RESULT="passed"
    state_update "CONFIG_TESTED" "IN_PROGRESS"
  else
    CONFIG_TEST_RESULT="failed"
    echo "Configuration test failed. Previous files are being restored and temporary secrets removed." >&2
    handle_failed_transaction "CONFIG_TESTED" "config_test_failed"
    return 1
  fi
  activate_xray_binary
  activate_config
  restart_service
  test_outbound
  generate_uri
  write_install_summary
  write_managed_marker
  state_update "COMPLETE" "COMPLETE"
  print_completion_summary
  trap - ERR
}

main "$@"
