#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CS_LIB_FALLBACK="/usr/local/lib/cognitive-suite/cs-common.sh"
if [[ -f "${CS_LIB_FALLBACK}" ]]; then
  # shellcheck disable=SC1090,SC1091
  source "${CS_LIB_FALLBACK}"
else
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
fi

# shellcheck disable=SC2034
CS_LOG_PREFIX="gitea-runner-service"

ACTION=${1:-start}
ENV_FILE=${ENV_FILE:-"/etc/gitea-runner.env"}
ENV_EXAMPLE="${SCRIPT_DIR}/gitea-runner.env.example"

if [[ -f "${ENV_FILE}" ]]; then
  cs_load_env_file "${ENV_FILE}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}" || true
fi

require_cmd() {
  cs_require_cmd "$1"
}

require_cmd docker

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

CONFIG_PATH_HOST="${RUNNER_DATA_DIR}/config.yaml"

register_runner() {
  if [[ -f "${CONFIG_PATH_HOST}" ]]; then
    echo "Runner config exists at ${CONFIG_PATH_HOST}; skipping register."
    return
  fi
  if [[ -z "${GITEA_INSTANCE_URL}" || -z "${RUNNER_TOKEN}" ]]; then
    cs_die "GITEA_INSTANCE_URL and RUNNER_TOKEN are required"
  fi

  local register_cmd=(
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
    mkdir -p "${RUNNER_DATA_DIR}"
    "${register_cmd[@]}"
  fi
}

start_runner() {
  local daemon_cmd=(
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
    return
  fi

  if docker ps -a --format '{{.Names}}' | grep -qx "${RUNNER_CONTAINER_NAME}"; then
    docker rm -f "${RUNNER_CONTAINER_NAME}"
  fi
  "${daemon_cmd[@]}"
}

stop_runner() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] docker rm -f ${RUNNER_CONTAINER_NAME}"
    return
  fi
  if docker ps -a --format '{{.Names}}' | grep -qx "${RUNNER_CONTAINER_NAME}"; then
    docker rm -f "${RUNNER_CONTAINER_NAME}"
  fi
}

case "${ACTION}" in
  start)
    register_runner
    start_runner
    ;;
  stop)
    stop_runner
    ;;
  restart)
    stop_runner
    register_runner
    start_runner
    ;;
  status)
    docker ps --filter "name=${RUNNER_CONTAINER_NAME}"
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}" >&2
    exit 1
    ;;
esac
