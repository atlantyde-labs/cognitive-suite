#!/usr/bin/env bash
set -euo pipefail
umask 077

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
CS_LOG_PREFIX="gh-pr-errors"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/tooling/forensics/gh-pr-errors.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

REPO=${REPO:-"${GITHUB_REPOSITORY:-}"}
PR_NUMBER=${PR_NUMBER:-""}
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
OUTPUT_DIR=${OUTPUT_DIR:-"./outputs/ci-evidence/pr-forensics"}
PER_PAGE=${PER_PAGE:-"100"}
DOWNLOAD_LOGS=${DOWNLOAD_LOGS:-"false"}
INTERACTIVE=${INTERACTIVE:-"true"}

require_cmd() {
  cs_require_cmd "$1"
}

require_cmd jq
require_cmd curl

if [[ -z "${REPO}" ]]; then
  fail "REPO is required (owner/repo)"
fi
if [[ -z "${PR_NUMBER}" ]]; then
  fail "PR_NUMBER is required"
fi

mkdir -p "${OUTPUT_DIR}"

if [[ "${INTERACTIVE}" == "true" ]]; then
  cs_ui_header "GitHub PR Forensics"
  cs_ui_note "Repo: ${REPO}"
  cs_ui_note "PR: ${PR_NUMBER}"
  if [[ -z "${GITHUB_TOKEN}" ]]; then
    cs_ui_note "GITHUB_TOKEN not set; public API only (rate-limited)"
  fi
  if [[ "${DOWNLOAD_LOGS}" == "true" ]]; then
    cs_ui_note "Download logs: enabled"
  elif cs_ui_confirm "Download job logs?" "N"; then
    DOWNLOAD_LOGS="true"
  fi
fi

auth_header=()
if [[ -n "${GITHUB_TOKEN}" ]]; then
  auth_header=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

api_get() {
  local url=$1
  curl -sS -H "Accept: application/vnd.github+json" "${auth_header[@]}" "${url}"
}

log "Fetching PR metadata"
pr_json="${OUTPUT_DIR}/pr.json"
api_get "https://api.github.com/repos/${REPO}/pulls/${PR_NUMBER}" > "${pr_json}"

sha=$(jq -r '.head.sha // empty' "${pr_json}")
if [[ -z "${sha}" ]]; then
  fail "Unable to read PR head sha"
fi
log "Head SHA: ${sha}"

log "Fetching check runs"
checks_json="${OUTPUT_DIR}/check-runs.json"
api_get "https://api.github.com/repos/${REPO}/commits/${sha}/check-runs?per_page=${PER_PAGE}" > "${checks_json}"

log "Fetching workflow runs"
runs_json="${OUTPUT_DIR}/workflow-runs.json"
api_get "https://api.github.com/repos/${REPO}/actions/runs?per_page=${PER_PAGE}&head_sha=${sha}" > "${runs_json}"

summary_json="${OUTPUT_DIR}/summary.json"
jq -r '
  {
    pr: {number: .number, title: .title, state: .state, head_sha: .head.sha, html_url: .html_url},
    checks: $checks.check_runs | map({id, name, status, conclusion, app: .app.slug, html_url})
      | map(select(.conclusion != "success" and .conclusion != null)),
    workflows: $runs.workflow_runs | map({id, name, status, conclusion, html_url, event, head_branch})
      | map(select(.conclusion != "success" and .conclusion != null))
  }
' --slurpfile checks "${checks_json}" --slurpfile runs "${runs_json}" "${pr_json}" > "${summary_json}"

log "Summary written to ${summary_json}"

if [[ "${DOWNLOAD_LOGS}" == "true" ]]; then
  log "Downloading failed job logs"
  jobs_dir="${OUTPUT_DIR}/jobs"
  logs_dir="${OUTPUT_DIR}/logs"
  mkdir -p "${jobs_dir}" "${logs_dir}"

  run_ids=$(jq -r '.workflow_runs[] | select(.conclusion != "success" and .conclusion != null) | .id' "${runs_json}")
  for run_id in ${run_ids}; do
    jobs_json="${jobs_dir}/run-${run_id}.json"
    api_get "https://api.github.com/repos/${REPO}/actions/runs/${run_id}/jobs?per_page=${PER_PAGE}" > "${jobs_json}"
    job_ids=$(jq -r '.jobs[] | select(.conclusion != "success" and .conclusion != null) | .id' "${jobs_json}")
    for job_id in ${job_ids}; do
      log "Downloading logs for job ${job_id}"
      curl -sSL -H "Accept: application/vnd.github+json" "${auth_header[@]}" \
        "https://api.github.com/repos/${REPO}/actions/jobs/${job_id}/logs" \
        -o "${logs_dir}/job-${job_id}.log"
    done
  done
fi

log "PR forensics complete"
