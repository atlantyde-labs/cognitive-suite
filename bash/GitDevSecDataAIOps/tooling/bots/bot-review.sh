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
CS_LOG_PREFIX="bot-review"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/tooling/bots/bot-review.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

# Apply defaults after config loading so values from ENV files are not masked.
PLATFORM="${PLATFORM:-github}" # github|gitea
BOT_NAME="${BOT_NAME:-ops-bot}"
BOT_ACTION="${BOT_ACTION:-comment}" # comment|approve
DRY_RUN="${DRY_RUN:-true}"
INTERACTIVE="${INTERACTIVE:-false}"

ALLOW_BOT_APPROVE="${ALLOW_BOT_APPROVE:-NO}"
HITL_APPROVE="${HITL_APPROVE:-}"

REVIEW_BODY="${REVIEW_BODY:-Automated review (advisory). Evidence recorded.}"
REVIEW_EVENT="${REVIEW_EVENT:-COMMENT}" # COMMENT|APPROVE|REQUEST_CHANGES

EVIDENCE_DIR="${EVIDENCE_DIR:-}"
DECISION_ID="${DECISION_ID:-}"

GITHUB_TOKEN="${GITHUB_TOKEN:-}"
REPO_SLUG="${REPO_SLUG:-}"
PR_NUMBER="${PR_NUMBER:-}"
GITHUB_API_URL="${GITHUB_API_URL:-https://api.github.com}"

GITEA_URL="${GITEA_URL:-}"
GITEA_TOKEN="${GITEA_TOKEN:-}"
REPO_OWNER="${REPO_OWNER:-}"
REPO_NAME="${REPO_NAME:-}"
PR_INDEX="${PR_INDEX:-}"
GITEA_REVIEW_EVENT="${GITEA_REVIEW_EVENT:-APPROVED}" # APPROVED|COMMENT
GITEA_REVIEW_ENDPOINT="${GITEA_REVIEW_ENDPOINT:-}"

require_cmd() {
  cs_require_cmd "$1"
}

require_cmd curl
require_cmd jq
require_cmd date

if [[ "${INTERACTIVE}" == "true" ]]; then
  if [[ ! -t 0 ]]; then
    cs_die "INTERACTIVE=true requires a TTY"
  fi
  cs_ui_header "Bot Review"
  PLATFORM=$(cs_ui_prompt "Platform (github|gitea)" "${PLATFORM}")
  BOT_NAME=$(cs_ui_prompt "Bot name" "${BOT_NAME}")
  BOT_ACTION=$(cs_ui_prompt "Bot action (comment|approve)" "${BOT_ACTION}")
  DRY_RUN=$(cs_ui_prompt "DRY_RUN (true|false)" "${DRY_RUN}")
  if [[ "${PLATFORM}" == "github" ]]; then
    REPO_SLUG=$(cs_ui_prompt "GitHub repo (owner/repo)" "${REPO_SLUG:-owner/repo}")
    PR_NUMBER=$(cs_ui_prompt "PR number" "${PR_NUMBER:-}")
  else
    GITEA_URL=$(cs_ui_prompt "Gitea URL" "${GITEA_URL:-}")
    REPO_OWNER=$(cs_ui_prompt "Repo owner" "${REPO_OWNER:-}")
    REPO_NAME=$(cs_ui_prompt "Repo name" "${REPO_NAME:-}")
    PR_INDEX=$(cs_ui_prompt "PR index" "${PR_INDEX:-}")
  fi
fi

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [[ "${BOT_ACTION}" == "approve" ]]; then
  if [[ "${ALLOW_BOT_APPROVE}" != "YES" ]]; then
    cs_die "ALLOW_BOT_APPROVE=YES required for bot approval"
  fi
  if [[ "${HITL_APPROVE}" != "YES" ]]; then
    cs_die "HITL_APPROVE=YES required for bot approval"
  fi
  if [[ "${PLATFORM}" == "github" ]]; then
    REVIEW_EVENT="APPROVE"
  else
    GITEA_REVIEW_EVENT="APPROVED"
  fi
fi

write_decision() {
  if [[ -z "${EVIDENCE_DIR}" ]]; then
    return 0
  fi
  mkdir -p "${EVIDENCE_DIR}"
  local decision_file="${EVIDENCE_DIR}/bot-decision.json"
  local decision
  decision=$(jq -n \
    --arg timestamp "${timestamp}" \
    --arg bot "${BOT_NAME}" \
    --arg platform "${PLATFORM}" \
    --arg action "${BOT_ACTION}" \
    --arg event "${REVIEW_EVENT}" \
    --arg gitea_event "${GITEA_REVIEW_EVENT}" \
    --arg repo "${REPO_SLUG:-${REPO_OWNER}/${REPO_NAME}}" \
    --arg pr "${PR_NUMBER:-${PR_INDEX}}" \
    --arg decision_id "${DECISION_ID}" \
    --arg dry_run "${DRY_RUN}" \
    '{timestamp:$timestamp, bot:$bot, platform:$platform, action:$action, review_event:$event, gitea_event:$gitea_event, repo:$repo, pr:$pr, decision_id:$decision_id, dry_run: ($dry_run=="true")}'
  )
  echo "${decision}" > "${decision_file}"
}

review_github() {
  if [[ -z "${GITHUB_TOKEN}" || -z "${REPO_SLUG}" || -z "${PR_NUMBER}" ]]; then
    cs_die "GITHUB_TOKEN, REPO_SLUG, PR_NUMBER are required for GitHub"
  fi
  local url="${GITHUB_API_URL}/repos/${REPO_SLUG}/pulls/${PR_NUMBER}/reviews"
  local payload
  payload=$(jq -n --arg body "${REVIEW_BODY}" --arg event "${REVIEW_EVENT}" '{body:$body, event:$event}')
  if [[ "${DRY_RUN}" == "true" ]]; then
    cs_log "[dry-run] POST ${url} payload=${payload}"
    return 0
  fi
  curl -sS -o /tmp/bot-review.json -w '%{http_code}' \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    -X POST "${url}" \
    -d "${payload}" > /tmp/bot-review.status
  local status
  status=$(cat /tmp/bot-review.status)
  if [[ "${status}" != "200" && "${status}" != "201" ]]; then
    cs_die "GitHub review failed (HTTP ${status})"
  fi
}

review_gitea() {
  if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" || -z "${REPO_OWNER}" || -z "${REPO_NAME}" || -z "${PR_INDEX}" ]]; then
    cs_die "GITEA_URL, GITEA_TOKEN, REPO_OWNER, REPO_NAME, PR_INDEX are required for Gitea"
  fi
  local endpoint="${GITEA_REVIEW_ENDPOINT}"
  if [[ -z "${endpoint}" ]]; then
    endpoint="${GITEA_URL}/api/v1/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_INDEX}/reviews"
  fi
  local payload
  payload=$(jq -n --arg body "${REVIEW_BODY}" --arg event "${GITEA_REVIEW_EVENT}" '{body:$body, event:$event}')
  if [[ "${DRY_RUN}" == "true" ]]; then
    cs_log "[dry-run] POST ${endpoint} payload=${payload}"
    return 0
  fi
  curl -sS -o /tmp/gitea-review.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${endpoint}" \
    -d "${payload}" > /tmp/gitea-review.status
  local status
  status=$(cat /tmp/gitea-review.status)
  if [[ "${status}" != "200" && "${status}" != "201" ]]; then
    cs_die "Gitea review failed (HTTP ${status})"
  fi
}

write_decision

case "${PLATFORM}" in
  github)
    review_github
    ;;
  gitea)
    review_gitea
    ;;
  *)
    cs_die "Unsupported PLATFORM: ${PLATFORM}"
    ;;
esac

cs_log "Bot review complete (${PLATFORM}/${BOT_ACTION})"
