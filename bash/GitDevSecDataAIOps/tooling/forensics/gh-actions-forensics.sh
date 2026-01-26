#!/usr/bin/env bash
set -euo pipefail
umask 077

LOG_PREFIX="[actions-forensics]"

log() {
  echo "${LOG_PREFIX} $*"
}

fail() {
  echo "${LOG_PREFIX} ERROR: $*" >&2
  exit 1
}

REPO=${REPO:-"${GITHUB_REPOSITORY:-}"}
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
OUTPUT_DIR=${OUTPUT_DIR:-"./outputs/ci-evidence/actions-forensics"}
PER_PAGE=${PER_PAGE:-"100"}
PAGES=${PAGES:-"2"}
SINCE_DAYS=${SINCE_DAYS:-"30"}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_cmd jq
require_cmd curl

if [[ -z "${REPO}" ]]; then
  fail "REPO is required (e.g. atlantyde-labs/cognitive-suite)"
fi
if [[ -z "${GITHUB_TOKEN}" ]]; then
  fail "GITHUB_TOKEN is required"
fi

mkdir -p "${OUTPUT_DIR}"

log "Fetching Actions runs for ${REPO}"

raw_file="${OUTPUT_DIR}/actions-runs.json"
summary_file="${OUTPUT_DIR}/actions-summary.json"
by_workflow_file="${OUTPUT_DIR}/actions-by-workflow.json"
by_branch_file="${OUTPUT_DIR}/actions-by-branch.json"
by_event_file="${OUTPUT_DIR}/actions-by-event.json"
by_conclusion_file="${OUTPUT_DIR}/actions-by-conclusion.json"
failures_file="${OUTPUT_DIR}/actions-failures.json"

pages=()
for ((page=1; page<=PAGES; page++)); do
  url="https://api.github.com/repos/${REPO}/actions/runs?per_page=${PER_PAGE}&page=${page}"
  curl -sS \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "${url}" > "${OUTPUT_DIR}/page-${page}.json"
  pages+=("${OUTPUT_DIR}/page-${page}.json")
done

jq -s '{workflow_runs: [.[].workflow_runs[]]}' "${pages[@]}" > "${raw_file}"

jq -r --argjson since_days "${SINCE_DAYS}" '
  def safe_key(x): (x // "none");
  .workflow_runs as $runs
  | {
      total_runs: ($runs | length),
      earliest_run: ($runs | map(.created_at) | min?),
      latest_run: ($runs | map(.created_at) | max?),
      by_conclusion: ($runs | sort_by(.conclusion // "none") | group_by(.conclusion // "none")
        | map({conclusion: (.[0].conclusion // "none"), count: length})),
      by_event: ($runs | sort_by(.event // "none") | group_by(.event // "none")
        | map({event: (.[0].event // "none"), count: length})),
      by_branch: ($runs | sort_by(.head_branch // "none") | group_by(.head_branch // "none")
        | map({branch: (.[0].head_branch // "none"), count: length})),
      by_workflow: ($runs | sort_by(.name // "unknown") | group_by(.name // "unknown")
        | map({workflow: (.[0].name // "unknown"), count: length})),
      sample_failures: ($runs
        | map(select(.conclusion != "success"))
        | map({id, name, event, conclusion, status, head_branch, head_sha, created_at, html_url})
        | .[0:20])
    }
' "${raw_file}" > "${summary_file}"

jq -r '.workflow_runs | sort_by(.name // "unknown") | group_by(.name // "unknown")
  | map({workflow: (.[0].name // "unknown"), count: length})' "${raw_file}" > "${by_workflow_file}"

jq -r '.workflow_runs | sort_by(.head_branch // "none") | group_by(.head_branch // "none")
  | map({branch: (.[0].head_branch // "none"), count: length})' "${raw_file}" > "${by_branch_file}"

jq -r '.workflow_runs | sort_by(.event // "none") | group_by(.event // "none")
  | map({event: (.[0].event // "none"), count: length})' "${raw_file}" > "${by_event_file}"

jq -r '.workflow_runs | sort_by(.conclusion // "none") | group_by(.conclusion // "none")
  | map({conclusion: (.[0].conclusion // "none"), count: length})' "${raw_file}" > "${by_conclusion_file}"

jq -r '.workflow_runs | map(select(.conclusion != "success"))
  | map({id, name, event, conclusion, status, head_branch, head_sha, created_at, html_url})' "${raw_file}" > "${failures_file}"

log "Forensics outputs in ${OUTPUT_DIR}"
