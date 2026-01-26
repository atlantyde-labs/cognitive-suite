#!/usr/bin/env bash
set -euo pipefail

LOG_PREFIX="[deploy-gitea-api]"

log() {
  echo "${LOG_PREFIX} $*"
}

fail() {
  echo "${LOG_PREFIX} ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_PATH="${1:-}"
if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    fail "Config not found: ${CONFIG_PATH}"
  fi
  # shellcheck disable=SC1090
  source "${CONFIG_PATH}"
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

GITEA_CTID=${GITEA_CTID:-"9100"}
GITEA_HOSTNAME=${GITEA_HOSTNAME:-"gitea"}
GITEA_MEMORY=${GITEA_MEMORY:-"4096"}
GITEA_CORES=${GITEA_CORES:-"2"}
GITEA_DISK=${GITEA_DISK:-"40"}
GITEA_IP=${GITEA_IP:-"dhcp"}

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
    bash "${API_CLIENT}" "${CONFIG_PATH}" "${method}" "${path}" "$@"
  else
    bash "${API_CLIENT}" "" "${method}" "${path}" "$@"
  fi
}

api_get() {
  local path=$1
  shift || true
  DRY_RUN="false" api_call GET "${path}" "$@"
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

log "API provisioning finished. Run deploy-gitea-lxc.sh on the Proxmox host to configure Gitea inside the LXC."
