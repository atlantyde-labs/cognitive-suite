#!/bin/bash
set -euo pipefail

echo "🔍 Iniciando prueba local de Cognitive GitOps Suite..."

# Preparar estructura
mkdir -p data/input outputs/raw outputs/insights schemas qdrant_storage

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

# Forzar redacción si se solicita (no imprime el secreto).
if [ "${BOOTSTRAP_REDACT:-0}" = "1" ]; then
  export COGNITIVE_ENV="${COGNITIVE_ENV:-prod}"
  export COGNITIVE_REDACT="${COGNITIVE_REDACT:-1}"
  export COGNITIVE_AUDIT_LOG="${COGNITIVE_AUDIT_LOG:-/data/outputs/audit/analysis.jsonl}"
  if [ -z "${COGNITIVE_HASH_SALT:-}" ]; then
    echo "❌ COGNITIVE_HASH_SALT debe estar definido para redacción."
    exit 1
  fi
  echo "🔒 Redacción habilitada (COGNITIVE_ENV=$COGNITIVE_ENV, COGNITIVE_REDACT=$COGNITIVE_REDACT, COGNITIVE_HASH_SALT=***)"
fi

# Iniciar contenedores
docker compose up -d --build

RESULT_FILE="outputs/insights/analysis.json"
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
  cat "$RESULT_FILE"
else
  echo "❌ Insight aún no generado tras ${timeout_secs}s."
  exit 1
fi
