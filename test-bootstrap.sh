#!/bin/bash
set -euo pipefail

echo "🔍 Iniciando prueba local de Cognitive GitOps Suite..."

# Preparar estructura
mkdir -p data/input outputs/raw outputs/insights outputs/audit schemas qdrant_storage

RESULT_FILE="outputs/insights/analysis.json"
rm -f "$RESULT_FILE"

# Copiar input de prueba
echo '{ "content": "El proyecto de microK8s europeo promueve la soberanía digital. Riesgos regulatorios pueden incluir el incumplimiento del RGPD. Ideas innovadoras incluyen orquestación distribuida con GitOps legalmente trazable." }' > data/input/demo_input.json

# Cargar secretos/variables desde un archivo opcional.
if [ -n "${BOOTSTRAP_ENV_FILE:-}" ]; then
  if [ ! -f "$BOOTSTRAP_ENV_FILE" ]; then
    echo "❌ BOOTSTRAP_ENV_FILE no encontrado: $BOOTSTRAP_ENV_FILE"
    exit 1
  fi
  set -a
  # shellcheck disable=SC1090
  source "$BOOTSTRAP_ENV_FILE"
  set +a
fi

# Alinear UID/GID con el host para evitar errores de permisos en volúmenes.
export COGNITIVE_UID="${COGNITIVE_UID:-$(id -u)}"
export COGNITIVE_GID="${COGNITIVE_GID:-$(id -g)}"

# Forzar redacción si se solicita (no imprime el secreto).
if [ "${BOOTSTRAP_REDACT:-0}" = "1" ]; then
  export COGNITIVE_ENV="${COGNITIVE_ENV:-prod}"
  export COGNITIVE_REDACT="${COGNITIVE_REDACT:-1}"
  export COGNITIVE_AUDIT_LOG="${COGNITIVE_AUDIT_LOG:-/data/outputs/audit/analysis.jsonl}"
  if [ -z "${COGNITIVE_HASH_SALT:-}" ]; then
    if [ "${BOOTSTRAP_GENERATE_SALT:-0}" = "1" ]; then
      COGNITIVE_HASH_SALT="$(python3 - <<'PY'
import secrets
print(secrets.token_hex(16))
PY
)"
      export COGNITIVE_HASH_SALT
    else
      echo "❌ COGNITIVE_HASH_SALT debe estar definido para redacción."
      exit 1
    fi
  fi
  echo "🔒 Redacción habilitada (COGNITIVE_ENV=$COGNITIVE_ENV, COGNITIVE_REDACT=$COGNITIVE_REDACT, COGNITIVE_HASH_SALT=***)"
fi

if [ "${BOOTSTRAP_DEBUG:-0}" = "1" ]; then
  export COGNITIVE_VERBOSE="${COGNITIVE_VERBOSE:-1}"
fi

# Iniciar contenedores
COMPOSE_FILE="${BOOTSTRAP_COMPOSE_FILE:-docker-compose.yml}"
docker compose -f "$COMPOSE_FILE" up -d --build

LOG_PID=""
if [ "${BOOTSTRAP_DEBUG:-0}" = "1" ]; then
  echo "🧪 Debug habilitado: mostrando logs de ingestor y pipeline."
  docker compose -f "$COMPOSE_FILE" logs -f --no-color --timestamps ingestor pipeline &
  LOG_PID=$!
fi

cleanup_logs() {
  if [ -n "$LOG_PID" ] && kill -0 "$LOG_PID" 2>/dev/null; then
    kill "$LOG_PID" || true
  fi
}
trap cleanup_logs EXIT

echo "⏳ Esperando análisis..."
# GitHub-hosted runners limit jobs to 6h; keep default aligned and allow override.
timeout_secs="${BOOTSTRAP_TIMEOUT_SECS:-21600}"
elapsed=0
while [ ! -f "$RESULT_FILE" ] && [ "$elapsed" -lt "$timeout_secs" ]; do
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ -f "$RESULT_FILE" ]; then
  echo "✅ Resultado disponible en $RESULT_FILE"
  if [ "${BOOTSTRAP_REDACT:-0}" = "1" ]; then
    python3 - <<'PY'
import json
from pathlib import Path

path = Path("outputs/insights/analysis.json")
data = json.loads(path.read_text(encoding="utf-8"))
if not data:
    raise SystemExit("Redaction check failed: empty insights output")
record = data[0]
if not record.get("redacted") or not record.get("redaction", {}).get("enabled"):
    raise SystemExit("Redaction check failed: record not redacted")
if not record.get("redaction", {}).get("hash_salt_set"):
    raise SystemExit("Redaction check failed: hash_salt_set false")
print("✅ Redacción verificada en insights.")
PY
  fi
  cat "$RESULT_FILE"
else
  echo "❌ Insight aún no generado tras ${timeout_secs}s."
  exit 1
fi
