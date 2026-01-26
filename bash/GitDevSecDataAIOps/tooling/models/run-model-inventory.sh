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
HASH_MODE=${HASH_MODE:-"none"}
DEFAULT_SENSITIVITY=${DEFAULT_SENSITIVITY:-"INTERNAL"}

python3 "$(dirname "$0")/model_inventory.py" \
  --roots "${ROOTS}" \
  --output "${OUTPUT_PATH}" \
  --hash "${HASH_MODE}" \
  --default-sensitivity "${DEFAULT_SENSITIVITY}"
