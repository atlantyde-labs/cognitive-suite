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
CS_LOG_PREFIX="validate-sso-mfa"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/platforms/compliance/sso-mfa-status.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

require_cmd() {
  cs_require_cmd "$1"
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
