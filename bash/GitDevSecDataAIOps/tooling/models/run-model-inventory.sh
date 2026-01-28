#!/usr/bin/env bash
set -euo pipefail

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
CS_LOG_PREFIX="model-inventory"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/tooling/models/model-inventory.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

ROOTS=${ROOTS:-"."}
OUTPUT_PATH=${OUTPUT_PATH:-"outputs/model-inventory.json"}
WHITELIST_PATH=${WHITELIST_PATH:-"outputs/model-whitelist.json"}
ALERTS_PATH=${ALERTS_PATH:-"outputs/model-alerts.json"}
HASH_MODE=${HASH_MODE:-"none"}
DEFAULT_SENSITIVITY=${DEFAULT_SENSITIVITY:-"INTERNAL"}
ALLOWED_SECRET_ROOTS=${ALLOWED_SECRET_ROOTS:-""}
QUARANTINE_MODE=${QUARANTINE_MODE:-"none"}
VAULT_DIR=${VAULT_DIR:-""}
DRY_RUN=${DRY_RUN:-"false"}
FAIL_ON_VIOLATION=${FAIL_ON_VIOLATION:-"false"}
PRESERVE_PATHS=${PRESERVE_PATHS:-"false"}

args=(
  "${SCRIPT_DIR}/model_inventory.py"
  --roots "${ROOTS}"
  --output "${OUTPUT_PATH}"
  --whitelist-output "${WHITELIST_PATH}"
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
if [[ "${PRESERVE_PATHS}" == "true" ]]; then
  args+=(--preserve-paths)
fi
if [[ "${FAIL_ON_VIOLATION}" == "true" ]]; then
  args+=(--fail-on-violation)
fi

python3 "${args[@]}"
