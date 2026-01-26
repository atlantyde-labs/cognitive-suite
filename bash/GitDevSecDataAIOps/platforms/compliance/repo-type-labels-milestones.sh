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
RULES_FILE=${RULES_FILE:-""}
DEFAULT_TYPE=${DEFAULT_TYPE:-"general"}
MATCH_MODE=${MATCH_MODE:-"name"}
CREATE_LABELS=${CREATE_LABELS:-"true"}
CREATE_MILESTONES=${CREATE_MILESTONES:-"true"}
DRY_RUN=${DRY_RUN:-"false"}

if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
  echo "GITEA_URL and GITEA_TOKEN are required" >&2
  exit 1
fi
if [[ -z "${RULES_FILE}" || ! -f "${RULES_FILE}" ]]; then
  echo "RULES_FILE not found" >&2
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
  curl -sS -o /tmp/gitea-type.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${GITEA_URL}/api/v1${path}" \
    -d "${payload}"
}

list_repos_for_owner() {
  local owner=$1
  local page=1
  while :; do
    local status
    status=$(curl -sS -o /tmp/gitea-repos.json -w '%{http_code}' \
      -H "Authorization: token ${GITEA_TOKEN}" \
      "${GITEA_URL}/api/v1/orgs/${owner}/repos?limit=50&page=${page}")
    if [[ "${status}" == "404" ]]; then
      status=$(curl -sS -o /tmp/gitea-repos.json -w '%{http_code}' \
        -H "Authorization: token ${GITEA_TOKEN}" \
        "${GITEA_URL}/api/v1/users/${owner}/repos?limit=50&page=${page}")
    fi
    if [[ "${status}" != "200" ]]; then
      echo "Failed to list repos for ${owner} (HTTP ${status})" >&2
      return
    fi
    local count
    count=$(jq 'length' /tmp/gitea-repos.json)
    if [[ "${count}" -eq 0 ]]; then
      break
    fi
    jq -c '.[]' /tmp/gitea-repos.json
    page=$((page + 1))
  done
}

load_rules() {
  rules_type=()
  rules_regex=()
  rules_labels=()
  rules_milestones=()

  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    [[ "${line}" == \#* ]] && continue
    IFS=',' read -r type regex labels milestones <<< "${line}"
    type=$(echo "${type}" | xargs)
    regex=$(echo "${regex}" | xargs)
    labels=$(echo "${labels}" | xargs)
    milestones=$(echo "${milestones}" | xargs)
    [[ -z "${type}" || -z "${regex}" ]] && continue
    rules_type+=("${type}")
    rules_regex+=("${regex}")
    rules_labels+=("${labels}")
    rules_milestones+=("${milestones}")
  done < "${RULES_FILE}"
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

  if [[ -z "${color}" ]]; then
    color="ffffff"
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
    cat /tmp/gitea-type.json >&2
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
    cat /tmp/gitea-type.json >&2
  fi
}

classify_repo() {
  local name=$1
  local description=$2
  local key
  if [[ "${MATCH_MODE}" == "name+description" ]]; then
    key="${name} ${description}"
  else
    key="${name}"
  fi

  local idx
  for idx in "${!rules_type[@]}"; do
    if [[ "${key}" =~ ${rules_regex[$idx]} ]]; then
      echo "${idx}"
      return
    fi
  done

  echo "-1"
}

apply_labels_milestones() {
  local owner=$1
  local repo=$2
  local labels=$3
  local milestones=$4

  if [[ "${CREATE_LABELS}" == "true" && -n "${labels}" ]]; then
    IFS=';' read -r -a label_list <<< "${labels}"
    for label in "${label_list[@]}"; do
      [[ -z "${label}" ]] && continue
      local name color
      if [[ "${label}" == *"|"* ]]; then
        name=${label%%|*}
        color=${label#*|}
      else
        name=${label}
        color=""
      fi
      ensure_label "${owner}" "${repo}" "${name}" "${color}"
    done
  fi

  if [[ "${CREATE_MILESTONES}" == "true" && -n "${milestones}" ]]; then
    IFS=';' read -r -a ms_list <<< "${milestones}"
    for ms in "${ms_list[@]}"; do
      [[ -z "${ms}" ]] && continue
      IFS='|' read -r title description due_on state <<< "${ms}"
      ensure_milestone "${owner}" "${repo}" "${title}" "${description:-}" "${due_on:-}" "${state:-}"
    done
  fi
}

load_rules
owners=$(read_owners)
if [[ -z "${owners}" ]]; then
  echo "No Gitea owners provided" >&2
  exit 1
fi

while IFS= read -r owner; do
  echo "Processing owner ${owner}"
  while IFS= read -r repo_json; do
    name=$(echo "${repo_json}" | jq -r '.name')
    description=$(echo "${repo_json}" | jq -r '.description // ""')
    idx=$(classify_repo "${name}" "${description}")
    if [[ "${idx}" == "-1" ]]; then
      type="${DEFAULT_TYPE}"
      labels="type:${type}"
      milestones=""
    else
      type="${rules_type[$idx]}"
      labels="${rules_labels[$idx]}"
      milestones="${rules_milestones[$idx]}"
    fi

    echo "  Repo ${owner}/${name} -> type ${type}"
    apply_labels_milestones "${owner}" "${name}" "${labels}" "${milestones}"
  done < <(list_repos_for_owner "${owner}")
done <<< "${owners}"
