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
CS_LOG_PREFIX="airgap-safe-ops"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

ROOT_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd)

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/proxmox/airgap-safe-ops.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

DRY_RUN=${DRY_RUN:-"false"}
if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

ENABLE_REBOOT_GUARD=${ENABLE_REBOOT_GUARD:-"false"}
REBOOT_GUARD_ENV=${REBOOT_GUARD_ENV:-""}
REBOOT_GUARD_STATUS=${REBOOT_GUARD_STATUS:-"false"}

PREPARE_AIRGAP=${PREPARE_AIRGAP:-"false"}
PREPARE_AIRGAP_ENV=${PREPARE_AIRGAP_ENV:-""}

APPLY_AIRGAP=${APPLY_AIRGAP:-"false"}
APPLY_AIRGAP_ENV=${APPLY_AIRGAP_ENV:-""}

PRE_PUBLISH_CHECKS=${PRE_PUBLISH_CHECKS:-"true"}
OPS_STATE_ENV=${OPS_STATE_ENV:-""}

SYNC_PUBLIC=${SYNC_PUBLIC:-"false"}
PUBLIC_SYNC_MODE=${PUBLIC_SYNC_MODE:-"git-push"} # git-push|gh-sync|command
PUBLIC_REPO_DIR=${PUBLIC_REPO_DIR:-""}
PUBLIC_REMOTE_URL=${PUBLIC_REMOTE_URL:-""}
PUBLIC_BRANCH=${PUBLIC_BRANCH:-"main"}
PUBLIC_SYNC_CMD=${PUBLIC_SYNC_CMD:-""}
ALLOW_EXTERNAL_CONFIRM=${ALLOW_EXTERNAL_CONFIRM:-""}

HITL_REQUIRED=${HITL_REQUIRED:-"true"}
HITL_APPROVE=${HITL_APPROVE:-""}

require_cmd() {
  cs_require_cmd "$1"
}

run_step() {
  local script=$1
  local env_file=$2
  local step=$3
  log "Step: ${step}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    if [[ -n "${env_file}" ]]; then
      env FORCE_DRY_RUN=true "${script}" "${env_file}"
    else
      env FORCE_DRY_RUN=true "${script}"
    fi
  else
    if [[ -n "${env_file}" ]]; then
      "${script}" "${env_file}"
    else
      "${script}"
    fi
  fi
}

if [[ "${HITL_REQUIRED}" == "true" && "${HITL_APPROVE}" != "YES" ]]; then
  fail "HITL_APPROVE=YES required"
fi

if [[ "${ENABLE_REBOOT_GUARD}" == "true" ]]; then
  if [[ -z "${REBOOT_GUARD_ENV}" ]]; then
    fail "REBOOT_GUARD_ENV is required"
  fi
  run_step "${ROOT_DIR}/bash/GitDevSecDataAIOps/platforms/ops-systems/install-reboot-guard.sh" "${REBOOT_GUARD_ENV}" "reboot_guard_install"
  if [[ "${REBOOT_GUARD_STATUS}" == "true" ]]; then
    run_step "${ROOT_DIR}/bash/GitDevSecDataAIOps/platforms/ops-systems/reboot-guard-status.sh" "${REBOOT_GUARD_ENV}" "reboot_guard_status"
  fi
fi

if [[ "${PREPARE_AIRGAP}" == "true" ]]; then
  if [[ -z "${PREPARE_AIRGAP_ENV}" ]]; then
    fail "PREPARE_AIRGAP_ENV is required"
  fi
  run_step "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/prepare-airgap-bundle.sh" "${PREPARE_AIRGAP_ENV}" "prepare_airgap_bundle"
fi

if [[ "${APPLY_AIRGAP}" == "true" ]]; then
  if [[ -z "${APPLY_AIRGAP_ENV}" ]]; then
    fail "APPLY_AIRGAP_ENV is required"
  fi
  run_step "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/started-kit-airgap.sh" "${APPLY_AIRGAP_ENV}" "apply_airgap_bundle"
fi

if [[ "${PRE_PUBLISH_CHECKS}" == "true" ]]; then
  if [[ -z "${OPS_STATE_ENV}" ]]; then
    fail "OPS_STATE_ENV is required"
  fi
  run_step "${ROOT_DIR}/bash/GitDevSecDataAIOps/tooling/ops-state/ops-state-machine.sh" "${OPS_STATE_ENV}" "pre_publish_ops_state"
fi

if [[ "${SYNC_PUBLIC}" == "true" ]]; then
  if [[ "${ALLOW_EXTERNAL_CONFIRM}" != "YES" ]]; then
    fail "ALLOW_EXTERNAL_CONFIRM=YES required for public sync"
  fi
  if [[ -z "${PUBLIC_REPO_DIR}" || ! -d "${PUBLIC_REPO_DIR}/.git" ]]; then
    fail "PUBLIC_REPO_DIR must be a git repo"
  fi
  case "${PUBLIC_SYNC_MODE}" in
    git-push)
      if [[ -z "${PUBLIC_REMOTE_URL}" ]]; then
        fail "PUBLIC_REMOTE_URL is required for git-push"
      fi
      if [[ "${DRY_RUN}" == "true" ]]; then
        log "[dry-run] git -C ${PUBLIC_REPO_DIR} remote add public ${PUBLIC_REMOTE_URL} (if missing)"
        log "[dry-run] git -C ${PUBLIC_REPO_DIR} push public ${PUBLIC_BRANCH}"
      else
        if ! git -C "${PUBLIC_REPO_DIR}" remote get-url public >/dev/null 2>&1; then
          git -C "${PUBLIC_REPO_DIR}" remote add public "${PUBLIC_REMOTE_URL}"
        fi
        git -C "${PUBLIC_REPO_DIR}" push public "${PUBLIC_BRANCH}"
      fi
      ;;
    gh-sync)
      require_cmd gh
      if [[ -z "${PUBLIC_REMOTE_URL}" ]]; then
        fail "PUBLIC_REMOTE_URL (org/repo) required for gh-sync"
      fi
      if [[ "${DRY_RUN}" == "true" ]]; then
        log "[dry-run] gh repo sync ${PUBLIC_REMOTE_URL} -b ${PUBLIC_BRANCH}"
      else
        gh repo sync "${PUBLIC_REMOTE_URL}" -b "${PUBLIC_BRANCH}"
      fi
      ;;
    command)
      if [[ -z "${PUBLIC_SYNC_CMD}" ]]; then
        fail "PUBLIC_SYNC_CMD is required for command mode"
      fi
      if [[ "${DRY_RUN}" == "true" ]]; then
        log "[dry-run] ${PUBLIC_SYNC_CMD}"
      else
        bash -c "${PUBLIC_SYNC_CMD}"
      fi
      ;;
    *)
      fail "Unsupported PUBLIC_SYNC_MODE: ${PUBLIC_SYNC_MODE}"
      ;;
  esac
fi

log "All requested steps completed."
