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
CS_LOG_PREFIX="bot-wizard"

if [[ ! -t 0 ]]; then
  cs_die "Interactive wizard requires a TTY"
fi

cs_ui_header "Bot Setup Wizard (GitHub Apps + Gitea Evidence)"
cs_ui_note "All values can be placeholders. Secrets should be set only in local .env files."

BOT_NAME=$(cs_ui_prompt "Bot name" "ops-bot")
BOT_EMAIL=$(cs_ui_prompt "Bot email" "ops-bot@example.local")
GITEA_URL=$(cs_ui_prompt "Gitea base URL" "https://gitea.example.local")
GITEA_EVIDENCE_REPO=$(cs_ui_prompt "Gitea evidence repo (owner/repo)" "founders/evidence")
GITEA_EVIDENCE_USER=$(cs_ui_prompt "Gitea evidence user" "bot")
GITEA_REPO_OWNER=$(cs_ui_prompt "Gitea repo owner (target)" "founders")
GITEA_REPO_NAME=$(cs_ui_prompt "Gitea repo name (target)" "repo")

cs_ui_step "GitHub Apps placeholders"
GH_APP_COMPLIANCE=$(cs_ui_prompt "GitHub App name (compliance)" "ops-compliance-app")
GH_APP_SECURITY=$(cs_ui_prompt "GitHub App name (security)" "ops-security-app")
GH_APP_PRIVACY=$(cs_ui_prompt "GitHub App name (privacy)" "ops-privacy-app")
GH_APP_SUPPLY=$(cs_ui_prompt "GitHub App name (supplychain)" "ops-supplychain-app")

OUTPUT_DIR=$(cs_ui_prompt "Output dir for env files" "${SCRIPT_DIR}")
mkdir -p "${OUTPUT_DIR}"

REVIEW_ENV="${OUTPUT_DIR}/bot-review.env"
EVIDENCE_ENV="${OUTPUT_DIR}/bot-evidence.env"

cs_ui_step "Writing env files"
cat <<EOF > "${REVIEW_ENV}"
PLATFORM="github"
BOT_NAME="${BOT_NAME}"
BOT_ACTION="comment"
DRY_RUN="true"
ALLOW_BOT_APPROVE="NO"
HITL_APPROVE=""
REVIEW_BODY="Automated advisory review. Evidence stored in Gitea (private)."
REVIEW_EVENT="COMMENT"
GITHUB_TOKEN=""
REPO_SLUG="owner/repo"
PR_NUMBER=""
GITEA_URL="${GITEA_URL}"
GITEA_TOKEN=""
REPO_OWNER="${GITEA_REPO_OWNER}"
REPO_NAME="${GITEA_REPO_NAME}"
PR_INDEX=""
EVIDENCE_DIR="outputs/bot-evidence"
EOF
chmod 600 "${REVIEW_ENV}"

cat <<EOF > "${EVIDENCE_ENV}"
DRY_RUN="true"
EVIDENCE_SOURCE_DIR="outputs/ci-evidence"
EVIDENCE_SUBDIR=""
EVIDENCE_COMMIT_MESSAGE="chore(evidence): publish bot evidence"
GITEA_URL="${GITEA_URL}"
GITEA_EVIDENCE_REPO="${GITEA_EVIDENCE_REPO}"
GITEA_EVIDENCE_USER="${GITEA_EVIDENCE_USER}"
GITEA_EVIDENCE_TOKEN=""
BOT_NAME="${BOT_NAME}"
BOT_EMAIL="${BOT_EMAIL}"
EOF
chmod 600 "${EVIDENCE_ENV}"

cs_ui_ok "Created ${REVIEW_ENV}"
cs_ui_ok "Created ${EVIDENCE_ENV}"

cs_ui_step "Next steps (manual)"
cat <<EOF
GitHub Apps (placeholders):
  - ${GH_APP_COMPLIANCE}
  - ${GH_APP_SECURITY}
  - ${GH_APP_PRIVACY}
  - ${GH_APP_SUPPLY}

Required secrets in GitHub repo/org:
  - GITEA_URL
  - GITEA_TOKEN
  - GITEA_EVIDENCE_TOKEN
  - GITEA_EVIDENCE_REPO (placeholder ok)
  - GITEA_EVIDENCE_USER

Required vars in GitHub repo/org:
  - GITEA_REPO_OWNER
  - GITEA_REPO_NAME

Run workflow: .github/workflows/bot-review.yml
EOF
