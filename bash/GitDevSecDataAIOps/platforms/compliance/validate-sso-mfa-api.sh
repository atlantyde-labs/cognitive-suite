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

require_cmd curl
require_cmd jq

SSO_STATUS_ENDPOINT=${SSO_STATUS_ENDPOINT:-""}
MFA_STATUS_ENDPOINT=${MFA_STATUS_ENDPOINT:-""}
SSO_MFA_API_TOKEN=${SSO_MFA_API_TOKEN:-""}
SSO_MFA_API_HEADER=${SSO_MFA_API_HEADER:-"Authorization: Bearer ${SSO_MFA_API_TOKEN}"}
SSO_STATUS_JQ=${SSO_STATUS_JQ:-".sso_enabled // .enabled"}
MFA_STATUS_JQ=${MFA_STATUS_JQ:-".mfa_enforced // .enabled"}
OUTPUT_FILE=${OUTPUT_FILE:-""}

fetch_flag() {
  local endpoint=$1
  local filter=$2
  if [[ -z "${endpoint}" ]]; then
    echo ""
    return
  fi

  local header_args=()
  if [[ -n "${SSO_MFA_API_TOKEN}" ]]; then
    header_args=(-H "${SSO_MFA_API_HEADER}")
  fi

  local json
  if ! json=$(curl -fsSL "${header_args[@]}" "${endpoint}"); then
    echo ""
    return
  fi

  local value
  value=$(echo "${json}" | jq -r "${filter}" 2>/dev/null || true)
  if [[ "${value}" == "true" || "${value}" == "false" ]]; then
    echo "${value}"
  else
    echo ""
  fi
}

sso=$(fetch_flag "${SSO_STATUS_ENDPOINT}" "${SSO_STATUS_JQ}")
mfa=$(fetch_flag "${MFA_STATUS_ENDPOINT}" "${MFA_STATUS_JQ}")

report=$(jq -n \
  --arg sso "${sso}" \
  --arg mfa "${mfa}" \
  '{sso_enabled: ($sso == "true"), mfa_enforced: ($mfa == "true") }')

echo "${report}"

if [[ -n "${OUTPUT_FILE}" ]]; then
  echo "${report}" > "${OUTPUT_FILE}"
  echo "Report written to ${OUTPUT_FILE}"
fi
