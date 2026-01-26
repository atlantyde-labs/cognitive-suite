#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-}"
shift || true

if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    echo "Config not found: ${CONFIG_PATH}" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "${CONFIG_PATH}"
fi

PVE_API_URL=${PVE_API_URL:-""}
PVE_API_TOKEN=${PVE_API_TOKEN:-""}
PVE_INSECURE=${PVE_INSECURE:-"false"}
DRY_RUN=${DRY_RUN:-"false"}

if [[ -z "${PVE_API_URL}" || -z "${PVE_API_TOKEN}" ]]; then
  echo "PVE_API_URL and PVE_API_TOKEN are required" >&2
  exit 1
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
    echo "Unsupported method: ${METHOD}" >&2
    exit 1
    ;;
esac

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[dry-run] curl ${curl_args[*]}"
  exit 0
fi

curl "${curl_args[@]}"
