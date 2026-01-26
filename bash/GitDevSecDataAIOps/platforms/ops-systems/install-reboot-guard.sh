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

SERVICE_NAME=${SERVICE_NAME:-"reboot-guard"}
ENV_TARGET=${ENV_TARGET:-"/etc/reboot-guard.env"}
SERVICE_TARGET=${SERVICE_TARGET:-"/etc/systemd/system/${SERVICE_NAME}.service"}
WRAPPER_TARGET=${WRAPPER_TARGET:-"/usr/local/bin/reboot-guard.sh"}
SERVICE_SOURCE=${SERVICE_SOURCE:-"$(dirname "$0")/reboot-guard.service.example"}
WRAPPER_SOURCE=${WRAPPER_SOURCE:-"$(dirname "$0")/reboot-guard.sh"}

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
  echo "[dry-run] would install service to ${SERVICE_TARGET}"
  echo "[dry-run] would enable ${SERVICE_NAME}"
  exit 0
fi

install -m 0755 "${WRAPPER_SOURCE}" "${WRAPPER_TARGET}"
install -m 0644 "${SERVICE_SOURCE}" "${SERVICE_TARGET}"

systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}"

echo "Installed and started ${SERVICE_NAME}"
