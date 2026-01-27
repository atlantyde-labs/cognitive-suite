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
CS_LOG_PREFIX="github-sync"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/platforms/migrations/github-to-gitea.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

require_cmd() {
  cs_require_cmd "$1"
}

require_cmd curl
require_cmd jq
require_cmd git

GITHUB_TOKEN=${GITHUB_TOKEN:-""}
GITHUB_API_URL=${GITHUB_API_URL:-"https://api.github.com"}
GITHUB_ORGS=${GITHUB_ORGS:-""}
GITHUB_ORGS_FILE=${GITHUB_ORGS_FILE:-""}
GITHUB_CLONE_TOKEN=${GITHUB_CLONE_TOKEN:-"${GITHUB_TOKEN}"}

GITEA_URL=${GITEA_URL:-""}
GITEA_OWNER_MAP=${GITEA_OWNER_MAP:-""}
MIRROR_WORKDIR=${MIRROR_WORKDIR:-"/var/lib/gitea-mirrors"}
GITEA_PUSH_USER=${GITEA_PUSH_USER:-"gitea-bot"}
GITEA_PUSH_TOKEN=${GITEA_PUSH_TOKEN:-""}
GITEA_REMOTE_TEMPLATE=${GITEA_REMOTE_TEMPLATE:-""}
DRY_RUN=${DRY_RUN:-"false"}

if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

if [[ -z "${GITHUB_TOKEN}" ]]; then
  cs_die "GITHUB_TOKEN is required"
fi
if [[ -z "${GITEA_URL}" ]]; then
  cs_die "GITEA_URL is required"
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
    echo "${resp}" | jq -r '.[] | [.name, .clone_url, .archived] | @tsv'
    page=$((page + 1))
  done
}

build_gitea_remote() {
  local owner=$1
  local repo=$2

  if [[ -n "${GITEA_REMOTE_TEMPLATE}" ]]; then
    local out
    out=${GITEA_REMOTE_TEMPLATE//\{owner\}/${owner}}
    out=${out//\{repo\}/${repo}}
    echo "${out}"
    return
  fi

  local base=${GITEA_URL#http://}
  base=${base#https://}

  if [[ -n "${GITEA_PUSH_TOKEN}" ]]; then
    echo "https://${GITEA_PUSH_USER}:${GITEA_PUSH_TOKEN}@${base}/${owner}/${repo}.git"
  else
    echo "https://${base}/${owner}/${repo}.git"
  fi
}

sync_repo() {
  local gh_org=$1
  local repo=$2
  local clone_url=$3
  local archived=$4

  if [[ "${archived}" == "true" ]]; then
    echo "Skipping archived repo ${gh_org}/${repo}"
    return
  fi

  local target_owner
  target_owner=$(map_owner "${gh_org}")

  local clone_token
  clone_token=${GITHUB_CLONE_TOKEN:-"${GITHUB_TOKEN}"}
  local clone_with_token
  clone_with_token="${clone_url/https:\/\//https:\/\/x-access-token:${clone_token}@}"

  local repo_dir="${MIRROR_WORKDIR}/${gh_org}/${repo}.git"
  mkdir -p "${MIRROR_WORKDIR}/${gh_org}"

  if [[ ! -d "${repo_dir}" ]]; then
    echo "Cloning mirror ${gh_org}/${repo}"
    git clone --mirror "${clone_with_token}" "${repo_dir}"
  else
    echo "Updating mirror ${gh_org}/${repo}"
    git -C "${repo_dir}" remote update --prune
  fi

  local gitea_remote
  gitea_remote=$(build_gitea_remote "${target_owner}" "${repo}")

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would push mirror to ${gitea_remote}"
    return
  fi

  if git -C "${repo_dir}" remote | grep -qx gitea; then
    git -C "${repo_dir}" remote set-url gitea "${gitea_remote}"
  else
    git -C "${repo_dir}" remote add gitea "${gitea_remote}"
  fi

  git -C "${repo_dir}" push --mirror gitea

  if git -C "${repo_dir}" lfs env >/dev/null 2>&1; then
    git -C "${repo_dir}" lfs fetch --all
    git -C "${repo_dir}" lfs push --all gitea || true
  fi
}

orgs=$(read_orgs)
if [[ -z "${orgs}" ]]; then
  echo "No GitHub orgs provided" >&2
  exit 1
fi

while IFS= read -r org; do
  echo "Syncing repos for ${org}"
  while IFS=$'\t' read -r repo clone_url archived; do
    sync_repo "${org}" "${repo}" "${clone_url}" "${archived}"
  done < <(list_repos "${org}")
done <<< "${orgs}"
