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
CS_LOG_PREFIX="gitlab-sync"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/platforms/migrations/gitlab-to-gitea.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

require_cmd() {
  cs_require_cmd "$1"
}

require_cmd curl
require_cmd jq
require_cmd git

GITLAB_TOKEN=${GITLAB_TOKEN:-""}
GITLAB_API_URL=${GITLAB_API_URL:-"https://gitlab.com/api/v4"}
GITLAB_GROUPS=${GITLAB_GROUPS:-""}
GITLAB_GROUPS_FILE=${GITLAB_GROUPS_FILE:-""}
GITLAB_CLONE_TOKEN=${GITLAB_CLONE_TOKEN:-"${GITLAB_TOKEN}"}
GITLAB_OWNER_STRATEGY=${GITLAB_OWNER_STRATEGY:-"top-level"}

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

if [[ -z "${GITLAB_TOKEN}" ]]; then
  cs_die "GITLAB_TOKEN is required"
fi
if [[ -z "${GITEA_URL}" ]]; then
  cs_die "GITEA_URL is required"
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

  local clone_token
  clone_token=${GITLAB_CLONE_TOKEN:-"${GITLAB_TOKEN}"}
  local clone_with_token
  clone_with_token="${clone_url/https:\/\//https:\/\/oauth2:${clone_token}@}"

  local repo_dir="${MIRROR_WORKDIR}/${path_with_ns}.git"
  mkdir -p "${repo_dir%/*}"

  if [[ ! -d "${repo_dir}" ]]; then
    echo "Cloning mirror ${path_with_ns}"
    git clone --mirror "${clone_with_token}" "${repo_dir}"
  else
    echo "Updating mirror ${path_with_ns}"
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

groups=$(read_groups)
if [[ -z "${groups}" ]]; then
  echo "No GitLab groups provided" >&2
  exit 1
fi

while IFS= read -r group; do
  echo "Syncing projects for ${group}"
  while IFS=$'\t' read -r path_with_ns clone_url archived; do
    sync_repo "${path_with_ns}" "${clone_url}" "${archived}"
  done < <(list_projects "${group}")
done <<< "${groups}"
