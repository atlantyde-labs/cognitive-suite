#!/usr/bin/env bash
set -euo pipefail
umask 077

LOG_PREFIX="[bootstrap]"

log() {
  echo "${LOG_PREFIX} $*"
}

fail() {
  echo "${LOG_PREFIX} ERROR: $*" >&2
  exit 1
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd)

CONFIG_PATH="${1:-}"
if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    fail "Config not found: ${CONFIG_PATH}"
  fi
  # shellcheck disable=SC1090
  source "${CONFIG_PATH}"
fi

REPO_DIR=${REPO_DIR:-"${ROOT_DIR}"}
SUITE_ENV=${SUITE_ENV:-"${REPO_DIR}/bash/GitDevSecDataAIOps/proxmox/deploy-all-secret-suite.env"}
COPY_EXAMPLES=${COPY_EXAMPLES:-"true"}
FIX_PERMS=${FIX_PERMS:-"true"}
CHECK_PLACEHOLDERS=${CHECK_PLACEHOLDERS:-"true"}
ALLOW_PLACEHOLDERS=${ALLOW_PLACEHOLDERS:-"false"}
ALLOW_EXTERNAL_CONFIRM=${ALLOW_EXTERNAL_CONFIRM:-""}
APPLY=${APPLY:-"false"}
CONFIRM_APPLY=${CONFIRM_APPLY:-""}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_cmd bash

copy_example() {
  local target=$1
  if [[ -f "${target}" ]]; then
    return 0
  fi
  if [[ "${COPY_EXAMPLES}" != "true" ]]; then
    return 1
  fi
  local example="${target}.example"
  if [[ -f "${example}" ]]; then
    install -m 0600 "${example}" "${target}"
    log "Created ${target} from ${example}"
    return 0
  fi
  return 1
}

ensure_env_file() {
  local target=$1
  if [[ -z "${target}" ]]; then
    return 0
  fi
  if [[ ! -f "${target}" ]]; then
    if ! copy_example "${target}"; then
      fail "Missing env file: ${target}"
    fi
  fi
  if [[ "${FIX_PERMS}" == "true" ]]; then
    chmod 600 "${target}" || true
  fi
}

get_env_value() {
  local env_file=$1
  local var=$2
  bash -c "set -a; source \"${env_file}\"; eval \"echo \\\"\${${var}:-}\\\"\"" 2>/dev/null
}

ensure_env_file "${SUITE_ENV}"

local_first=$(get_env_value "${SUITE_ENV}" LOCAL_FIRST)
allow_external=$(get_env_value "${SUITE_ENV}" ALLOW_EXTERNAL)
if [[ "${local_first}" == "true" && "${allow_external}" == "true" ]]; then
  if [[ "${ALLOW_EXTERNAL_CONFIRM}" != "YES" ]]; then
    fail "ALLOW_EXTERNAL=true while LOCAL_FIRST=true. Set ALLOW_EXTERNAL_CONFIRM=YES if intentional."
  fi
fi

env_keys=(
  GITEA_LXC_ENV
  GITEA_LXC_API_ENV
  HARDEN_ENV
  COMPLIANCE_LABELS_ENV
  REPO_TYPE_ENV
  SSO_MFA_ENV
  COMPLIANCE_REPORT_ENV
  GITHUB_ENV
  GITHUB_IMPORT_ENV
  GITLAB_ENV
  USER_MAP_VALIDATE_ENV
  SECRETS_ENV
  REBOOT_GUARD_ENV
)

for key in "${env_keys[@]}"; do
  path=$(get_env_value "${SUITE_ENV}" "${key}")
  if [[ -n "${path}" ]]; then
    ensure_env_file "${REPO_DIR}/${path}"
  fi
done

if [[ "${CHECK_PLACEHOLDERS}" == "true" ]]; then
  placeholder_regex='REPLACE_WITH|REDACTED|CHANGEME'
  missing=()
  if grep -Eq "${placeholder_regex}" "${SUITE_ENV}"; then
    missing+=("${SUITE_ENV}")
  fi
  for key in "${env_keys[@]}"; do
    path=$(get_env_value "${SUITE_ENV}" "${key}")
    if [[ -n "${path}" && -f "${REPO_DIR}/${path}" ]]; then
      if grep -Eq "${placeholder_regex}" "${REPO_DIR}/${path}"; then
        missing+=("${REPO_DIR}/${path}")
      fi
    fi
  done
  if [[ "${#missing[@]}" -gt 0 && "${ALLOW_PLACEHOLDERS}" != "true" && "${APPLY}" == "true" ]]; then
    printf '%s\n' "${missing[@]}" | awk '{print "[bootstrap] ERROR: Placeholder secrets found in " $0}' >&2
    fail "Refusing APPLY with placeholder values. Set ALLOW_PLACEHOLDERS=true to override."
  fi
fi

log "Running local lint checks"
scripts=()
if command -v rg >/dev/null 2>&1; then
  mapfile -t scripts < <(rg --files -g "*.sh" "${REPO_DIR}/bash/GitDevSecDataAIOps" "${REPO_DIR}/scripts" 2>/dev/null || true)
else
  mapfile -t scripts < <(find "${REPO_DIR}/bash/GitDevSecDataAIOps" "${REPO_DIR}/scripts" -type f -name "*.sh" 2>/dev/null || true)
fi

if [[ "${#scripts[@]}" -gt 0 ]]; then
  bash -n "${scripts[@]}"
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${scripts[@]}"
  else
    log "shellcheck not installed; skipping"
  fi
else
  log "No scripts found for linting"
fi

if command -v python3 >/dev/null 2>&1; then
  pyfiles=()
  if command -v rg >/dev/null 2>&1; then
    mapfile -t pyfiles < <(rg --files -g "*.py" "${REPO_DIR}/bash/GitDevSecDataAIOps" 2>/dev/null || true)
  else
    mapfile -t pyfiles < <(find "${REPO_DIR}/bash/GitDevSecDataAIOps" -type f -name "*.py" 2>/dev/null || true)
  fi
  if [[ "${#pyfiles[@]}" -gt 0 ]]; then
    python3 -m py_compile "${pyfiles[@]}"
  fi
fi

ORCHESTRATOR="${REPO_DIR}/bash/GitDevSecDataAIOps/proxmox/deploy-all-secret-suite.sh"
if [[ ! -f "${ORCHESTRATOR}" ]]; then
  fail "Orchestrator not found at ${ORCHESTRATOR}"
fi

if [[ "${APPLY}" == "true" ]]; then
  if [[ "${CONFIRM_APPLY}" != "YES" ]]; then
    fail "Set CONFIRM_APPLY=YES to apply changes."
  fi
  log "Applying suite with DRY_RUN=false"
  env DRY_RUN=false "${ORCHESTRATOR}" "${SUITE_ENV}"
else
  log "Running suite in dry-run mode"
  env DRY_RUN=true "${ORCHESTRATOR}" "${SUITE_ENV}"
fi
