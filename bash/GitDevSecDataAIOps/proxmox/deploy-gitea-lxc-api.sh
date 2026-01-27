#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CS_ROOT="${SCRIPT_DIR}"
while [[ ! -f "${CS_ROOT}/lib/cs-common.sh" ]]; do
  if [[ "${CS_ROOT}" == "/" ]]; then
    echo "cs-common.sh not found" >&2
    exit 1
  fi
  CS_ROOT=$(dirname "${CS_ROOT}")
done
# shellcheck disable=SC1090,SC1091
source "${CS_ROOT}/lib/cs-common.sh"

# shellcheck disable=SC2034
CS_LOG_PREFIX="deploy-gitea-api"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

require_cmd() {
  cs_require_cmd "$1"
}

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/proxmox/deploy-gitea-lxc-api.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

DRY_RUN=${DRY_RUN:-"false"}
if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

PVE_API_URL=${PVE_API_URL:-""}
PVE_API_TOKEN=${PVE_API_TOKEN:-""}
PVE_INSECURE=${PVE_INSECURE:-"false"}
PVE_NODE=${PVE_NODE:-"pve"}
PVE_STORAGE=${PVE_STORAGE:-"local-lvm"}
PVE_TEMPLATE=${PVE_TEMPLATE:-"local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"}
PVE_BRIDGE=${PVE_BRIDGE:-"vmbr0"}
PVE_GATEWAY=${PVE_GATEWAY:-""}
PVE_DNS=${PVE_DNS:-"1.1.1.1"}
PVE_SWAP=${PVE_SWAP:-"512"}
PVE_FEATURES=${PVE_FEATURES:-"keyctl=1,nesting=1"}
PVE_UNPRIVILEGED=${PVE_UNPRIVILEGED:-"1"}
PVE_ONBOOT=${PVE_ONBOOT:-"1"}
PVE_ROOT_PASSWORD=${PVE_ROOT_PASSWORD:-""}
PVE_SSH_KEYS=${PVE_SSH_KEYS:-""}

cs_warn_debian13_template "${PVE_TEMPLATE}"

GITEA_CTID=${GITEA_CTID:-"9100"}
GITEA_HOSTNAME=${GITEA_HOSTNAME:-"gitea"}
GITEA_MEMORY=${GITEA_MEMORY:-"4096"}
GITEA_CORES=${GITEA_CORES:-"2"}
GITEA_DISK=${GITEA_DISK:-"40"}
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

BOOTSTRAP_SSH=${BOOTSTRAP_SSH:-"false"}
BOOTSTRAP_SSH_HOST=${BOOTSTRAP_SSH_HOST:-""}
BOOTSTRAP_SSH_USER=${BOOTSTRAP_SSH_USER:-"root"}
BOOTSTRAP_SSH_PORT=${BOOTSTRAP_SSH_PORT:-"22"}
BOOTSTRAP_SSH_KEY=${BOOTSTRAP_SSH_KEY:-""}
BOOTSTRAP_SSH_STRICT=${BOOTSTRAP_SSH_STRICT:-"true"}
BOOTSTRAP_SSH_CONNECT_TIMEOUT=${BOOTSTRAP_SSH_CONNECT_TIMEOUT:-"10"}
BOOTSTRAP_SSH_WAIT_SECS=${BOOTSTRAP_SSH_WAIT_SECS:-"60"}
BOOTSTRAP_SSH_SLEEP=${BOOTSTRAP_SSH_SLEEP:-"5"}

require_cmd jq
require_cmd curl

API_CLIENT="${SCRIPT_DIR}/pve-api-client.sh"
if [[ ! -x "${API_CLIENT}" ]]; then
  fail "pve-api-client.sh not found or not executable at ${API_CLIENT}"
fi

if [[ -z "${PVE_API_URL}" || -z "${PVE_API_TOKEN}" ]]; then
  fail "PVE_API_URL and PVE_API_TOKEN are required"
fi

api_call() {
  local method=$1
  local path=$2
  shift 2 || true
  if [[ -n "${CONFIG_PATH}" ]]; then
    env DRY_RUN="${DRY_RUN}" bash "${API_CLIENT}" "${CONFIG_PATH}" "${method}" "${path}" "$@"
  else
    env DRY_RUN="${DRY_RUN}" bash "${API_CLIENT}" "" "${method}" "${path}" "$@"
  fi
}

api_get() {
  local path=$1
  shift || true
  local prev="${DRY_RUN}"
  DRY_RUN="false"
  api_call GET "${path}" "$@"
  DRY_RUN="${prev}"
}

api_post() {
  local path=$1
  shift || true
  DRY_RUN="${DRY_RUN}" api_call POST "${path}" "$@"
}

check_template() {
  local template_path template_file
  template_path="${PVE_TEMPLATE#*:}"
  template_file="${template_path#vztmpl/}"

  log "Checking template ${template_file} in ${PVE_STORAGE} via API"
  local response
  response=$(api_get "/nodes/${PVE_NODE}/storage/${PVE_STORAGE}/content?content=vztmpl")
  if ! echo "${response}" | jq -e --arg tpl "${PVE_TEMPLATE}" --arg file "${template_file}" '
      (.data // [])
      | map(select((.volid // "") == $tpl
                   or (.name // "") == $file
                   or ((.volid // "") | endswith($file))
                   or ((.name // "") | endswith($file))))
      | length > 0
    ' >/dev/null; then
    fail "Template ${template_file} not found in ${PVE_STORAGE}. Upload or download it first."
  fi
}

container_exists() {
  local response
  response=$(api_get "/nodes/${PVE_NODE}/lxc")
  echo "${response}" | jq -e --arg vmid "${GITEA_CTID}" '
    (.data // []) | map(select((.vmid | tostring) == $vmid)) | length > 0
  ' >/dev/null
}

create_container() {
  local net0
  if [[ "${GITEA_IP}" == "dhcp" ]]; then
    net0="name=eth0,bridge=${PVE_BRIDGE},ip=dhcp"
  else
    if [[ -z "${PVE_GATEWAY}" ]]; then
      fail "PVE_GATEWAY is required for static IP"
    fi
    net0="name=eth0,bridge=${PVE_BRIDGE},ip=${GITEA_IP},gw=${PVE_GATEWAY}"
  fi

  local args=(
    "vmid=${GITEA_CTID}"
    "hostname=${GITEA_HOSTNAME}"
    "cores=${GITEA_CORES}"
    "memory=${GITEA_MEMORY}"
    "swap=${PVE_SWAP}"
    "rootfs=${PVE_STORAGE}:${GITEA_DISK}"
    "ostemplate=${PVE_TEMPLATE}"
    "net0=${net0}"
    "features=${PVE_FEATURES}"
    "unprivileged=${PVE_UNPRIVILEGED}"
    "onboot=${PVE_ONBOOT}"
    "nameserver=${PVE_DNS}"
  )

  if [[ -n "${PVE_ROOT_PASSWORD}" ]]; then
    args+=("password=${PVE_ROOT_PASSWORD}")
  fi
  if [[ -n "${PVE_SSH_KEYS}" ]]; then
    args+=("ssh-public-keys=${PVE_SSH_KEYS}")
  fi

  log "Creating LXC ${GITEA_CTID} (${GITEA_HOSTNAME})"
  api_post "/nodes/${PVE_NODE}/lxc" "${args[@]}"
}

start_container() {
  log "Starting LXC ${GITEA_CTID}"
  api_post "/nodes/${PVE_NODE}/lxc/${GITEA_CTID}/status/start"
}

resolve_bootstrap_host() {
  if [[ -n "${BOOTSTRAP_SSH_HOST}" ]]; then
    return
  fi
  if [[ "${GITEA_IP}" != "dhcp" ]]; then
    BOOTSTRAP_SSH_HOST="${GITEA_IP%%/*}"
  fi
  if [[ -z "${BOOTSTRAP_SSH_HOST}" ]]; then
    fail "BOOTSTRAP_SSH_HOST is required when BOOTSTRAP_SSH=true and GITEA_IP=dhcp"
  fi
}

build_ssh_opts() {
  SSH_OPTS=(
    -p "${BOOTSTRAP_SSH_PORT}"
    -o BatchMode=yes
    -o ConnectTimeout="${BOOTSTRAP_SSH_CONNECT_TIMEOUT}"
  )
  if [[ -n "${BOOTSTRAP_SSH_KEY}" ]]; then
    SSH_OPTS+=(-i "${BOOTSTRAP_SSH_KEY}" -o IdentitiesOnly=yes)
  fi
  if [[ "${BOOTSTRAP_SSH_STRICT}" != "true" ]]; then
    SSH_OPTS+=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
  fi
}

wait_for_ssh() {
  local max_attempts=1
  if [[ "${BOOTSTRAP_SSH_WAIT_SECS}" =~ ^[0-9]+$ ]] && [[ "${BOOTSTRAP_SSH_SLEEP}" =~ ^[0-9]+$ ]]; then
    if (( BOOTSTRAP_SSH_SLEEP > 0 )); then
      max_attempts=$((BOOTSTRAP_SSH_WAIT_SECS / BOOTSTRAP_SSH_SLEEP))
      if (( max_attempts < 1 )); then
        max_attempts=1
      fi
    fi
  fi
  local attempt=1
  while (( attempt <= max_attempts )); do
    if ssh "${SSH_OPTS[@]}" "${BOOTSTRAP_SSH_USER}@${BOOTSTRAP_SSH_HOST}" "true" >/dev/null 2>&1; then
      return 0
    fi
    sleep "${BOOTSTRAP_SSH_SLEEP}"
    attempt=$((attempt + 1))
  done
  return 1
}

bootstrap_gitea() {
  if [[ "${BOOTSTRAP_SSH}" != "true" ]]; then
    return
  fi

  require_cmd ssh
  resolve_bootstrap_host
  build_ssh_opts

  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would bootstrap via SSH to ${BOOTSTRAP_SSH_USER}@${BOOTSTRAP_SSH_HOST}:${BOOTSTRAP_SSH_PORT}"
    return
  fi

  if ! wait_for_ssh; then
    fail "SSH not reachable at ${BOOTSTRAP_SSH_USER}@${BOOTSTRAP_SSH_HOST}:${BOOTSTRAP_SSH_PORT}"
  fi

  log "Bootstrapping Gitea via SSH to ${BOOTSTRAP_SSH_USER}@${BOOTSTRAP_SSH_HOST}:${BOOTSTRAP_SSH_PORT}"

  local root_url
  root_url=${GITEA_ROOT_URL:-"http://${GITEA_DOMAIN}:${GITEA_HTTP_PORT}/"}

  local env_assignments=(
    "GITEA_DOMAIN=$(printf %q "${GITEA_DOMAIN}")"
    "GITEA_ROOT_URL=$(printf %q "${root_url}")"
    "GITEA_HTTP_PORT=$(printf %q "${GITEA_HTTP_PORT}")"
    "GITEA_SSH_PORT=$(printf %q "${GITEA_SSH_PORT}")"
    "GITEA_VERSION=$(printf %q "${GITEA_VERSION}")"
    "GITEA_DATA_DIR=$(printf %q "${GITEA_DATA_DIR}")"
    "GITEA_DB_TYPE=$(printf %q "${GITEA_DB_TYPE}")"
    "GITEA_DB_HOST=$(printf %q "${GITEA_DB_HOST}")"
    "GITEA_DB_NAME=$(printf %q "${GITEA_DB_NAME}")"
    "GITEA_DB_USER=$(printf %q "${GITEA_DB_USER}")"
    "GITEA_DB_PASS=$(printf %q "${GITEA_DB_PASS}")"
  )

  # shellcheck disable=SC2029
  ssh "${SSH_OPTS[@]}" "${BOOTSTRAP_SSH_USER}@${BOOTSTRAP_SSH_HOST}" \
    "export ${env_assignments[*]}; bash -s" <<'REMOTE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release docker.io docker-compose-plugin
systemctl enable --now docker

install -d /opt/gitea
install -d "${GITEA_DATA_DIR}"

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
      - GITEA__server__ROOT_URL=${GITEA_ROOT_URL}
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
      - "${GITEA_HTTP_PORT}:3000"
      - "${GITEA_SSH_PORT}:22"
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
REMOTE
}

if [[ "${DRY_RUN}" == "true" ]]; then
  log "Dry run enabled. Writes will be skipped; read-only checks still run."
fi

check_template

if container_exists; then
  log "Container ${GITEA_CTID} already exists. Skipping create."
else
  create_container
  start_container
fi

bootstrap_gitea

if [[ "${BOOTSTRAP_SSH}" == "true" ]]; then
  log "Gitea bootstrap complete. URL: http://${GITEA_DOMAIN}:${GITEA_HTTP_PORT}"
else
  log "API provisioning finished. Run deploy-gitea-lxc.sh on the Proxmox host to configure Gitea inside the LXC."
fi
