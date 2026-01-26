#!/usr/bin/env bash
set -euo pipefail
umask 077

LOG_PREFIX="[started-kit]"

log() {
  echo "${LOG_PREFIX} $*"
}

fail() {
  echo "${LOG_PREFIX} ERROR: $*" >&2
  exit 1
}

CONFIG_PATH="${1:-}"
if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    fail "Config not found: ${CONFIG_PATH}"
  fi
  # shellcheck disable=SC1090
  source "${CONFIG_PATH}"
fi

REPO_URL=${REPO_URL:-"https://github.com/atlantyde-labs/cognitive-suite.git"}
BRANCH=${BRANCH:-"chore/scripts-testing"}
DEST_DIR=${DEST_DIR:-"${HOME}/cognitive-suite"}
USE_GH=${USE_GH:-"true"}
RUN_BOOTSTRAP=${RUN_BOOTSTRAP:-"true"}
BOOTSTRAP_ENV=${BOOTSTRAP_ENV:-"${DEST_DIR}/bash/GitDevSecDataAIOps/proxmox/bootstrap.env"}
BOOTSTRAP_PATH=${BOOTSTRAP_PATH:-"${DEST_DIR}/bash/GitDevSecDataAIOps/proxmox/bootstrap.sh"}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_cmd git
require_cmd bash

if [[ "${USE_GH}" == "true" ]]; then
  require_cmd gh
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
