#!/usr/bin/env bash
set -euo pipefail

IMAGE="$1"
PORT="$2"
OUTPUTS_HOST="$3"
OUTPUTS_CONTAINER="$4"

docker run --rm -p "${PORT}:8501" \
  -v "${OUTPUTS_HOST}:${OUTPUTS_CONTAINER}" \
  -e COGNITIVE_OUTPUTS="${OUTPUTS_CONTAINER}" \
  "$IMAGE"
