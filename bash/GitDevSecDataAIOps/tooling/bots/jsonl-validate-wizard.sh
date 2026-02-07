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
CS_LOG_PREFIX="jsonl-validate"

ROOT_DIR=$(cd "${SCRIPT_DIR}/../../../../" && pwd)
VALIDATOR="${ROOT_DIR}/bash/GitDevSecDataAIOps/tooling/forensics/validate-jsonl.py"

INPUT_PATH=${INPUT_PATH:-""}
SCHEMA_PATH=${SCHEMA_PATH:-""}
AUTO_SCHEMA=${AUTO_SCHEMA:-"true"}
OUTPUT_FILE=${OUTPUT_FILE:-"${ROOT_DIR}/outputs/ci-evidence/jsonl-validate-summary.json"}
INTERACTIVE=${INTERACTIVE:-"true"}

if [[ "${INTERACTIVE}" == "true" ]]; then
  if [[ ! -t 0 ]]; then
    cs_die "INTERACTIVE=true requires a TTY"
  fi
  cs_ui_header "JSONL Validation Wizard"
  INPUT_PATH=$(cs_ui_prompt "Input path (file or dir)" "${INPUT_PATH:-.}")
  SCHEMA_PATH=$(cs_ui_prompt "Schema path (blank for auto)" "${SCHEMA_PATH}")
  AUTO_SCHEMA=$(cs_ui_prompt "AUTO_SCHEMA (true|false)" "${AUTO_SCHEMA}")
  OUTPUT_FILE=$(cs_ui_prompt "Output summary file" "${OUTPUT_FILE}")
fi

cs_require_cmd python3

if [[ ! -f "${VALIDATOR}" ]]; then
  cs_die "Validator not found: ${VALIDATOR}"
fi

if [[ -z "${INPUT_PATH}" ]]; then
  cs_die "INPUT_PATH is required"
fi

if [[ -d "${INPUT_PATH}" ]]; then
  mapfile -t files < <(find "${INPUT_PATH}" -type f -name "*.jsonl" | sort)
elif [[ -f "${INPUT_PATH}" ]]; then
  files=("${INPUT_PATH}")
else
  cs_die "Input not found: ${INPUT_PATH}"
fi

if [[ "${#files[@]}" -eq 0 ]]; then
  cs_die "No .jsonl files found in ${INPUT_PATH}"
fi

detect_schema() {
  local file=$1
  local base
  base=$(basename "${file}")

  if [[ -n "${SCHEMA_PATH}" ]]; then
    echo "${SCHEMA_PATH}"
    return
  fi

  if [[ "${AUTO_SCHEMA}" != "true" ]]; then
    echo ""
    return
  fi

  if [[ "${base}" == *"bot-"* || "${base}" == *"bot_"* || "${base}" == *"github-apps"* || "${base}" == *"gitea-bot"* ]]; then
    echo "${ROOT_DIR}/schemas/bot-clickops.schema.json"
    return
  fi

  if [[ "${base}" == *"github-migration"* || "${base}" == *"migration-clickops"* || "${base}" == *"clickops"* ]]; then
    echo "${ROOT_DIR}/schemas/github-migration-clickops.schema.json"
    return
  fi

  echo ""
}

cs_ui_step "Validating JSONL files"
results=()
fail_count=0
for file in "${files[@]}"; do
  schema=$(detect_schema "${file}")
  if [[ -z "${schema}" ]]; then
    cs_ui_note "No schema for ${file}"
    results+=("{\"file\":\"${file}\",\"schema\":\"\",\"status\":\"skipped\"}")
    continue
  fi
  if [[ ! -f "${schema}" ]]; then
    cs_ui_note "Schema not found: ${schema}"
    results+=("{\"file\":\"${file}\",\"schema\":\"${schema}\",\"status\":\"fail\"}")
    fail_count=$((fail_count + 1))
    continue
  fi
  if python3 "${VALIDATOR}" --schema "${schema}" --input "${file}" >/tmp/jsonl-validate.log 2>&1; then
    cs_ui_ok "OK: ${file}"
    results+=("{\"file\":\"${file}\",\"schema\":\"${schema}\",\"status\":\"pass\"}")
  else
    cs_ui_note "FAIL: ${file}"
    results+=("{\"file\":\"${file}\",\"schema\":\"${schema}\",\"status\":\"fail\"}")
    fail_count=$((fail_count + 1))
    cat /tmp/jsonl-validate.log >&2 || true
  fi
done

if [[ -n "${OUTPUT_FILE}" ]]; then
  mkdir -p "$(dirname "${OUTPUT_FILE}")"
  RESULTS_LINES=$(printf '%s\n' "${results[@]}") OUTPUT_FILE="${OUTPUT_FILE}" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone

lines = [line.strip() for line in os.environ.get("RESULTS_LINES", "").splitlines() if line.strip()]
records = [json.loads(line) for line in lines]
payload = {
    "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "results": records,
}
with open(os.environ["OUTPUT_FILE"], "w", encoding="utf-8") as fh:
    fh.write(json.dumps(payload, ensure_ascii=True, indent=2))
PY
  cs_ui_ok "Summary written: ${OUTPUT_FILE}"
fi

if [[ "${fail_count}" -gt 0 ]]; then
  cs_die "Validation failed (${fail_count} files)"
fi

cs_ui_ok "All JSONL files validated"
