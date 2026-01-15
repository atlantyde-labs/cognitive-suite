#!/bin/bash

echo "🔍 Iniciando prueba local de Cognitive GitOps Suite..."

# Preparar estructura
mkdir -p data/input outputs/raw outputs/insights schemas qdrant_storage

# Copiar input de prueba
echo '{ "content": "El proyecto de microK8s europeo promueve la soberanía digital. Riesgos regulatorios pueden incluir el incumplimiento del RGPD. Ideas innovadoras incluyen orquestación distribuida con GitOps legalmente trazable." }' > data/input/demo_input.json

# Iniciar contenedores
docker compose up -d --build

echo "⏳ Esperando análisis..."
# Esperar unos segundos a que el pipeline genere el archivo
sleep 10

RESULT_FILE="outputs/insights/analysis.json"
if [ -f "$RESULT_FILE" ]; then
  echo "✅ Resultado disponible en $RESULT_FILE"
  cat "$RESULT_FILE"
else
  echo "⚠️ Insight aún no generado."
fi
