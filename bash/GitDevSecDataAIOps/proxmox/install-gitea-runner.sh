#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-}"
if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    echo "Config not found: ${CONFIG_PATH}" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "${CONFIG_PATH}"
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

GITEA_INSTANCE_URL=${GITEA_INSTANCE_URL:-""}
RUNNER_TOKEN=${RUNNER_TOKEN:-""}
RUNNER_NAME=${RUNNER_NAME:-"proxmox-local-01"}
RUNNER_LABELS=${RUNNER_LABELS:-"local"}
RUNNER_IMAGE=${RUNNER_IMAGE:-"gitea/act_runner:latest"}
RUNNER_DATA_DIR=${RUNNER_DATA_DIR:-"/opt/gitea-runner"}
RUNNER_CONTAINER_NAME=${RUNNER_CONTAINER_NAME:-"gitea-runner"}
RUNNER_CONFIG_FILE=${RUNNER_CONFIG_FILE:-"/data/config.yaml"}
RUNNER_REGISTER_ARGS=${RUNNER_REGISTER_ARGS:-""}
RUNNER_DAEMON_ARGS=${RUNNER_DAEMON_ARGS:-""}
DRY_RUN=${DRY_RUN:-"false"}

if [[ -z "${GITEA_INSTANCE_URL}" || -z "${RUNNER_TOKEN}" ]]; then
  echo "GITEA_INSTANCE_URL and RUNNER_TOKEN are required" >&2
  exit 1
fi

require_cmd docker

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[dry-run] would create ${RUNNER_DATA_DIR}"
else
  mkdir -p "${RUNNER_DATA_DIR}"
fi

register_cmd=(
  docker run --rm
  -v "${RUNNER_DATA_DIR}:/data"
  "${RUNNER_IMAGE}"
  act_runner register
  --no-interactive
  --instance "${GITEA_INSTANCE_URL}"
  --token "${RUNNER_TOKEN}"
  --name "${RUNNER_NAME}"
  --labels "${RUNNER_LABELS}"
  --config "${RUNNER_CONFIG_FILE}"
)
if [[ -n "${RUNNER_REGISTER_ARGS}" ]]; then
  # shellcheck disable=SC2206
  register_cmd+=(${RUNNER_REGISTER_ARGS})
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[dry-run] ${register_cmd[*]}"
else
  "${register_cmd[@]}"
fi

daemon_cmd=(
  docker run -d
  --name "${RUNNER_CONTAINER_NAME}"
  --restart unless-stopped
  -v "${RUNNER_DATA_DIR}:/data"
  -v /var/run/docker.sock:/var/run/docker.sock
  "${RUNNER_IMAGE}"
  act_runner daemon
  --config "${RUNNER_CONFIG_FILE}"
)
if [[ -n "${RUNNER_DAEMON_ARGS}" ]]; then
  # shellcheck disable=SC2206
  daemon_cmd+=(${RUNNER_DAEMON_ARGS})
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[dry-run] ${daemon_cmd[*]}"
else
  # replace existing container if present
  if docker ps -a --format '{{.Names}}' | grep -qx "${RUNNER_CONTAINER_NAME}"; then
    docker rm -f "${RUNNER_CONTAINER_NAME}"
  fi
  "${daemon_cmd[@]}"
fi

if [[ "${DRY_RUN}" != "true" ]]; then
  echo "Gitea runner started: ${RUNNER_CONTAINER_NAME}"
fi
