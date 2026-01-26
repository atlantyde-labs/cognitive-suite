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

GITHUB_TOKEN=${GITHUB_TOKEN:-""}
GITHUB_API_URL=${GITHUB_API_URL:-"https://api.github.com"}
GITHUB_ORGS=${GITHUB_ORGS:-""}
GITHUB_ORGS_FILE=${GITHUB_ORGS_FILE:-""}
GITHUB_CLONE_TOKEN=${GITHUB_CLONE_TOKEN:-"${GITHUB_TOKEN}"}

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

if [[ -z "${GITHUB_TOKEN}" ]]; then
  echo "GITHUB_TOKEN is required" >&2
  exit 1
fi
if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
  echo "GITEA_URL and GITEA_TOKEN are required" >&2
  exit 1
fi

read_orgs() {
  local list=()
  if [[ -n "${GITHUB_ORGS}" ]]; then
    IFS=',' read -r -a list <<< "${GITHUB_ORGS}"
  fi
  if [[ -n "${GITHUB_ORGS_FILE}" ]]; then
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      list+=("${line}")
    done < "${GITHUB_ORGS_FILE}"
  fi
  printf '%s\n' "${list[@]}" | awk 'NF'
}

map_owner() {
  local gh_owner=$1
  if [[ -z "${GITEA_OWNER_MAP}" ]]; then
    echo "${gh_owner}"
    return
  fi
  local mapping
  IFS=',' read -r -a mapping <<< "${GITEA_OWNER_MAP}"
  for pair in "${mapping[@]}"; do
    local k=${pair%%=*}
    local v=${pair#*=}
    if [[ "${k}" == "${gh_owner}" ]]; then
      echo "${v}"
      return
    fi
  done
  echo "${gh_owner}"
}

list_repos() {
  local org=$1
  local page=1
  while :; do
    local resp
    resp=$(curl -fsSL \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "${GITHUB_API_URL}/orgs/${org}/repos?per_page=100&page=${page}&type=all")
    local count
    count=$(echo "${resp}" | jq 'length')
    if [[ "${count}" -eq 0 ]]; then
      break
    fi
    echo "${resp}" | jq -r '.[] | [.name, .private, .clone_url, .archived] | @tsv'
    page=$((page + 1))
  done
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
  local gh_org=$1
  local repo=$2
  local private=$3
  local clone_url=$4
  local archived=$5

  if [[ "${archived}" == "true" ]]; then
    echo "Skipping archived repo ${gh_org}/${repo}"
    return
  fi

  local target_owner
  target_owner=$(map_owner "${gh_org}")

  if repo_exists_in_gitea "${target_owner}" "${repo}"; then
    echo "Repo already exists in Gitea: ${target_owner}/${repo}"
    return
  fi

  local clone_token
  clone_token=${GITHUB_CLONE_TOKEN:-"${GITHUB_TOKEN}"}
  local clone_with_token
  clone_with_token="${clone_url/https:\/\//https:\/\/x-access-token:${clone_token}@}"

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
    echo "DRY_RUN: would migrate ${gh_org}/${repo} -> ${target_owner}/${repo}"
    return
  fi

  local status
  status=$(curl -sS -o /tmp/gitea-migrate.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${GITEA_URL}/api/v1/repos/migrate" \
    -d "${payload}")

  if [[ "${status}" != "201" && "${status}" != "202" ]]; then
    echo "Migration failed for ${gh_org}/${repo} (HTTP ${status})" >&2
    cat /tmp/gitea-migrate.json >&2
    return
  fi

  echo "Migrated ${gh_org}/${repo} -> ${target_owner}/${repo}"
}

orgs=$(read_orgs)
if [[ -z "${orgs}" ]]; then
  echo "No GitHub orgs provided" >&2
  exit 1
fi

while IFS= read -r org; do
  echo "Listing repos for ${org}"
  while IFS=$'\t' read -r repo private clone_url archived; do
    migrate_repo "${org}" "${repo}" "${private}" "${clone_url}" "${archived}"
  done < <(list_repos "${org}")
done <<< "${orgs}"
