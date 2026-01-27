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
CS_LOG_PREFIX="install-reboot-guard"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/platforms/ops-systems/reboot-guard.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

require_cmd() {
  cs_require_cmd "$1"
}

SERVICE_NAME=${SERVICE_NAME:-"reboot-guard"}
ENV_TARGET=${ENV_TARGET:-"/etc/reboot-guard.env"}
SERVICE_TARGET=${SERVICE_TARGET:-"/etc/systemd/system/${SERVICE_NAME}.service"}
WRAPPER_TARGET=${WRAPPER_TARGET:-"/usr/local/bin/reboot-guard.sh"}
SERVICE_SOURCE=${SERVICE_SOURCE:-"${SCRIPT_DIR}/reboot-guard.service.example"}
WRAPPER_SOURCE=${WRAPPER_SOURCE:-"${SCRIPT_DIR}/reboot-guard.sh"}
LIB_SOURCE=${LIB_SOURCE:-"${CS_ROOT}/lib/cs-common.sh"}
LIB_TARGET=${LIB_TARGET:-"/usr/local/lib/cognitive-suite/cs-common.sh"}

DRY_RUN=${DRY_RUN:-"false"}
if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

require_cmd systemctl

if [[ ! -f "${SERVICE_SOURCE}" || ! -f "${WRAPPER_SOURCE}" ]]; then
  echo "Service or wrapper source not found" >&2
  exit 1
fi

if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] would install env to ${ENV_TARGET}"
  else
    install -m 0600 "${CONFIG_PATH}" "${ENV_TARGET}"
  fi
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[dry-run] would install wrapper to ${WRAPPER_TARGET}"
  echo "[dry-run] would install library to ${LIB_TARGET}"
  echo "[dry-run] would install service to ${SERVICE_TARGET}"
  echo "[dry-run] would enable ${SERVICE_NAME}"
  exit 0
fi

install -m 0755 "${WRAPPER_SOURCE}" "${WRAPPER_TARGET}"
install -d "$(dirname "${LIB_TARGET}")"
install -m 0644 "${LIB_SOURCE}" "${LIB_TARGET}"
install -m 0644 "${SERVICE_SOURCE}" "${SERVICE_TARGET}"

systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}"

echo "Installed and started ${SERVICE_NAME}"
