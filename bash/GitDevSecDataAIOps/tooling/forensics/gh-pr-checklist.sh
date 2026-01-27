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
CS_LOG_PREFIX="gh-pr-checklist"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/tooling/forensics/gh-pr-checklist.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

REPO=${REPO:-"${GITHUB_REPOSITORY:-}"}
PR_NUMBER=${PR_NUMBER:-""}
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
OUTPUT_DIR=${OUTPUT_DIR:-"./outputs/ci-evidence/pr-checklist"}
PER_PAGE=${PER_PAGE:-"100"}
PAGES=${PAGES:-"2"}
INTERACTIVE=${INTERACTIVE:-"true"}

require_cmd() {
  cs_require_cmd "$1"
}

require_cmd jq
require_cmd curl
require_cmd python3

if [[ -z "${REPO}" ]]; then
  fail "REPO is required (owner/repo)"
fi
if [[ -z "${PR_NUMBER}" ]]; then
  fail "PR_NUMBER is required"
fi

mkdir -p "${OUTPUT_DIR}"

if [[ "${INTERACTIVE}" == "true" ]]; then
  cs_ui_header "GitHub PR Checklist Forensics"
  cs_ui_note "Repo: ${REPO}"
  cs_ui_note "PR: ${PR_NUMBER}"
  if [[ -z "${GITHUB_TOKEN}" ]]; then
    cs_ui_note "GITHUB_TOKEN not set; public API only (rate-limited)"
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

pr_json="${OUTPUT_DIR}/pr.json"
log "Fetching PR metadata"
api_get "https://api.github.com/repos/${REPO}/pulls/${PR_NUMBER}" > "${pr_json}"

milestone_number=$(jq -r '.milestone.number // empty' "${pr_json}")
issues_json="${OUTPUT_DIR}/milestone-issues.json"

if [[ -n "${milestone_number}" ]]; then
  log "Fetching milestone ${milestone_number} issues"
  pages=()
  for ((page=1; page<=PAGES; page++)); do
    url="https://api.github.com/repos/${REPO}/issues?milestone=${milestone_number}&state=all&per_page=${PER_PAGE}&page=${page}"
    page_file="${OUTPUT_DIR}/milestone-page-${page}.json"
    api_get "${url}" > "${page_file}"
    pages+=("${page_file}")
  done
  jq -s '[.[].[]]' "${pages[@]}" > "${issues_json}"
fi

summary_json="${OUTPUT_DIR}/summary.json"
summary_jsonl="${OUTPUT_DIR}/summary.jsonl"

export PR_JSON="${pr_json}"
export SUMMARY_JSON="${summary_json}"
export SUMMARY_JSONL="${summary_jsonl}"
if [[ -f "${issues_json}" ]]; then
  export ISSUES_JSON="${issues_json}"
else
  export ISSUES_JSON=""
fi

python3 - <<'PY'
import json
import os
import re
from datetime import datetime, timezone

pr_path = os.environ['PR_JSON']
issues_path = os.environ.get('ISSUES_JSON')

with open(pr_path, 'r', encoding='utf-8') as fh:
    pr = json.load(fh)

body = pr.get('body') or ''
checklist = []
for line in body.splitlines():
    match = re.match(r"^\s*[-*]\s+\[( |x|X)\]\s+(.*)$", line)
    if match:
        checked = match.group(1).lower() == 'x'
        checklist.append({"text": match.group(2).strip(), "checked": checked})

total_tasks = len(checklist)
done_tasks = sum(1 for item in checklist if item["checked"])

issues = []
if issues_path and os.path.exists(issues_path):
    with open(issues_path, 'r', encoding='utf-8') as fh:
        issues = json.load(fh)

milestone_total = len(issues)
closed = sum(1 for issue in issues if issue.get("state") == "closed")
open_issues = [
    {
        "number": issue.get("number"),
        "title": issue.get("title"),
        "html_url": issue.get("html_url"),
        "state": issue.get("state"),
    }
    for issue in issues
    if issue.get("state") != "closed"
]

status = "pass"
if total_tasks and done_tasks != total_tasks:
    status = "needs_attention"
if milestone_total and closed != milestone_total:
    status = "needs_attention"

summary = {
    "pr": {
        "number": pr.get("number"),
        "title": pr.get("title"),
        "state": pr.get("state"),
        "html_url": pr.get("html_url"),
    },
    "checklist": {
        "total": total_tasks,
        "done": done_tasks,
        "items": checklist,
    },
    "milestone": {
        "number": pr.get("milestone", {}).get("number"),
        "title": pr.get("milestone", {}).get("title"),
        "total_issues": milestone_total,
        "closed_issues": closed,
        "open_issues": open_issues,
    },
    "status": status,
    "generated_at": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
}

with open(os.environ['SUMMARY_JSON'], 'w', encoding='utf-8') as fh:
    json.dump(summary, fh, indent=2, ensure_ascii=True)

record = summary.copy()
record["record_id"] = f"pr-checklist-{pr.get('number')}-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}"
record["category"] = "pr-checklist"
with open(os.environ['SUMMARY_JSONL'], 'w', encoding='utf-8') as fh:
    fh.write(json.dumps(record, ensure_ascii=True) + "\n")
PY

log "Summary written to ${summary_json}"
log "JSONL written to ${summary_jsonl}"
