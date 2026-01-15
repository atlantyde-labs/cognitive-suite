#!/usr/bin/env bash
set -euo pipefail

OUTPUTS_HOST="${1:-../outputs}"
FILE="${OUTPUTS_HOST}/insights/analysis.json"

if [[ ! -f "$FILE" ]]; then
  echo "Missing $FILE"
  echo "Tip: generate outputs first, or set COGNITIVE_OUTPUTS to your outputs path."
  exit 1
fi

echo "UI Doctor OK -> $FILE found"
