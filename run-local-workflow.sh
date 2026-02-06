#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_DIR=".github/workflows"
SECRETS_FILE=".actrc"

usage() {
  cat <<'EOF'
Usage: ./run-local-workflow.sh --job JOB_NAME [--workflow PATH] [--event PATH] [--image-mode MODE] [--image IMAGE]

Defaults:
  --workflow: will be inferred from JOB_NAME (see mapping)
  --event: tests/fixtures/<event>.json if a fixture is defined

Examples:
  ./run-local-workflow.sh --job gamify-approval --event tests/fixtures/pull_request_review-approved.json
  ./run-local-workflow.sh --job award-regulatory-xp --workflow ${WORKFLOW_DIR}/regulatory-xp-award.yml --event tests/fixtures/pull_request-labeled.json
  ./run-local-workflow.sh --job gamify-approval --image-mode medium
EOF
}

declare -A WORKFLOW_MAP=(
  ["gamify-approval"]="${WORKFLOW_DIR}/early-adopter-codeowner-approval.yml"
  ["award-regulatory-xp"]="${WORKFLOW_DIR}/regulatory-xp-award.yml"
  ["apply-decay"]="${WORKFLOW_DIR}/xp-decay-monthly.yml"
)

declare -A IMAGE_MODE_MAP=(
  ["act-latest"]="catthehacker/ubuntu:full-latest"
  ["medium"]="ghcr.io/catthehacker/ubuntu:act-22.04"
  ["micro"]="node:20-alpine"
)

IMAGE_MODE="act-latest"
CUSTOM_IMAGE=""

JOB=""
WORKFLOW=""
EVENT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --job)
      JOB="$2"
      shift 2
      ;;
    --image-mode)
      IMAGE_MODE="$2"
      shift 2
      ;;
    --image)
      CUSTOM_IMAGE="$2"
      shift 2
      ;;
    --workflow)
      WORKFLOW="$2"
      shift 2
      ;;
    --event)
      EVENT="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$JOB" ]]; then
  echo "Missing --job argument" >&2
  usage
  exit 1
fi

if [[ -z "$WORKFLOW" ]]; then
  WORKFLOW="${WORKFLOW_MAP[$JOB]:-}"
  if [[ -z "$WORKFLOW" ]]; then
    echo "No workflow mapped to job '$JOB'. Pass --workflow explicitly." >&2
    exit 1
  fi
fi

IMAGE="$CUSTOM_IMAGE"
if [[ -z "$IMAGE" ]]; then
  IMAGE="${IMAGE_MODE_MAP[$IMAGE_MODE]:-}"
fi

if [[ -z "$IMAGE" ]]; then
  echo "Unknown image mode '$IMAGE_MODE'. Available: ${!IMAGE_MODE_MAP[*]}" >&2
  exit 1
fi

ACT_CMD=("act" "--secret-file" "${SECRETS_FILE}" "--job" "${JOB}" "-P" "ubuntu-latest=${IMAGE}" "-W" "${WORKFLOW}")

if [[ -n "$EVENT" ]]; then
  ACT_CMD+=("--eventpath" "$EVENT")
fi

echo "==> Running: ${ACT_CMD[*]}"
"${ACT_CMD[@]}"
