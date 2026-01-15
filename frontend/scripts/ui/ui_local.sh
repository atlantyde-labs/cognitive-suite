#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8501}"
OUTPUTS_HOST="${2:-../outputs}"

export COGNITIVE_OUTPUTS="$OUTPUTS_HOST"

echo "UI local at http://localhost:${PORT}"
streamlit run streamlit_app.py \
  --server.headless=true \
  --server.port="$PORT"
