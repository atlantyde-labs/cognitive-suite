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

CONFIG_PATH="${1:-}"
shift || true

ENV_EXAMPLE="${CS_ROOT}/proxmox/pve-api.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

PVE_API_URL=${PVE_API_URL:-""}
PVE_API_TOKEN=${PVE_API_TOKEN:-""}
PVE_INSECURE=${PVE_INSECURE:-"false"}
DRY_RUN=${DRY_RUN:-"false"}

if [[ -z "${PVE_API_URL}" || -z "${PVE_API_TOKEN}" ]]; then
  cs_die "PVE_API_URL and PVE_API_TOKEN are required"
fi

METHOD=${1:-""}
PATH_ARG=${2:-""}
shift 2 || true

if [[ -z "${METHOD}" || -z "${PATH_ARG}" ]]; then
  echo "Usage: $0 /path/to/pve-api.env METHOD /path [key=value ...]" >&2
  echo "Example: $0 pve-api.env GET /nodes" >&2
  echo "Example: $0 pve-api.env POST /nodes/pve/lxc vmid=100 hostname=test" >&2
  exit 1
fi

METHOD=$(echo "${METHOD}" | tr '[:lower:]' '[:upper:]')

curl_args=(
  -sS
  -H "Authorization: PVEAPIToken=${PVE_API_TOKEN}"
)

if [[ "${PVE_INSECURE}" == "true" ]]; then
  curl_args+=(--insecure)
fi

url="${PVE_API_URL}${PATH_ARG}"

if [[ "${#@}" -gt 0 ]]; then
  for kv in "$@"; do
    curl_args+=(--data-urlencode "${kv}")
  done
fi

case "${METHOD}" in
  GET)
    curl_args+=(--get "${url}")
    ;;
  POST|PUT|DELETE)
    curl_args+=(--request "${METHOD}" "${url}")
    ;;
  *)
    cs_die "Unsupported method: ${METHOD}"
    ;;
esac

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[dry-run] curl ${curl_args[*]}"
  exit 0
fi

curl "${curl_args[@]}"
