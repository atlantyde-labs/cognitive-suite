#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CS_ROOT=$(git rev-parse --show-toplevel)
SCRIPTS_DIR="${CS_ROOT}/scripts"
PLAN_DEFAULT="${SCRIPTS_DIR}/repo-visibility-plan.json"
NOTES_DEFAULT="${CS_ROOT}/docs/internal/workshop-notes.md"
OUTPUT_DEFAULT="${CS_ROOT}/outputs/workshop-digests"

CONFIG_PATH="${PLAN_DEFAULT}"
NOTES_FILE="${NOTES_DEFAULT}"
OUTPUT_DIR="${OUTPUT_DEFAULT}"
DRY_RUN="true"
OPEN_NOTEBOOK_API_URL="${OPEN_NOTEBOOK_API_URL:-}"
OPEN_NOTEBOOK_NOTEBOOK_ID="${OPEN_NOTEBOOK_NOTEBOOK_ID:-}"
OPEN_NOTEBOOK_API_KEY="${OPEN_NOTEBOOK_API_KEY:-}"

usage() {
  cat <<'EOF'
Usage: workshop-learning-workflow.sh [options]

Options:
  --config <path>                     Plan de visibilidad (JSON)
  --run                               Ejecutar con push (por defecto es dry-run)
  --dry-run                           Mantener dry-run
  --notes <path>                      Archivo compartido de notas cognitivas/emocionales
  --output <dir>                      Carpeta para los digests generados
  --open-notebook-api-url <url>       URL del API Open Notebook
  --open-notebook-notebook-id <id>    Notebook destino en Open Notebook
  --open-notebook-api-key <key>       Clave para Open Notebook (opcional)
  -h, --help                          Mostrar esta ayuda
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG_PATH="$2"
      shift 2
      ;;
    --run)
      DRY_RUN="false"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --notes)
      NOTES_FILE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --open-notebook-api-url)
      OPEN_NOTEBOOK_API_URL="$2"
      shift 2
      ;;
    --open-notebook-notebook-id)
      OPEN_NOTEBOOK_NOTEBOOK_ID="$2"
      shift 2
      ;;
    --open-notebook-api-key)
      OPEN_NOTEBOOK_API_KEY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argumento desconocido: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "Config JSON no encontrado: ${CONFIG_PATH}" >&2
  exit 1
fi

echo "Ejecutando repo-visibility-splitter (${DRY_RUN} mode)..."
if [[ "${DRY_RUN}" == "true" ]]; then
  bash "${SCRIPTS_DIR}/repo-visibility-splitter.sh" --config "${CONFIG_PATH}"
else
  bash "${SCRIPTS_DIR}/repo-visibility-splitter.sh" --config "${CONFIG_PATH}" --run
fi

PY_ARGS=(
  --config "${CONFIG_PATH}"
  --output-dir "${OUTPUT_DIR}"
  --notes-file "${NOTES_FILE}"
)

if [[ "${DRY_RUN}" == "true" ]]; then
  PY_ARGS+=(--dry-run)
fi

if [[ -n "${OPEN_NOTEBOOK_API_URL}" ]]; then
  PY_ARGS+=(--open-notebook-api-url "${OPEN_NOTEBOOK_API_URL}")
fi
if [[ -n "${OPEN_NOTEBOOK_NOTEBOOK_ID}" ]]; then
  PY_ARGS+=(--open-notebook-notebook-id "${OPEN_NOTEBOOK_NOTEBOOK_ID}")
fi
if [[ -n "${OPEN_NOTEBOOK_API_KEY}" ]]; then
  PY_ARGS+=(--open-notebook-api-key "${OPEN_NOTEBOOK_API_KEY}")
fi

python3 "${SCRIPTS_DIR}/workshop-learning-digest.py" "${PY_ARGS[@]}"
