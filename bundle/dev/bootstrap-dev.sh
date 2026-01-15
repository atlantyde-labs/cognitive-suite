#!/usr/bin/env bash
# dev/bootstrap-dev.sh
# ------------------------------------
#
# Este script prepara un entorno de desarrollo completo para los
# primeros adoptantes (early‑adopters) de la Cognitive GitOps Suite.
# Está pensado para ejecutarse en sistemas GNU/Linux con permisos
# suficientes para instalar paquetes. Automatiza la instalación de
# dependencias de sistema, la creación de un entorno virtual Python,
# la instalación de las dependencias del proyecto y la descarga de
# modelos NLP. Finalmente, inicializa la estructura del proyecto,
# ejecuta la ingesta y análisis de cualquier archivo colocado en
# `data/input/` y lanza la interfaz TUI para que los desarrolladores
# puedan explorar los resultados de forma interactiva.

set -euo pipefail

echo "🛠️  Iniciando bootstrap para entorno de desarrollo..."

#
# 1. Dependencias de sistema
#
# Actualiza el índice de paquetes y instala Python, pip, venv y FFmpeg
# para procesar audio/vídeo. También instala librerías básicas de
# desarrollo que algunas dependencias nativas (como PyMuPDF) requieren.
echo "🔍 Comprobando e instalando dependencias de sistema..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-venv python3-pip ffmpeg build-essential libgl1-mesa-dev libgtk-3-dev

#
# 2. Configurar entorno virtual
#
# Utilizamos un entorno virtual para aislar las dependencias del
# proyecto y evitar conflictos con otras aplicaciones. Si ya existe,
# simplemente lo activamos.
echo "🐍 Configurando entorno virtual Python (.venv)..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate

# Actualiza pip a la última versión
pip install --upgrade pip

#
# 3. Instalar dependencias de Python
#
# Instalamos todas las librerías necesarias definidas en
# requirements.txt. Esto incluye PyPDF2, PyMuPDF, Whisper, spaCy,
# transformers, FAISS, Streamlit, Rich, entre otras.
echo "📦 Instalando dependencias Python del proyecto..."
pip install -r requirements.txt

# Descarga el modelo de spaCy en español (si no está ya instalado).
if ! python -m spacy validate 2>/dev/null | grep -q "es_core_news_md"; then
  echo "🧠 Descargando modelo spaCy en español (es_core_news_md)..."
  python -m spacy download es_core_news_md || true
fi

#
# 4. Inicializar la estructura de la suite
#
# Creamos las carpetas necesarias (data/input, outputs/raw, outputs/insights,
# etc.) mediante el comando `cogctl.py init` incluido en el proyecto.
echo "📁 Inicializando estructura de carpetas del proyecto..."
python cogctl.py init

#
# 5. Ingesta y análisis automáticos (opcional)
#
# Si el usuario ha colocado archivos en data/input/, los ingerimos y
# lanzamos el análisis. Esto prepara datos reales para ser explorados
# inmediatamente en la TUI.
if [ -d "data/input" ] && [ "$(ls -A data/input 2>/dev/null || true)" ]; then
  echo "📄 Ingeriendo archivos encontrados en data/input/..."
  for f in data/input/*; do
    python cogctl.py ingest "$(basename "$f")"
  done
  echo "🧮 Ejecutando análisis semántico..."
  python cogctl.py analyze
else
  echo "⚠️  No se encontraron archivos en data/input. Puedes copiar archivos PDF, DOCX, JSON, audio o vídeo en esa carpeta y volver a ejecutar la ingesta mediante 'python cogctl.py ingest nombre_archivo'."
fi

#
# 6. Lanzar la interfaz TUI
#
# Finalmente, arrancamos la interfaz de terminal basada en Rich. Esta
# interfaz permite a los adoptantes filtrar por etiquetas, ver
# resúmenes, sentimientos y entidades de los documentos procesados. El
# script se bloqueará hasta que el usuario cierre la TUI.
echo "🖥️  Lanzando interfaz TUI de exploración de análisis..."
python frontend/tui.py

echo "✅ Bootstrap de desarrollo completado. ¡Disfruta explorando la suite!"