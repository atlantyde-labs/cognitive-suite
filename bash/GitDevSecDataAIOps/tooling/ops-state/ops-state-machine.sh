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
CS_LOG_PREFIX="ops-state"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/tooling/ops-state/ops-state-machine.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

REPO_DIR=${REPO_DIR:-"$(pwd)"}
OUTPUT_DIR=${OUTPUT_DIR:-"./outputs/ops-state"}
REQUIRE_CLEAN_GIT=${REQUIRE_CLEAN_GIT:-"true"}
REQUIRE_GITLEAKS=${REQUIRE_GITLEAKS:-"false"}
REQUIRE_DETECT_SECRETS=${REQUIRE_DETECT_SECRETS:-"false"}
HEALTHCHECK_URLS=${HEALTHCHECK_URLS:-""}
RUN_ORCHESTRATOR_DRY_RUN=${RUN_ORCHESTRATOR_DRY_RUN:-"false"}
ORCHESTRATOR_ENV=${ORCHESTRATOR_ENV:-""}

REQUIRE_APPROVALS=${REQUIRE_APPROVALS:-"true"}
REQUIRED_APPROVALS=${REQUIRED_APPROVALS:-"2"}
PR_NUMBER=${PR_NUMBER:-""}
REPO_SLUG=${REPO_SLUG:-"${GITHUB_REPOSITORY:-}"} # owner/repo
GITHUB_TOKEN=${GITHUB_TOKEN:-""}

HITL_REQUIRED=${HITL_REQUIRED:-"true"}
HITL_APPROVE=${HITL_APPROVE:-""}

FAIL_COUNT=0
CHECKS=()

record_check() {
  local name=$1
  local status=$2
  local detail=$3
  CHECKS+=("{\"name\":\"${name}\",\"status\":\"${status}\",\"detail\":\"${detail}\"}")
  if [[ "${status}" == "fail" ]]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

ensure_repo() {
  if [[ ! -d "${REPO_DIR}/.git" ]]; then
    record_check "repo" "fail" "not a git repo: ${REPO_DIR}"
    return 1
  fi
  record_check "repo" "pass" "${REPO_DIR}"
  return 0
}

check_clean_git() {
  if [[ "${REQUIRE_CLEAN_GIT}" != "true" ]]; then
    record_check "clean_git" "skip" "disabled"
    return 0
  fi
  if git -C "${REPO_DIR}" status --porcelain | grep -q .; then
    record_check "clean_git" "fail" "working tree not clean"
    return 1
  fi
  record_check "clean_git" "pass" "working tree clean"
}

check_gitleaks() {
  if [[ "${REQUIRE_GITLEAKS}" != "true" ]]; then
    record_check "gitleaks" "skip" "disabled"
    return 0
  fi
  if ! command -v gitleaks >/dev/null 2>&1; then
    record_check "gitleaks" "fail" "gitleaks not installed"
    return 1
  fi
  if gitleaks detect --source "${REPO_DIR}" --no-banner --redact >/dev/null 2>&1; then
    record_check "gitleaks" "pass" "no leaks"
  else
    record_check "gitleaks" "fail" "gitleaks detected issues"
  fi
}

check_detect_secrets() {
  if [[ "${REQUIRE_DETECT_SECRETS}" != "true" ]]; then
    record_check "detect_secrets" "skip" "disabled"
    return 0
  fi
  if ! command -v detect-secrets >/dev/null 2>&1; then
    record_check "detect_secrets" "fail" "detect-secrets not installed"
    return 1
  fi
  if detect-secrets scan --all-files "${REPO_DIR}" >/dev/null 2>&1; then
    record_check "detect_secrets" "pass" "scan complete"
  else
    record_check "detect_secrets" "fail" "scan failed"
  fi
}

check_health_urls() {
  if [[ -z "${HEALTHCHECK_URLS}" ]]; then
    record_check "healthcheck" "skip" "no urls"
    return 0
  fi
  local failed=0
  IFS=',' read -r -a urls <<< "${HEALTHCHECK_URLS}"
  for url in "${urls[@]}"; do
    url=$(echo "${url}" | xargs)
    if [[ -z "${url}" ]]; then
      continue
    fi
    if curl -fsS "${url}" >/dev/null 2>&1; then
      record_check "healthcheck:${url}" "pass" "ok"
    else
      record_check "healthcheck:${url}" "fail" "unreachable"
      failed=1
    fi
  done
  return "${failed}"
}

run_orchestrator() {
  if [[ "${RUN_ORCHESTRATOR_DRY_RUN}" != "true" ]]; then
    record_check "orchestrator_dry_run" "skip" "disabled"
    return 0
  fi
  if [[ -z "${ORCHESTRATOR_ENV}" || ! -f "${ORCHESTRATOR_ENV}" ]]; then
    record_check "orchestrator_dry_run" "fail" "missing env"
    return 1
  fi
  if env DRY_RUN=true bash "${REPO_DIR}/bash/GitDevSecDataAIOps/proxmox/deploy-all-secret-suite.sh" "${ORCHESTRATOR_ENV}"; then
    record_check "orchestrator_dry_run" "pass" "completed"
  else
    record_check "orchestrator_dry_run" "fail" "failed"
    return 1
  fi
}

check_pr_approvals() {
  if [[ "${REQUIRE_APPROVALS}" != "true" ]]; then
    record_check "pr_approvals" "skip" "disabled"
    return 0
  fi
  if [[ -z "${PR_NUMBER}" || -z "${REPO_SLUG}" || -z "${GITHUB_TOKEN}" ]]; then
    record_check "pr_approvals" "fail" "missing PR_NUMBER/REPO_SLUG/GITHUB_TOKEN"
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    record_check "pr_approvals" "fail" "jq not installed"
    return 1
  fi
  local api="https://api.github.com/repos/${REPO_SLUG}/pulls/${PR_NUMBER}/reviews?per_page=100"
  local approvals
  approvals=$(curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "${api}" \
    | jq -r '[.[] | select(.state=="APPROVED") | .user.login] | unique | length')
  if [[ "${approvals}" -ge "${REQUIRED_APPROVALS}" ]]; then
    record_check "pr_approvals" "pass" "approvals=${approvals}"
  else
    record_check "pr_approvals" "fail" "approvals=${approvals}"
    return 1
  fi
}

check_hitl() {
  if [[ "${HITL_REQUIRED}" != "true" ]]; then
    record_check "hitl" "skip" "disabled"
    return 0
  fi
  if [[ "${HITL_APPROVE}" == "YES" ]]; then
    record_check "hitl" "pass" "approved"
    return 0
  fi
  record_check "hitl" "fail" "HITL_APPROVE!=YES"
  return 1
}

write_summary() {
  mkdir -p "${OUTPUT_DIR}"
  local summary
  summary=$(CHECK_LINES="$(printf '%s\n' "${CHECKS[@]}")" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone

lines = [l.strip() for l in os.environ.get("CHECK_LINES", "").splitlines() if l.strip()]
checks = [json.loads(l) for l in lines]
payload = {
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "checks": checks,
    "failures": [c for c in checks if c.get("status") == "fail"],
}
print(json.dumps(payload, ensure_ascii=True, indent=2))
PY
  )
  echo "${summary}" > "${OUTPUT_DIR}/ops-state-summary.json"
  log "Summary written to ${OUTPUT_DIR}/ops-state-summary.json"
}

ensure_repo || true
check_clean_git || true
check_gitleaks || true
check_detect_secrets || true
check_health_urls || true
run_orchestrator || true
check_pr_approvals || true
check_hitl || true

write_summary

if [[ "${FAIL_COUNT}" -gt 0 ]]; then
  fail "State machine failed with ${FAIL_COUNT} errors"
fi

log "All checks passed"
