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
CS_LOG_PREFIX="started-kit"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/proxmox/started-kit-deployments-cli-ops.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

REPO_URL=${REPO_URL:-"https://github.com/atlantyde-labs/cognitive-suite.git"}
BRANCH=${BRANCH:-"chore/scripts-testing"}
DEST_DIR=${DEST_DIR:-"${HOME}/cognitive-suite"}
USE_GH=${USE_GH:-"true"}
RUN_BOOTSTRAP=${RUN_BOOTSTRAP:-"true"}
BOOTSTRAP_ENV=${BOOTSTRAP_ENV:-"${DEST_DIR}/bash/GitDevSecDataAIOps/proxmox/bootstrap.env"}
BOOTSTRAP_PATH=${BOOTSTRAP_PATH:-"${DEST_DIR}/bash/GitDevSecDataAIOps/proxmox/bootstrap.sh"}

cs_require_cmd git
cs_require_cmd bash

if [[ "${USE_GH}" == "true" ]]; then
  cs_require_cmd gh
fi

clone_repo() {
  log "Cloning ${REPO_URL} into ${DEST_DIR}"
  if [[ "${USE_GH}" == "true" ]]; then
    gh repo clone "${REPO_URL}" "${DEST_DIR}"
  else
    git clone "${REPO_URL}" "${DEST_DIR}"
  fi
}

update_repo() {
  log "Fetching latest from origin"
  git -C "${DEST_DIR}" fetch origin
  if git -C "${DEST_DIR}" rev-parse --verify "${BRANCH}" >/dev/null 2>&1; then
    git -C "${DEST_DIR}" checkout "${BRANCH}"
  else
    git -C "${DEST_DIR}" checkout -b "${BRANCH}" "origin/${BRANCH}"
  fi
  git -C "${DEST_DIR}" pull --ff-only origin "${BRANCH}"
}

ensure_bootstrap_env() {
  if [[ -f "${BOOTSTRAP_ENV}" ]]; then
    return
  fi
  local example="${BOOTSTRAP_ENV}.example"
  if [[ -f "${example}" ]]; then
    install -m 0600 "${example}" "${BOOTSTRAP_ENV}"
    log "Created ${BOOTSTRAP_ENV} from ${example}"
  fi
}

if [[ -d "${DEST_DIR}/.git" ]]; then
  update_repo
else
  clone_repo
  update_repo
fi

if [[ "${RUN_BOOTSTRAP}" == "true" ]]; then
  if [[ ! -x "${BOOTSTRAP_PATH}" ]]; then
    fail "Bootstrap not found at ${BOOTSTRAP_PATH}"
  fi
  ensure_bootstrap_env
  if [[ -f "${BOOTSTRAP_ENV}" ]]; then
    log "Running bootstrap with ${BOOTSTRAP_ENV}"
    bash "${BOOTSTRAP_PATH}" "${BOOTSTRAP_ENV}"
  else
    log "Running bootstrap without config (using defaults)"
    bash "${BOOTSTRAP_PATH}"
  fi
else
  log "Bootstrap disabled (RUN_BOOTSTRAP=false)"
fi
