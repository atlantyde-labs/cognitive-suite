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

GITEA_URL=${GITEA_URL:-""}
GITEA_TOKEN=${GITEA_TOKEN:-""}
USER_MAP_FILE=${USER_MAP_FILE:-""}
OUTPUT_FILE=${OUTPUT_FILE:-""}
ALLOW_MISSING=${ALLOW_MISSING:-"false"}

if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
  echo "GITEA_URL and GITEA_TOKEN are required" >&2
  exit 1
fi

if [[ -z "${USER_MAP_FILE}" || ! -f "${USER_MAP_FILE}" ]]; then
  echo "USER_MAP_FILE not found" >&2
  exit 1
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
