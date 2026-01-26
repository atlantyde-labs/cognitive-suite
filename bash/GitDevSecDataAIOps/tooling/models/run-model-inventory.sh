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

ROOTS=${ROOTS:-"."}
OUTPUT_PATH=${OUTPUT_PATH:-"outputs/model-inventory.json"}
ALERTS_PATH=${ALERTS_PATH:-"outputs/model-alerts.json"}
HASH_MODE=${HASH_MODE:-"none"}
DEFAULT_SENSITIVITY=${DEFAULT_SENSITIVITY:-"INTERNAL"}
ALLOWED_SECRET_ROOTS=${ALLOWED_SECRET_ROOTS:-""}
QUARANTINE_MODE=${QUARANTINE_MODE:-"none"}
VAULT_DIR=${VAULT_DIR:-""}
DRY_RUN=${DRY_RUN:-"false"}
FAIL_ON_VIOLATION=${FAIL_ON_VIOLATION:-"false"}

args=(
  "$(dirname "$0")/model_inventory.py"
  --roots "${ROOTS}"
  --output "${OUTPUT_PATH}"
  --hash "${HASH_MODE}"
  --default-sensitivity "${DEFAULT_SENSITIVITY}"
  --alerts-output "${ALERTS_PATH}"
)

if [[ -n "${ALLOWED_SECRET_ROOTS}" ]]; then
  args+=(--allowed-secret-roots "${ALLOWED_SECRET_ROOTS}")
fi
if [[ -n "${VAULT_DIR}" ]]; then
  args+=(--vault-dir "${VAULT_DIR}")
fi
if [[ "${QUARANTINE_MODE}" != "none" ]]; then
  args+=(--quarantine-mode "${QUARANTINE_MODE}")
fi
if [[ "${DRY_RUN}" == "true" ]]; then
  args+=(--dry-run)
fi
if [[ "${FAIL_ON_VIOLATION}" == "true" ]]; then
  args+=(--fail-on-violation)
fi

python3 "${args[@]}"
