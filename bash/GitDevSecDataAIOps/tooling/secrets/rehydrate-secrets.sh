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

SECRETS_FILE=${SECRETS_FILE:-""}
SECRETS_VALUE_B64=${SECRETS_VALUE_B64:-"false"}
DRY_RUN=${DRY_RUN:-"false"}

if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

GITEA_URL=${GITEA_URL:-""}
GITEA_TOKEN=${GITEA_TOKEN:-""}
GITEA_SECRET_SET_CMD=${GITEA_SECRET_SET_CMD:-""}

if [[ -z "${SECRETS_FILE}" ]]; then
  echo "SECRETS_FILE is required" >&2
  exit 1
fi
if [[ ! -f "${SECRETS_FILE}" ]]; then
  echo "Secrets file not found: ${SECRETS_FILE}" >&2
  exit 1
fi

maybe_decode() {
  local value=$1
  if [[ "${SECRETS_VALUE_B64}" == "true" ]]; then
    echo "${value}" | base64 -d
  else
    echo "${value}"
  fi
}

set_gitea_secret_default() {
  local owner=$1
  local repo=$2
  local name=$3
  local value=$4

  if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
    echo "Gitea URL/token missing for ${owner}/${repo}:${name}" >&2
    return 1
  fi

  require_cmd jq

  local payload
  payload=$(jq -n --arg data "${value}" '{data: $data}')

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would set gitea secret ${owner}/${repo}:${name}"
    return 0
  fi

  local status
  status=$(curl -sS -o /tmp/gitea-secret.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X PUT "${GITEA_URL}/api/v1/repos/${owner}/${repo}/actions/secrets/${name}" \
    -d "${payload}")

  if [[ "${status}" != "204" && "${status}" != "200" && "${status}" != "201" ]]; then
    echo "Failed to set gitea secret ${owner}/${repo}:${name} (HTTP ${status})" >&2
    cat /tmp/gitea-secret.json >&2 || true
    return 1
  fi

  echo "Set gitea secret ${owner}/${repo}:${name}"
}

set_gitea_secret() {
  local owner=$1
  local repo=$2
  local name=$3
  local value=$4

  if [[ -n "${GITEA_SECRET_SET_CMD}" ]]; then
    if [[ "${DRY_RUN}" == "true" ]]; then
      echo "DRY_RUN: would run custom gitea secret command for ${owner}/${repo}:${name}"
      return 0
    fi
    local cmd
    cmd=${GITEA_SECRET_SET_CMD//\{owner\}/${owner}}
    cmd=${cmd//\{repo\}/${repo}}
    cmd=${cmd//\{name\}/${name}}
    cmd=${cmd//\{value\}/${value}}
    eval "${cmd}"
    echo "Set gitea secret ${owner}/${repo}:${name}"
  else
    set_gitea_secret_default "${owner}" "${repo}" "${name}" "${value}"
  fi
}

set_github_secret() {
  local scope=$1
  local owner=$2
  local repo=$3
  local name=$4
  local value=$5

  require_cmd gh

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would set github secret ${scope}:${owner}/${repo}:${name}"
    return 0
  fi

  if [[ "${scope}" == "org" ]]; then
    gh secret set "${name}" -b"${value}" -o "${owner}"
  else
    gh secret set "${name}" -b"${value}" -R "${owner}/${repo}"
  fi
}

set_gitlab_secret() {
  local owner=$1
  local repo=$2
  local name=$3
  local value=$4

  require_cmd glab

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would set gitlab secret ${owner}/${repo}:${name}"
    return 0
  fi

  glab variable set "${name}" --repo "${owner}/${repo}" --value "${value}" --masked
}

# CSV format: provider,scope,owner,repo,secret_name,secret_value
# provider: gitea|github|gitlab
# scope: repo|org (github only)
# owner: org/user
# repo: repo name or '-' for org scope
# secret_value: consider base64 if it contains commas
while IFS=',' read -r provider scope owner repo name value; do
  [[ -z "${provider}" ]] && continue
  [[ "${provider}" == "#"* ]] && continue

  value=$(maybe_decode "${value}")

  case "${provider}" in
    gitea)
      if [[ "${repo}" == "-" ]]; then
        echo "Gitea org-level secrets not supported by default for ${owner}:${name}" >&2
        continue
      fi
      set_gitea_secret "${owner}" "${repo}" "${name}" "${value}"
      ;;
    github)
      if [[ "${scope}" == "org" ]]; then
        set_github_secret "org" "${owner}" "-" "${name}" "${value}"
      else
        set_github_secret "repo" "${owner}" "${repo}" "${name}" "${value}"
      fi
      ;;
    gitlab)
      set_gitlab_secret "${owner}" "${repo}" "${name}" "${value}"
      ;;
    *)
      echo "Unknown provider: ${provider}" >&2
      ;;
  esac
done < "${SECRETS_FILE}"
