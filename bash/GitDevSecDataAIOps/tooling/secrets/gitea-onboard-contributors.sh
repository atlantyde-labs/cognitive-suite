#!/usr/bin/env bash
set -euo pipefail

LOG_PREFIX="[gitea-onboard]"

log() {
  echo "${LOG_PREFIX} $*"
}

fail() {
  echo "${LOG_PREFIX} ERROR: $*" >&2
  exit 1
}

CONFIG_PATH="${1:-}"
if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    fail "Config not found: ${CONFIG_PATH}"
  fi
  # shellcheck disable=SC1090
  source "${CONFIG_PATH}"
fi

GITEA_URL=${GITEA_URL:-""}
GITEA_TOKEN=${GITEA_TOKEN:-""}
ORG=${ORG:-""}
USERS_CSV=${USERS_CSV:-""}
DEFAULT_PASSWORD=${DEFAULT_PASSWORD:-""}
GENERATE_PASSWORDS=${GENERATE_PASSWORDS:-"true"}
PASSWORD_OUTPUT=${PASSWORD_OUTPUT:-""}
DRY_RUN=${DRY_RUN:-"true"}

ENFORCE_MUST_CHANGE_PASSWORD=${ENFORCE_MUST_CHANGE_PASSWORD:-"true"}
ADD_SSH_KEYS=${ADD_SSH_KEYS:-"true"}
ADD_ORG_MEMBERSHIP=${ADD_ORG_MEMBERSHIP:-"true"}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_cmd curl
require_cmd jq

if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
  fail "GITEA_URL and GITEA_TOKEN are required"
fi
if [[ -z "${USERS_CSV}" || ! -f "${USERS_CSV}" ]]; then
  fail "USERS_CSV is required"
fi

if [[ -n "${PASSWORD_OUTPUT}" ]]; then
  install -d -m 0700 "$(dirname "${PASSWORD_OUTPUT}")"
  : > "${PASSWORD_OUTPUT}"
  chmod 600 "${PASSWORD_OUTPUT}"
fi

generate_password() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 24
    return
  fi
  python3 - <<'PY'
import secrets
import string
alphabet = string.ascii_letters + string.digits + "!@#%^*-_"
print("".join(secrets.choice(alphabet) for _ in range(24)))
PY
}

api_post_json() {
  local path=$1
  local payload=$2
  local url="${GITEA_URL}/api/v1${path}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] POST ${url} payload=${payload}"
    return 0
  fi
  curl -sS -o /tmp/gitea-onboard.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${url}" \
    -d "${payload}" > /tmp/gitea-onboard.status
}

api_put() {
  local path=$1
  local url="${GITEA_URL}/api/v1${path}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] PUT ${url}"
    return 0
  fi
  curl -sS -o /tmp/gitea-onboard.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -X PUT "${url}" > /tmp/gitea-onboard.status
}

api_post_form() {
  local path=$1
  local form=$2
  local url="${GITEA_URL}/api/v1${path}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] POST ${url} form=${form}"
    return 0
  fi
  curl -sS -o /tmp/gitea-onboard.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -X POST "${url}" \
    -d "${form}" > /tmp/gitea-onboard.status
}

check_status() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    return 0
  fi
  local status
  status=$(cat /tmp/gitea-onboard.status)
  if [[ "${status}" -lt 200 || "${status}" -ge 300 ]]; then
    cat /tmp/gitea-onboard.json >&2 || true
    fail "Gitea API error (HTTP ${status})"
  fi
}

trim() {
  echo "$1" | xargs
}

log "Onboarding users from ${USERS_CSV}"
while IFS=',' read -r username email full_name ssh_key; do
  username=$(trim "${username}")
  email=$(trim "${email}")
  full_name=$(trim "${full_name}")
  ssh_key=$(trim "${ssh_key}")

  [[ -z "${username}" || "${username}" == username* ]] && continue

  password="${DEFAULT_PASSWORD}"
  if [[ -z "${password}" && "${GENERATE_PASSWORDS}" == "true" ]]; then
    password=$(generate_password)
  fi
  if [[ -z "${password}" ]]; then
    fail "No password provided for ${username}"
  fi

  payload=$(jq -n \
    --arg username "${username}" \
    --arg email "${email}" \
    --arg full_name "${full_name}" \
    --arg password "${password}" \
    --argjson must_change "$( [[ "${ENFORCE_MUST_CHANGE_PASSWORD}" == "true" ]] && echo true || echo false )" \
    '{username:$username,email:$email,full_name:$full_name,password:$password,must_change_password:$must_change}')

  log "Creating user ${username}"
  api_post_json "/admin/users" "${payload}"
  check_status

  if [[ -n "${ORG}" && "${ADD_ORG_MEMBERSHIP}" == "true" ]]; then
    log "Adding ${username} to org ${ORG}"
    api_put "/orgs/${ORG}/members/${username}"
    check_status
  fi

  if [[ "${ADD_SSH_KEYS}" == "true" && -n "${ssh_key}" ]]; then
    key_value="${ssh_key}"
    if [[ -f "${ssh_key}" ]]; then
      key_value=$(cat "${ssh_key}")
    fi
    form="title=${username}-key&key=${key_value}"
    log "Adding SSH key for ${username}"
    api_post_form "/admin/users/${username}/keys" "${form}"
    check_status
  fi

  if [[ -n "${PASSWORD_OUTPUT}" ]]; then
    printf '%s,%s\n' "${username}" "${password}" >> "${PASSWORD_OUTPUT}"
  fi
done < "${USERS_CSV}"

log "Onboarding complete. Ensure each user enrolls MFA in Gitea UI."
