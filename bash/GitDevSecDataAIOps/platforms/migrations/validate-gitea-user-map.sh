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
CS_LOG_PREFIX="validate-user-map"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/platforms/migrations/github-to-gitea.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

require_cmd() {
  cs_require_cmd "$1"
}

require_cmd curl

GITEA_URL=${GITEA_URL:-""}
GITEA_TOKEN=${GITEA_TOKEN:-""}
USER_MAP_FILE=${USER_MAP_FILE:-""}
OUTPUT_FILE=${OUTPUT_FILE:-""}
ALLOW_MISSING=${ALLOW_MISSING:-"false"}

if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
  cs_die "GITEA_URL and GITEA_TOKEN are required"
fi

if [[ -z "${USER_MAP_FILE}" || ! -f "${USER_MAP_FILE}" ]]; then
  cs_die "USER_MAP_FILE not found"
fi

check_user() {
  local user=$1
  local status
  status=$(curl -sS -o /dev/null -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    "${GITEA_URL}/api/v1/users/${user}")
  [[ "${status}" == "200" ]]
}

missing=()

if [[ -n "${OUTPUT_FILE}" ]]; then
  : > "${OUTPUT_FILE}"
fi

while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  [[ "${line}" == \#* ]] && continue

  gh_user=""
  gitea_user=""

  if [[ "${line}" == *","* ]]; then
    IFS=',' read -r gh_user gitea_user _ <<< "${line}"
    if [[ "${gh_user}" == "github_user" ]]; then
      continue
    fi
  else
    IFS='=' read -r gh_user gitea_user <<< "${line}"
  fi

  gh_user=$(echo "${gh_user}" | xargs)
  gitea_user=$(echo "${gitea_user}" | xargs)

  [[ -z "${gh_user}" || -z "${gitea_user}" ]] && continue

  if check_user "${gitea_user}"; then
    echo "OK ${gh_user} -> ${gitea_user}"
    if [[ -n "${OUTPUT_FILE}" ]]; then
      printf '%s=%s\n' "${gh_user}" "${gitea_user}" >> "${OUTPUT_FILE}"
    fi
  else
    echo "MISSING ${gh_user} -> ${gitea_user}" >&2
    missing+=("${gh_user}:${gitea_user}")
  fi
done < "${USER_MAP_FILE}"

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "Missing users: ${missing[*]}" >&2
  if [[ "${ALLOW_MISSING}" != "true" ]]; then
    exit 1
  fi
fi
