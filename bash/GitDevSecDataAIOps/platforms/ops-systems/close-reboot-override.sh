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

ENV_FILE=${ENV_FILE:-"/etc/reboot-guard.env"}
if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
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
