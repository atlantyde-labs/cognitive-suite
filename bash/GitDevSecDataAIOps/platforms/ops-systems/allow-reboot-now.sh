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
RG_OVERRIDE_TTL=${RG_OVERRIDE_TTL:-"30"}
DRY_RUN=${DRY_RUN:-"false"}
if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

if [[ -z "${RG_OVERRIDE_TTL}" || "${RG_OVERRIDE_TTL}" == "0" ]]; then
  echo "RG_OVERRIDE_TTL must be > 0 to allow override." >&2
  exit 1
fi

dir=$(dirname "${RG_OVERRIDE_FILE}")
if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[dry-run] would create ${RG_OVERRIDE_FILE} (TTL ${RG_OVERRIDE_TTL} minutes)"
  exit 0
fi

install -d -m 0755 "${dir}"
touch "${RG_OVERRIDE_FILE}"
echo "Override active for ${RG_OVERRIDE_TTL} minutes via ${RG_OVERRIDE_FILE}"
