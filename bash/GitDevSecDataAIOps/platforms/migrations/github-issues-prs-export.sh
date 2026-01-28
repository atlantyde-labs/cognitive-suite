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
CS_LOG_PREFIX="github-export"

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

GITHUB_TOKEN=${GITHUB_TOKEN:-""}
GITHUB_API_URL=${GITHUB_API_URL:-"https://api.github.com"}
GITHUB_ORGS=${GITHUB_ORGS:-""}
GITHUB_ORGS_FILE=${GITHUB_ORGS_FILE:-""}

EXPORT_DIR=${EXPORT_DIR:-"./exports/github"}
EXPORT_ISSUES=${EXPORT_ISSUES:-"true"}
EXPORT_PULLS=${EXPORT_PULLS:-"true"}
INCLUDE_ARCHIVED=${INCLUDE_ARCHIVED:-"false"}
SINCE=${SINCE:-""}
PER_PAGE=${PER_PAGE:-"100"}
API_SLEEP_SECONDS=${API_SLEEP_SECONDS:-"0"}

if [[ -z "${GITHUB_TOKEN}" ]]; then
  cs_die "GITHUB_TOKEN is required"
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

list_repos() {
  local org=$1
  local page=1
  while :; do
    local resp
    resp=$(curl -fsSL \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "${GITHUB_API_URL}/orgs/${org}/repos?per_page=${PER_PAGE}&page=${page}&type=all")
    local count
    count=$(echo "${resp}" | jq 'length')
    if [[ "${count}" -eq 0 ]]; then
      break
    fi
    echo "${resp}" | jq -r '.[] | [.name, .archived] | @tsv'
    page=$((page + 1))
  done
}

fetch_items() {
  local url=$1
  local page=1
  while :; do
    local resp
    resp=$(curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" "${url}&page=${page}")
    local count
    count=$(echo "${resp}" | jq 'length')
    if [[ "${count}" -eq 0 ]]; then
      break
    fi
    echo "${resp}"
    page=$((page + 1))
    if [[ "${API_SLEEP_SECONDS}" != "0" ]]; then
      sleep "${API_SLEEP_SECONDS}"
    fi
  done
}

export_issues() {
  local org=$1
  local repo=$2
  local out_dir=$3
  local url
  url="${GITHUB_API_URL}/repos/${org}/${repo}/issues?state=all&per_page=${PER_PAGE}"
  if [[ -n "${SINCE}" ]]; then
    url="${url}&since=${SINCE}"
  fi

  : > "${out_dir}/issues.jsonl"

  fetch_items "${url}" | jq -c '.[] | select(.pull_request | not)' >> "${out_dir}/issues.jsonl"
}

export_pulls() {
  local org=$1
  local repo=$2
  local out_dir=$3
  local url
  url="${GITHUB_API_URL}/repos/${org}/${repo}/pulls?state=all&per_page=${PER_PAGE}"
  if [[ -n "${SINCE}" ]]; then
    url="${url}&since=${SINCE}"
  fi

  : > "${out_dir}/pulls.jsonl"

  fetch_items "${url}" | jq -c '.[]' >> "${out_dir}/pulls.jsonl"
}

orgs=$(read_orgs)
if [[ -z "${orgs}" ]]; then
  echo "No GitHub orgs provided" >&2
  exit 1
fi

mkdir -p "${EXPORT_DIR}"

while IFS= read -r org; do
  echo "Exporting issues/PRs for ${org}"
  while IFS=$'\t' read -r repo archived; do
    if [[ "${archived}" == "true" && "${INCLUDE_ARCHIVED}" != "true" ]]; then
      echo "Skipping archived repo ${org}/${repo}"
      continue
    fi
    out_dir="${EXPORT_DIR}/${org}/${repo}"
    mkdir -p "${out_dir}"

    if [[ "${EXPORT_ISSUES}" == "true" ]]; then
      echo "Exporting issues for ${org}/${repo}"
      export_issues "${org}" "${repo}" "${out_dir}"
    fi
    if [[ "${EXPORT_PULLS}" == "true" ]]; then
      echo "Exporting PRs for ${org}/${repo}"
      export_pulls "${org}" "${repo}" "${out_dir}"
    fi
  done < <(list_repos "${org}")
done <<< "${orgs}"
