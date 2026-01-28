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
CS_LOG_PREFIX="reboot-guard-status"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${SCRIPT_DIR}/reboot-guard.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

ENV_FILE=${ENV_FILE:-"/etc/reboot-guard.env"}
if [[ -f "${ENV_FILE}" ]]; then
  cs_load_env_file "${ENV_FILE}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}" || true
fi

SERVICE_NAME=${SERVICE_NAME:-"reboot-guard"}
RG_OVERRIDE_FILE=${RG_OVERRIDE_FILE:-"/run/reboot-guard/allow"}
RG_OVERRIDE_TTL=${RG_OVERRIDE_TTL:-"30"}
RG_WINDOW_START=${RG_WINDOW_START:-"02:00"}
RG_WINDOW_END=${RG_WINDOW_END:-"03:00"}
RG_WINDOW_DAYS=${RG_WINDOW_DAYS:-"Sun"}

service_state="unknown"
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
    service_state="active"
  else
    service_state="inactive"
  fi
fi

override_state="absent"
override_age="n/a"
override_left="n/a"
if [[ -f "${RG_OVERRIDE_FILE}" ]]; then
  override_state="present"
  if [[ "${RG_OVERRIDE_TTL}" =~ ^[0-9]+$ ]]; then
    now=$(date +%s)
    if ts=$(stat -c %Y "${RG_OVERRIDE_FILE}" 2>/dev/null); then
      :
    elif ts=$(stat -f %m "${RG_OVERRIDE_FILE}" 2>/dev/null); then
      :
    else
      ts=""
    fi
    if [[ -n "${ts}" ]]; then
      override_age=$(( (now - ts) / 60 ))
      if (( RG_OVERRIDE_TTL > 0 )); then
        if (( override_age <= RG_OVERRIDE_TTL )); then
          override_left=$(( RG_OVERRIDE_TTL - override_age ))
        else
          override_left=0
        fi
      fi
    fi
  fi
fi

cat <<EOF
reboot_guard_service=${service_state}
override_file=${RG_OVERRIDE_FILE}
override_state=${override_state}
override_age_minutes=${override_age}
override_minutes_left=${override_left}
window_days=${RG_WINDOW_DAYS}
window_start=${RG_WINDOW_START}
window_end=${RG_WINDOW_END}
EOF
