#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-}"
if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    echo "Config not found: ${CONFIG_PATH}" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "${CONFIG_PATH}"
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd pct
require_cmd pveam
require_cmd awk

DRY_RUN=${DRY_RUN:-"false"}
if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

PVE_STORAGE=${PVE_STORAGE:-"local-lvm"}
PVE_TEMPLATE=${PVE_TEMPLATE:-"local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"}
PVE_BRIDGE=${PVE_BRIDGE:-"vmbr0"}
PVE_GATEWAY=${PVE_GATEWAY:-""}
PVE_DNS=${PVE_DNS:-"1.1.1.1"}

GITEA_CTID=${GITEA_CTID:-"9100"}
GITEA_HOSTNAME=${GITEA_HOSTNAME:-"gitea"}
GITEA_MEMORY=${GITEA_MEMORY:-"4096"}
GITEA_CORES=${GITEA_CORES:-"2"}
GITEA_DISK=${GITEA_DISK:-"20"}
GITEA_IP=${GITEA_IP:-"dhcp"}
GITEA_HTTP_PORT=${GITEA_HTTP_PORT:-"3000"}
GITEA_SSH_PORT=${GITEA_SSH_PORT:-"2222"}
GITEA_DOMAIN=${GITEA_DOMAIN:-"gitea.local"}
GITEA_VERSION=${GITEA_VERSION:-"1.22.2"}
GITEA_DATA_DIR=${GITEA_DATA_DIR:-"/opt/gitea/data"}

GITEA_DB_TYPE=${GITEA_DB_TYPE:-"sqlite3"}
GITEA_DB_HOST=${GITEA_DB_HOST:-""}
GITEA_DB_NAME=${GITEA_DB_NAME:-"gitea"}
GITEA_DB_USER=${GITEA_DB_USER:-"gitea"}
GITEA_DB_PASS=${GITEA_DB_PASS:-""}

ensure_template() {
  local storage template_path template_file
  storage="${PVE_TEMPLATE%%:*}"
  template_path="${PVE_TEMPLATE#*:}"
  template_file="${template_path#vztmpl/}"

  if ! pveam list "${storage}" | awk '{print $1}' | grep -q "${template_file}"; then
    echo "Template ${template_file} not found in ${storage}"
    if [[ "${DRY_RUN}" == "true" ]]; then
      echo "[dry-run] would download template ${template_file} into ${storage}"
      return
    fi
    echo "Downloading template ${template_file} into ${storage}"
    pveam update
    pveam download "${storage}" "${template_file}"
  fi
}

create_container() {
  local ctid=$1
  local hostname=$2
  local memory=$3
  local cores=$4
  local disk=$5
  local ip=$6

  if pct status "${ctid}" >/dev/null 2>&1; then
    echo "Container ${ctid} already exists. Skipping create."
    return
  fi

  local net_conf
  if [[ "${ip}" == "dhcp" ]]; then
    net_conf="name=eth0,bridge=${PVE_BRIDGE},ip=dhcp"
  else
    if [[ -z "${PVE_GATEWAY}" ]]; then
      echo "PVE_GATEWAY is required for static IP" >&2
      exit 1
    fi
    net_conf="name=eth0,bridge=${PVE_BRIDGE},ip=${ip},gw=${PVE_GATEWAY}"
  fi

  pct create "${ctid}" "${PVE_TEMPLATE}" \
    -hostname "${hostname}" \
    -cores "${cores}" \
    -memory "${memory}" \
    -swap 512 \
    -rootfs "${PVE_STORAGE}:${disk}" \
    -net0 "${net_conf}" \
    -features keyctl=1,nesting=1 \
    -unprivileged 1 \
    -nameserver "${PVE_DNS}" >/dev/null

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] would start container ${ctid}"
  else
    pct start "${ctid}" >/dev/null
  fi
}

install_docker() {
  local ctid=$1
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] would install docker in CT ${ctid}"
    return
  fi
  pct exec "${ctid}" -- bash -c "set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release docker.io docker-compose-plugin
    systemctl enable --now docker
  "
}

configure_gitea() {
  local ctid=$1
  local root_url
  root_url=${GITEA_ROOT_URL:-"http://${GITEA_DOMAIN}:${GITEA_HTTP_PORT}/"}

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] would configure Gitea in CT ${ctid}"
    echo "[dry-run] root_url=${root_url}"
    return
  fi

  pct exec "${ctid}" -- bash -c "set -euo pipefail
    install -d /opt/gitea
    install -d ${GITEA_DATA_DIR}
    cat <<'YAML' > /opt/gitea/docker-compose.yml
services:
  gitea:
    image: gitea/gitea:${GITEA_VERSION}
    container_name: gitea
    restart: unless-stopped
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__server__DOMAIN=${GITEA_DOMAIN}
      - GITEA__server__ROOT_URL=${root_url}
      - GITEA__server__SSH_DOMAIN=${GITEA_DOMAIN}
      - GITEA__server__HTTP_PORT=${GITEA_HTTP_PORT}
      - GITEA__server__SSH_PORT=${GITEA_SSH_PORT}
      - GITEA__database__DB_TYPE=${GITEA_DB_TYPE}
      - GITEA__database__HOST=${GITEA_DB_HOST}
      - GITEA__database__NAME=${GITEA_DB_NAME}
      - GITEA__database__USER=${GITEA_DB_USER}
      - GITEA__database__PASSWD=${GITEA_DB_PASS}
    volumes:
      - ${GITEA_DATA_DIR}:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - \"${GITEA_HTTP_PORT}:3000\"
      - \"${GITEA_SSH_PORT}:22\"
YAML

    cat <<'SERVICE' > /etc/systemd/system/gitea-compose.service
[Unit]
Description=Gitea (docker compose)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
WorkingDirectory=/opt/gitea
RemainAfterExit=true
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable --now gitea-compose.service
  "
}

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[dry-run] Dry run enabled. No changes will be applied."
fi

ensure_template
create_container "${GITEA_CTID}" "${GITEA_HOSTNAME}" "${GITEA_MEMORY}" "${GITEA_CORES}" "${GITEA_DISK}" "${GITEA_IP}"
install_docker "${GITEA_CTID}"
configure_gitea "${GITEA_CTID}"

echo "Gitea deployment complete. URL: http://${GITEA_DOMAIN}:${GITEA_HTTP_PORT}"
