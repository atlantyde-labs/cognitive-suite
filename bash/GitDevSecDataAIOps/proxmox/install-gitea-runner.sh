#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CS_ROOT="${SCRIPT_DIR}"
while [[ ! -f "${CS_ROOT}/lib/cs-common.sh" ]]; do
  if [[ "${CS_ROOT}" == "/" ]]; then
    echo "cs-common.sh not found" >&2
    exit 1
  fi
  CS_ROOT=$(dirname "${CS_ROOT}")
done
# shellcheck disable=SC1090,SC1091
source "${CS_ROOT}/lib/cs-common.sh"

# shellcheck disable=SC2034
CS_LOG_PREFIX="install-gitea-runner"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/proxmox/gitea-runner.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

require_cmd() {
  cs_require_cmd "$1"
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
  cs_die "GITEA_INSTANCE_URL and RUNNER_TOKEN are required"
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
