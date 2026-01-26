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

GITLAB_TOKEN=${GITLAB_TOKEN:-""}
GITLAB_API_URL=${GITLAB_API_URL:-"https://gitlab.com/api/v4"}
GITLAB_GROUPS=${GITLAB_GROUPS:-""}
GITLAB_GROUPS_FILE=${GITLAB_GROUPS_FILE:-""}
GITLAB_CLONE_TOKEN=${GITLAB_CLONE_TOKEN:-"${GITLAB_TOKEN}"}
GITLAB_OWNER_STRATEGY=${GITLAB_OWNER_STRATEGY:-"top-level"}

GITEA_URL=${GITEA_URL:-""}
GITEA_TOKEN=${GITEA_TOKEN:-""}
GITEA_OWNER_MAP=${GITEA_OWNER_MAP:-""}

MIGRATE_MIRROR=${MIGRATE_MIRROR:-"true"}
MIGRATE_PRIVATE=${MIGRATE_PRIVATE:-"true"}
MIGRATE_LFS=${MIGRATE_LFS:-"true"}
MIGRATE_ISSUES=${MIGRATE_ISSUES:-"true"}
MIGRATE_PULL_REQUESTS=${MIGRATE_PULL_REQUESTS:-"true"}
MIGRATE_LABELS=${MIGRATE_LABELS:-"true"}
MIGRATE_MILESTONES=${MIGRATE_MILESTONES:-"true"}
MIGRATE_RELEASES=${MIGRATE_RELEASES:-"true"}
MIGRATE_WIKI=${MIGRATE_WIKI:-"true"}
MIGRATE_PROJECTS=${MIGRATE_PROJECTS:-"true"}
DRY_RUN=${DRY_RUN:-"false"}

if [[ -z "${GITLAB_TOKEN}" ]]; then
  echo "GITLAB_TOKEN is required" >&2
  exit 1
fi
if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
  echo "GITEA_URL and GITEA_TOKEN are required" >&2
  exit 1
fi

read_groups() {
  local list=()
  if [[ -n "${GITLAB_GROUPS}" ]]; then
    IFS=',' read -r -a list <<< "${GITLAB_GROUPS}"
  fi
  if [[ -n "${GITLAB_GROUPS_FILE}" ]]; then
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      list+=("${line}")
    done < "${GITLAB_GROUPS_FILE}"
  fi
  printf '%s\n' "${list[@]}" | awk 'NF'
}

urlencode() {
  jq -rn --arg v "$1" '$v|@uri'
}

map_owner() {
  local owner=$1
  if [[ -z "${GITEA_OWNER_MAP}" ]]; then
    echo "${owner}"
    return
  fi
  local mapping
  IFS=',' read -r -a mapping <<< "${GITEA_OWNER_MAP}"
  for pair in "${mapping[@]}"; do
    local k=${pair%%=*}
    local v=${pair#*=}
    if [[ "${k}" == "${owner}" ]]; then
      echo "${v}"
      return
    fi
  done
  echo "${owner}"
}

list_projects() {
  local group=$1
  local page=1
  local enc
  enc=$(urlencode "${group}")
  while :; do
    local resp
    resp=$(curl -fsSL \
      -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
      "${GITLAB_API_URL}/groups/${enc}/projects?per_page=100&page=${page}&include_subgroups=true")
    local count
    count=$(echo "${resp}" | jq 'length')
    if [[ "${count}" -eq 0 ]]; then
      break
    fi
    echo "${resp}" | jq -r '.[] | [.path_with_namespace, .http_url_to_repo, .archived] | @tsv'
    page=$((page + 1))
  done
}

resolve_owner_repo() {
  local full=$1
  local repo=${full##*/}
  local owner_path=${full%/*}
  local owner
  if [[ "${GITLAB_OWNER_STRATEGY}" == "full" ]]; then
    owner=${owner_path}
  else
    owner=${owner_path%%/*}
  fi
  echo "${owner}|${repo}"
}

repo_exists_in_gitea() {
  local owner=$1
  local repo=$2
  local status
  status=$(curl -sS -o /dev/null -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    "${GITEA_URL}/api/v1/repos/${owner}/${repo}")
  [[ "${status}" == "200" ]]
}

migrate_repo() {
  local path_with_ns=$1
  local clone_url=$2
  local archived=$3

  if [[ "${archived}" == "true" ]]; then
    echo "Skipping archived repo ${path_with_ns}"
    return
  fi

  local owner_repo
  owner_repo=$(resolve_owner_repo "${path_with_ns}")
  local source_owner=${owner_repo%%|*}
  local repo=${owner_repo##*|}
  local target_owner
  target_owner=$(map_owner "${source_owner}")

  if repo_exists_in_gitea "${target_owner}" "${repo}"; then
    echo "Repo already exists in Gitea: ${target_owner}/${repo}"
    return
  fi

  local clone_token
  clone_token=${GITLAB_CLONE_TOKEN:-"${GITLAB_TOKEN}"}
  local clone_with_token
  clone_with_token="${clone_url/https:\/\//https:\/\/oauth2:${clone_token}@}"

  local payload
  payload=$(jq -n \
    --arg repo_name "${repo}" \
    --arg repo_owner "${target_owner}" \
    --arg clone_addr "${clone_with_token}" \
    --argjson mirror "${MIGRATE_MIRROR}" \
    --argjson private "${MIGRATE_PRIVATE}" \
    --argjson issues "${MIGRATE_ISSUES}" \
    --argjson pull_requests "${MIGRATE_PULL_REQUESTS}" \
    --argjson wiki "${MIGRATE_WIKI}" \
    --argjson labels "${MIGRATE_LABELS}" \
    --argjson milestones "${MIGRATE_MILESTONES}" \
    --argjson releases "${MIGRATE_RELEASES}" \
    --argjson lfs "${MIGRATE_LFS}" \
    --argjson projects "${MIGRATE_PROJECTS}" \
    '{repo_name: $repo_name, repo_owner: $repo_owner, clone_addr: $clone_addr, mirror: $mirror, private: $private, issues: $issues, pull_requests: $pull_requests, wiki: $wiki, labels: $labels, milestones: $milestones, releases: $releases, lfs: $lfs, projects: $projects}')

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would migrate ${path_with_ns} -> ${target_owner}/${repo}"
    return
  fi

  local status
  status=$(curl -sS -o /tmp/gitea-migrate.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${GITEA_URL}/api/v1/repos/migrate" \
    -d "${payload}")

  if [[ "${status}" != "201" && "${status}" != "202" ]]; then
    echo "Migration failed for ${path_with_ns} (HTTP ${status})" >&2
    cat /tmp/gitea-migrate.json >&2
    return
  fi

  echo "Migrated ${path_with_ns} -> ${target_owner}/${repo}"
}

groups=$(read_groups)
if [[ -z "${groups}" ]]; then
  echo "No GitLab groups provided" >&2
  exit 1
fi

while IFS= read -r group; do
  echo "Listing projects for ${group}"
  while IFS=$'\t' read -r path_with_ns clone_url archived; do
    migrate_repo "${path_with_ns}" "${clone_url}" "${archived}"
  done < <(list_projects "${group}")
done <<< "${groups}"
