#!/bin/bash
# dev/bootstrap.sh
# ----------------
#
# Script de arranque para desarrolladores. Ejecuta las funciones básicas
# de la suite de forma interactiva: validación, ingesta de un archivo de
# muestra, análisis y visualización de resultados. Este script asume
# que los módulos están disponibles localmente sin necesidad de Docker.

set -euo pipefail
echo "🧠 Inicializando entorno cognitivo (modo Developer)..."

# Crear estructura de carpetas
python3 cogctl.py init

# Copiar archivo de demostración si existe
DEMO_FILE="outputs/demo_input.json"
if [ -f "$DEMO_FILE" ]; then
  cp "$DEMO_FILE" data/input/
fi

# Ingerir archivo de ejemplo
if [ -n "$(ls data/input 2>/dev/null)" ]; then
  for f in data/input/*; do
    python3 cogctl.py ingest "$(basename "$f")"
  done
fi

# Ejecutar análisis
python3 cogctl.py analyze

# Mostrar resultados
python3 frontend/app.py

echo "✅ Developer bootstrap finalizado."