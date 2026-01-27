#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CS_LIB_FALLBACK="/usr/local/lib/cognitive-suite/cs-common.sh"
if [[ -f "${CS_LIB_FALLBACK}" ]]; then
  # shellcheck disable=SC1090,SC1091
  source "${CS_LIB_FALLBACK}"
else
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
fi

# shellcheck disable=SC2034
CS_LOG_PREFIX="reboot-guard-close"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${SCRIPT_DIR}/reboot-guard.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

ENV_FILE=${ENV_FILE:-"/etc/reboot-guard.env"}
if [[ -f "${ENV_FILE}" ]]; then
  cs_load_env_file "${ENV_FILE}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}" || true
fi

RG_OVERRIDE_FILE=${RG_OVERRIDE_FILE:-"/run/reboot-guard/allow"}
RG_AUDIT_LOG=${RG_AUDIT_LOG:-"/var/log/reboot-guard-audit.log"}
DRY_RUN=${DRY_RUN:-"false"}
if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

audit_log() {
  local action=$1
  local ts user host
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  user=$(id -un 2>/dev/null || echo "unknown")
  host=$(hostname -f 2>/dev/null || hostname)
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] audit ${ts} user=${user} host=${host} action=${action}"
    return
  fi
  install -d -m 0755 "$(dirname "${RG_AUDIT_LOG}")"
  printf '%s user=%s host=%s action=%s\n' "${ts}" "${user}" "${host}" "${action}" >> "${RG_AUDIT_LOG}"
}

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[dry-run] would remove ${RG_OVERRIDE_FILE}"
  audit_log "override-close"
  exit 0
fi

if [[ -f "${RG_OVERRIDE_FILE}" ]]; then
  rm -f "${RG_OVERRIDE_FILE}"
  audit_log "override-close"
  echo "Override closed: ${RG_OVERRIDE_FILE}"
else
  audit_log "override-close-missing"
  echo "Override file not found: ${RG_OVERRIDE_FILE}"
fi
