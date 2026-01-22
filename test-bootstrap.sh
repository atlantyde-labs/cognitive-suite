#!/bin/bash
set -euo pipefail

echo "🔍 Iniciando prueba local de Cognitive GitOps Suite..."

# Preparar estructura
mkdir -p data/input outputs/raw outputs/insights schemas qdrant_storage

# Copiar input de prueba
echo '{ "content": "El proyecto de microK8s europeo promueve la soberanía digital. Riesgos regulatorios pueden incluir el incumplimiento del RGPD. Ideas innovadoras incluyen orquestación distribuida con GitOps legalmente trazable." }' > data/input/demo_input.json

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
