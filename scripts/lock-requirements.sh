#!/usr/bin/env bash
set -euo pipefail

VENV_DIR=".venv"

if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/pip" install --upgrade pip pip-tools

"$VENV_DIR/bin/pip-compile" requirements.in -o requirements.txt
"$VENV_DIR/bin/pip-compile" requirements-docs.in -o requirements-docs.txt
"$VENV_DIR/bin/pip-compile" frontend/requirements.in -o frontend/requirements.txt
"$VENV_DIR/bin/pip-compile" ingestor/requirements.in -o ingestor/requirements.txt
"$VENV_DIR/bin/pip-compile" pipeline/requirements.in -o pipeline/requirements.txt

echo "✅ Lockfiles updated."
