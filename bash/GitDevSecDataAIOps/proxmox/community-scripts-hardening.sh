#!/usr/bin/env bash
set -euo pipefail
umask 077

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
CS_LOG_PREFIX="community-scripts-hardening"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/proxmox/community-scripts-hardening.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

DRY_RUN=${DRY_RUN:-"true"}
INTERACTIVE=${INTERACTIVE:-"true"}

DIAGNOSTICS_OPT_OUT=${DIAGNOSTICS_OPT_OUT:-"true"}
DIAGNOSTICS_FILE=${DIAGNOSTICS_FILE:-"/usr/local/community-scripts/diagnostics"}
DIAGNOSTICS_VALUE=${DIAGNOSTICS_VALUE:-"no"}

BLOCK_API_HOST=${BLOCK_API_HOST:-"false"}
BLOCK_MODE=${BLOCK_MODE:-"hosts"}
API_HOST=${API_HOST:-"api.community-scripts.org"}
BLOCK_IPV4=${BLOCK_IPV4:-"0.0.0.0"}
BLOCK_IPV6=${BLOCK_IPV6:-"::"}
HOSTS_FILE=${HOSTS_FILE:-"/etc/hosts"}

MIRROR_REPO=${MIRROR_REPO:-"false"}
MIRROR_URL=${MIRROR_URL:-"https://git.community-scripts.org/community-scripts/ProxmoxVE.git"}
MIRROR_BRANCH=${MIRROR_BRANCH:-"main"}
MIRROR_DIR=${MIRROR_DIR:-"/opt/community-scripts/mirror"}
ALLOW_EXTERNAL_CONFIRM=${ALLOW_EXTERNAL_CONFIRM:-""}

EVIDENCE_DIR=${EVIDENCE_DIR:-""}

require_root_if_apply() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    return 0
  fi
  if [[ "$(id -u)" -ne 0 ]]; then
    fail "Run as root (sudo) when DRY_RUN=false"
  fi
}

json_escape() {
  local value="$1"
  printf '%s' "${value}" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_evidence() {
  if [[ -z "${EVIDENCE_DIR}" ]]; then
    return 0
  fi
  mkdir -p "${EVIDENCE_DIR}"
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local diag_sha=""
  if [[ -f "${DIAGNOSTICS_FILE}" ]]; then
    if command -v sha256sum >/dev/null 2>&1; then
      diag_sha=$(sha256sum "${DIAGNOSTICS_FILE}" | awk '{print $1}')
    fi
  fi
  local record
  record=$(printf '{"timestamp":"%s","dry_run":%s,"diagnostics_opt_out":%s,"diagnostics_file":"%s","diagnostics_value":"%s","diagnostics_sha256":"%s","block_api_host":%s,"block_mode":"%s","api_host":"%s","mirror_repo":%s,"mirror_dir":"%s"}' \
    "${timestamp}" \
    "${DRY_RUN}" \
    "${DIAGNOSTICS_OPT_OUT}" \
    "$(json_escape "${DIAGNOSTICS_FILE}")" \
    "$(json_escape "${DIAGNOSTICS_VALUE}")" \
    "$(json_escape "${diag_sha}")" \
    "${BLOCK_API_HOST}" \
    "$(json_escape "${BLOCK_MODE}")" \
    "$(json_escape "${API_HOST}")" \
    "${MIRROR_REPO}" \
    "$(json_escape "${MIRROR_DIR}")")
  printf '%s\n' "${record}" >> "${EVIDENCE_DIR}/community-scripts-hardening.jsonl"
}

opt_out_diagnostics() {
  local target_dir
  target_dir=$(dirname "${DIAGNOSTICS_FILE}")
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would write ${DIAGNOSTICS_FILE} (DIAGNOSTICS=${DIAGNOSTICS_VALUE})"
    return 0
  fi
  install -d -m 700 "${target_dir}"
  printf 'DIAGNOSTICS="%s"\n' "${DIAGNOSTICS_VALUE}" > "${DIAGNOSTICS_FILE}"
  chmod 600 "${DIAGNOSTICS_FILE}"
  log "Diagnostics opt-out written to ${DIAGNOSTICS_FILE}"
}

block_api_host() {
  if [[ "${BLOCK_MODE}" != "hosts" ]]; then
    log "Blocking disabled (BLOCK_MODE=${BLOCK_MODE})"
    return 0
  fi
  local line_v4="${BLOCK_IPV4} ${API_HOST} # community-scripts-block"
  local line_v6="${BLOCK_IPV6} ${API_HOST} # community-scripts-block"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would ensure ${API_HOST} blocked in ${HOSTS_FILE}"
    log "[dry-run] ${line_v4}"
    log "[dry-run] ${line_v6}"
    return 0
  fi
  if grep -q "${API_HOST}" "${HOSTS_FILE}"; then
    log "${API_HOST} already present in ${HOSTS_FILE}"
    return 0
  fi
  printf '%s\n' "${line_v4}" >> "${HOSTS_FILE}"
  printf '%s\n' "${line_v6}" >> "${HOSTS_FILE}"
  log "Blocked ${API_HOST} via ${HOSTS_FILE}"
}

mirror_repo() {
  if [[ "${MIRROR_REPO}" != "true" ]]; then
    return 0
  fi
  if [[ "${DRY_RUN}" != "true" && "${ALLOW_EXTERNAL_CONFIRM}" != "YES" ]]; then
    fail "ALLOW_EXTERNAL_CONFIRM=YES required for mirror operations"
  fi
  cs_require_cmd git
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would mirror ${MIRROR_URL} (${MIRROR_BRANCH}) to ${MIRROR_DIR}"
    return 0
  fi
  if [[ -d "${MIRROR_DIR}/.git" ]]; then
    log "Updating mirror at ${MIRROR_DIR}"
    git -C "${MIRROR_DIR}" fetch --depth=1 origin "${MIRROR_BRANCH}"
    git -C "${MIRROR_DIR}" checkout "${MIRROR_BRANCH}"
    git -C "${MIRROR_DIR}" pull --ff-only origin "${MIRROR_BRANCH}"
  else
    log "Cloning mirror to ${MIRROR_DIR}"
    git clone --depth=1 --branch "${MIRROR_BRANCH}" "${MIRROR_URL}" "${MIRROR_DIR}"
  fi
}

main() {
  cs_check_pve_version false || true

  if [[ "${INTERACTIVE}" == "true" ]]; then
    cs_ui_header "Community-scripts Hardening"
    cs_ui_note "DRY_RUN=${DRY_RUN}"
    cs_ui_note "Diagnostics opt-out: ${DIAGNOSTICS_OPT_OUT}"
    cs_ui_note "Block API host: ${BLOCK_API_HOST} (${BLOCK_MODE})"
    cs_ui_note "Mirror repo: ${MIRROR_REPO}"
    if [[ "${DRY_RUN}" != "true" ]]; then
      if ! cs_ui_confirm "Apply changes now?" "N"; then
        fail "Cancelled by operator"
      fi
    fi
  fi

  require_root_if_apply

  if [[ "${DIAGNOSTICS_OPT_OUT}" == "true" ]]; then
    cs_ui_step "Opt-out diagnostics"
    opt_out_diagnostics
    cs_ui_ok "Diagnostics opt-out handled"
  fi

  if [[ "${BLOCK_API_HOST}" == "true" ]]; then
    cs_ui_step "Block API host"
    block_api_host
    cs_ui_ok "API host blocking handled"
  fi

  if [[ "${MIRROR_REPO}" == "true" ]]; then
    cs_ui_step "Mirror repository"
    mirror_repo
    cs_ui_ok "Mirror step handled"
  fi

  write_evidence
  cs_ui_ok "Completed"
}

main "$@"
