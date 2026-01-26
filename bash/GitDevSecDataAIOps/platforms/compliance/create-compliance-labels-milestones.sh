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

GITEA_URL=${GITEA_URL:-""}
GITEA_TOKEN=${GITEA_TOKEN:-""}

GITEA_OWNERS=${GITEA_OWNERS:-""}
GITEA_OWNERS_FILE=${GITEA_OWNERS_FILE:-""}
REPO_FILTER=${REPO_FILTER:-""}

CREATE_LABELS=${CREATE_LABELS:-"true"}
CREATE_MILESTONES=${CREATE_MILESTONES:-"true"}
DRY_RUN=${DRY_RUN:-"false"}

COMPLIANCE_LABELS_FILE=${COMPLIANCE_LABELS_FILE:-""}
COMPLIANCE_MILESTONES_FILE=${COMPLIANCE_MILESTONES_FILE:-""}

if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
  echo "GITEA_URL and GITEA_TOKEN are required" >&2
  exit 1
fi

read_owners() {
  local list=()
  if [[ -n "${GITEA_OWNERS}" ]]; then
    IFS=',' read -r -a list <<< "${GITEA_OWNERS}"
  fi
  if [[ -n "${GITEA_OWNERS_FILE}" ]]; then
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      list+=("${line}")
    done < "${GITEA_OWNERS_FILE}"
  fi
  printf '%s\n' "${list[@]}" | awk 'NF'
}

api_get() {
  local path=$1
  curl -fsSL -H "Authorization: token ${GITEA_TOKEN}" "${GITEA_URL}/api/v1${path}"
}

api_post() {
  local path=$1
  local payload=$2
  curl -sS -o /tmp/gitea-compliance.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${GITEA_URL}/api/v1${path}" \
    -d "${payload}"
}

list_repos_for_owner() {
  local owner=$1
  local page=1
  while :; do
    local resp status
    resp=$(curl -sS -o /tmp/gitea-repos.json -w '%{http_code}' \
      -H "Authorization: token ${GITEA_TOKEN}" \
      "${GITEA_URL}/api/v1/orgs/${owner}/repos?limit=50&page=${page}")
    if [[ "${resp}" == "404" ]]; then
      resp=$(curl -sS -o /tmp/gitea-repos.json -w '%{http_code}' \
        -H "Authorization: token ${GITEA_TOKEN}" \
        "${GITEA_URL}/api/v1/users/${owner}/repos?limit=50&page=${page}")
    fi
    status=${resp}
    if [[ "${status}" != "200" ]]; then
      echo "Failed to list repos for ${owner} (HTTP ${status})" >&2
      return
    fi
    local count
    count=$(jq 'length' /tmp/gitea-repos.json)
    if [[ "${count}" -eq 0 ]]; then
      break
    fi
    jq -r '.[] | .name' /tmp/gitea-repos.json
    page=$((page + 1))
  done
}

load_labels() {
  local labels=()
  if [[ -n "${COMPLIANCE_LABELS_FILE}" && -f "${COMPLIANCE_LABELS_FILE}" ]]; then
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      [[ "${line}" == \#* ]] && continue
      labels+=("${line}")
    done < "${COMPLIANCE_LABELS_FILE}"
  else
    labels+=("compliance:gdpr,b60205")
    labels+=("compliance:nis2,0e8a16")
    labels+=("compliance:dora,1d76db")
    labels+=("compliance:iso27001,5319e7")
    labels+=("compliance:risk,fbca04")
    labels+=("compliance:audit,0052cc")
    labels+=("compliance:incident,d4c5f9")
  fi
  printf '%s\n' "${labels[@]}"
}

load_milestones() {
  local milestones=()
  if [[ -n "${COMPLIANCE_MILESTONES_FILE}" && -f "${COMPLIANCE_MILESTONES_FILE}" ]]; then
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      [[ "${line}" == \#* ]] && continue
      milestones+=("${line}")
    done < "${COMPLIANCE_MILESTONES_FILE}"
  else
    milestones+=("GDPR Baseline,,,")
    milestones+=("NIS2 Readiness,,,")
    milestones+=("DORA Controls,,,")
    milestones+=("ISO 27001 ISMS,,,")
  fi
  printf '%s\n' "${milestones[@]}"
}

ensure_label() {
  local owner=$1
  local repo=$2
  local name=$3
  local color=$4

  local exists
  exists=$(api_get "/repos/${owner}/${repo}/labels" | jq -r --arg name "${name}" '.[] | select(.name == $name) | .id' | head -n1)
  if [[ -n "${exists}" ]]; then
    return
  fi

  local payload
  payload=$(jq -n --arg name "${name}" --arg color "${color}" '{name: $name, color: $color}')

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would create label ${owner}/${repo}:${name}"
    return
  fi

  local status
  status=$(api_post "/repos/${owner}/${repo}/labels" "${payload}")
  if [[ "${status}" != "201" ]]; then
    echo "Failed to create label ${owner}/${repo}:${name} (HTTP ${status})" >&2
    cat /tmp/gitea-compliance.json >&2
  fi
}

ensure_milestone() {
  local owner=$1
  local repo=$2
  local title=$3
  local description=$4
  local due_on=$5
  local state=$6

  local exists
  exists=$(api_get "/repos/${owner}/${repo}/milestones" | jq -r --arg title "${title}" '.[] | select(.title == $title) | .id' | head -n1)
  if [[ -n "${exists}" ]]; then
    return
  fi

  local payload
  payload=$(jq -n \
    --arg title "${title}" \
    --arg description "${description}" \
    --arg due_on "${due_on}" \
    --arg state "${state}" \
    '{title: $title} + ( $description | if length>0 then {description: $description} else {} end ) + ( $due_on | if length>0 then {due_on: $due_on} else {} end ) + ( $state | if length>0 then {state: $state} else {} end )')

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would create milestone ${owner}/${repo}:${title}"
    return
  fi

  local status
  status=$(api_post "/repos/${owner}/${repo}/milestones" "${payload}")
  if [[ "${status}" != "201" ]]; then
    echo "Failed to create milestone ${owner}/${repo}:${title} (HTTP ${status})" >&2
    cat /tmp/gitea-compliance.json >&2
  fi
}

owners=$(read_owners)
if [[ -z "${owners}" ]]; then
  echo "No Gitea owners provided" >&2
  exit 1
fi

mapfile -t labels < <(load_labels)
mapfile -t milestones < <(load_milestones)

while IFS= read -r owner; do
  echo "Processing owner ${owner}"
  while IFS= read -r repo; do
    if [[ -n "${REPO_FILTER}" && "${repo}" != *"${REPO_FILTER}"* ]]; then
      continue
    fi
    echo "  Repo ${owner}/${repo}"

    if [[ "${CREATE_LABELS}" == "true" ]]; then
      for label in "${labels[@]}"; do
        name=${label%%,*}
        color=${label#*,}
        ensure_label "${owner}" "${repo}" "${name}" "${color}"
      done
    fi

    if [[ "${CREATE_MILESTONES}" == "true" ]]; then
      for ms in "${milestones[@]}"; do
        IFS=',' read -r title description due_on state <<< "${ms}"
        ensure_milestone "${owner}" "${repo}" "${title}" "${description}" "${due_on}" "${state}"
      done
    fi
  done < <(list_repos_for_owner "${owner}")
done <<< "${owners}"
