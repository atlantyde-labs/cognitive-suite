#!/usr/bin/env bash
set -euo pipefail

LOG_PREFIX="[gitea-model-lock]"

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
OWNER=${OWNER:-""}
REPOS=${REPOS:-""}
FOUNDERS=${FOUNDERS:-""}
DRY_RUN=${DRY_RUN:-"false"}

ENFORCE_PRIVATE=${ENFORCE_PRIVATE:-"true"}
ENFORCE_COLLABORATORS=${ENFORCE_COLLABORATORS:-"true"}
COLLAB_PERMISSION=${COLLAB_PERMISSION:-"admin"}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_cmd curl
require_cmd jq

if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
  fail "GITEA_URL and GITEA_TOKEN are required"
fi
if [[ -z "${OWNER}" || -z "${REPOS}" || -z "${FOUNDERS}" ]]; then
  fail "OWNER, REPOS, FOUNDERS are required"
fi

IFS=',' read -r -a repo_list <<< "${REPOS}"
IFS=',' read -r -a founder_list <<< "${FOUNDERS}"

normalize() {
  echo "$1" | xargs
}

api() {
  local method=$1
  local path=$2
  shift 2 || true
  local url="${GITEA_URL}/api/v1${path}"
  if [[ "${DRY_RUN}" == "true" && "${method}" != "GET" ]]; then
    log "[dry-run] ${method} ${url} $*"
    return 0
  fi
  case "${method}" in
    GET)
      curl -fsSL -H "Authorization: token ${GITEA_TOKEN}" "${url}"
      ;;
    PATCH)
      curl -sS -o /tmp/gitea-lock.json -w '%{http_code}' \
        -H "Authorization: token ${GITEA_TOKEN}" \
        -H "Content-Type: application/json" \
        -X PATCH "${url}" \
        -d "$1" > /tmp/gitea-lock.status
      ;;
    PUT|DELETE)
      curl -sS -o /tmp/gitea-lock.json -w '%{http_code}' \
        -H "Authorization: token ${GITEA_TOKEN}" \
        -X "${method}" "${url}" \
        -d "$1" > /tmp/gitea-lock.status
      ;;
    *)
      fail "Unsupported method: ${method}"
      ;;
  esac
}

update_repo_private() {
  local repo=$1
  local payload='{"private":true}'
  api PATCH "/repos/${OWNER}/${repo}" "${payload}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    return
  fi
  status=$(cat /tmp/gitea-lock.status)
  if [[ "${status}" -lt 200 || "${status}" -ge 300 ]]; then
    cat /tmp/gitea-lock.json >&2 || true
    fail "Failed to set repo private ${OWNER}/${repo} (HTTP ${status})"
  fi
}

list_collabs() {
  api GET "/repos/${OWNER}/${repo}/collaborators"
}

ensure_collaborators() {
  local repo=$1
  local collabs
  collabs=$(api GET "/repos/${OWNER}/${repo}/collaborators")
  local current=()
  mapfile -t current < <(echo "${collabs}" | jq -r '.[].login')

  for login in "${current[@]}"; do
    keep="false"
    for founder in "${founder_list[@]}"; do
      if [[ "$(normalize "${founder}")" == "$(normalize "${login}")" ]]; then
        keep="true"
        break
      fi
    done
    if [[ "${keep}" != "true" ]]; then
      api DELETE "/repos/${OWNER}/${repo}/collaborators/${login}"
      if [[ "${DRY_RUN}" != "true" ]]; then
        status=$(cat /tmp/gitea-lock.status)
        if [[ "${status}" -lt 200 || "${status}" -ge 300 ]]; then
          cat /tmp/gitea-lock.json >&2 || true
          fail "Failed to remove collaborator ${login} from ${OWNER}/${repo}"
        fi
      fi
    fi
  done

  for founder in "${founder_list[@]}"; do
    founder=$(normalize "${founder}")
    if [[ -z "${founder}" ]]; then
      continue
    fi
    if printf '%s\n' "${current[@]}" | grep -qx "${founder}"; then
      continue
    fi
    api PUT "/repos/${OWNER}/${repo}/collaborators/${founder}" "permission=${COLLAB_PERMISSION}"
    if [[ "${DRY_RUN}" != "true" ]]; then
      status=$(cat /tmp/gitea-lock.status)
      if [[ "${status}" -lt 200 || "${status}" -ge 300 ]]; then
        cat /tmp/gitea-lock.json >&2 || true
        fail "Failed to add collaborator ${founder} to ${OWNER}/${repo}"
      fi
    fi
  done
}

for repo in "${repo_list[@]}"; do
  repo=$(normalize "${repo}")
  if [[ -z "${repo}" ]]; then
    continue
  fi
  log "Locking ${OWNER}/${repo}"
  if [[ "${ENFORCE_PRIVATE}" == "true" ]]; then
    update_repo_private "${repo}"
  fi
  if [[ "${ENFORCE_COLLABORATORS}" == "true" ]]; then
    ensure_collaborators "${repo}"
  fi
done

log "Lockdown complete"
