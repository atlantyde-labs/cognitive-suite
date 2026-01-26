#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-}"
if [[ -z "${CONFIG_PATH}" ]]; then
  echo "Usage: $0 /path/to/deploy-all-secret-suite.env" >&2
  exit 1
fi
if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "Config not found: ${CONFIG_PATH}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${CONFIG_PATH}"

log() {
  echo "[secret-suite] $*"
}

fail() {
  echo "[secret-suite] ERROR: $*" >&2
  exit 1
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root_dir=$(cd "${script_dir}/../.." && pwd)

LOCAL_FIRST=${LOCAL_FIRST:-"true"}
ALLOW_EXTERNAL=${ALLOW_EXTERNAL:-"false"}

RUN_DEPLOY_GITEA=${RUN_DEPLOY_GITEA:-"false"}
RUN_HARDEN=${RUN_HARDEN:-"false"}
RUN_COMPLIANCE_LABELS=${RUN_COMPLIANCE_LABELS:-"false"}
RUN_REPO_TYPE_LABELS=${RUN_REPO_TYPE_LABELS:-"false"}
RUN_VALIDATE_SSO_MFA=${RUN_VALIDATE_SSO_MFA:-"false"}
RUN_COMPLIANCE_REPORT=${RUN_COMPLIANCE_REPORT:-"false"}

RUN_GITHUB_BOOTSTRAP=${RUN_GITHUB_BOOTSTRAP:-"false"}
RUN_GITHUB_SYNC=${RUN_GITHUB_SYNC:-"false"}
RUN_GITHUB_EXPORT=${RUN_GITHUB_EXPORT:-"false"}
RUN_GITHUB_IMPORT=${RUN_GITHUB_IMPORT:-"false"}

RUN_GITLAB_BOOTSTRAP=${RUN_GITLAB_BOOTSTRAP:-"false"}
RUN_GITLAB_SYNC=${RUN_GITLAB_SYNC:-"false"}

RUN_VALIDATE_USER_MAP=${RUN_VALIDATE_USER_MAP:-"false"}
RUN_SECRETS=${RUN_SECRETS:-"false"}

GITEA_LXC_ENV=${GITEA_LXC_ENV:-""}
HARDEN_ENV=${HARDEN_ENV:-""}
COMPLIANCE_LABELS_ENV=${COMPLIANCE_LABELS_ENV:-""}
REPO_TYPE_ENV=${REPO_TYPE_ENV:-""}
SSO_MFA_ENV=${SSO_MFA_ENV:-""}
COMPLIANCE_REPORT_ENV=${COMPLIANCE_REPORT_ENV:-""}

GITHUB_ENV=${GITHUB_ENV:-""}
GITHUB_IMPORT_ENV=${GITHUB_IMPORT_ENV:-""}
GITLAB_ENV=${GITLAB_ENV:-""}
USER_MAP_VALIDATE_ENV=${USER_MAP_VALIDATE_ENV:-""}
SECRETS_ENV=${SECRETS_ENV:-""}

require_file() {
  local path=$1
  if [[ -z "${path}" || ! -f "${path}" ]]; then
    fail "Required env file not found: ${path}"
  fi
}

get_env_value() {
  local env_file=$1
  local var=$2
  bash -c "set -a; source \"${env_file}\"; eval \"echo \\\"\${${var}:-}\\\"\"" 2>/dev/null
}

is_private_host() {
  local host=$1
  case "${host}" in
    localhost|127.*|10.*|192.168.*) return 0 ;;
    172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) return 0 ;;
    *.local|*.lan|*.internal) return 0 ;;
    *) return 1 ;;
  esac
}

check_local_url() {
  local label=$1
  local url=$2
  if [[ -z "${url}" ]]; then
    return
  fi
  local host
  host=${url#*://}
  host=${host%%/*}
  host=${host%%:*}

  if ! is_private_host "${host}"; then
    if [[ "${ALLOW_EXTERNAL}" != "true" ]]; then
      fail "${label} not local/private: ${url}. Set ALLOW_EXTERNAL=true to override."
    fi
  fi
}

require_external_allowed() {
  local label=$1
  if [[ "${LOCAL_FIRST}" == "true" && "${ALLOW_EXTERNAL}" != "true" ]]; then
    fail "${label} requires external access. Set ALLOW_EXTERNAL=true if intended."
  fi
}

run_script() {
  local script=$1
  local env_file=$2
  log "Running ${script}"
  if [[ -n "${env_file}" ]]; then
    "${script}" "${env_file}"
  else
    "${script}"
  fi
}

# Local-first URL checks for Gitea/SSO/MFA endpoints
if [[ "${LOCAL_FIRST}" == "true" ]]; then
  if [[ -n "${COMPLIANCE_REPORT_ENV}" && -f "${COMPLIANCE_REPORT_ENV}" ]]; then
    gitea_url=$(get_env_value "${COMPLIANCE_REPORT_ENV}" GITEA_URL)
    sso_url=$(get_env_value "${COMPLIANCE_REPORT_ENV}" SSO_STATUS_ENDPOINT)
    mfa_url=$(get_env_value "${COMPLIANCE_REPORT_ENV}" MFA_STATUS_ENDPOINT)
    check_local_url "GITEA_URL" "${gitea_url}"
    check_local_url "SSO_STATUS_ENDPOINT" "${sso_url}"
    check_local_url "MFA_STATUS_ENDPOINT" "${mfa_url}"
  fi

  if [[ -n "${SSO_MFA_ENV}" && -f "${SSO_MFA_ENV}" ]]; then
    sso_url=$(get_env_value "${SSO_MFA_ENV}" SSO_STATUS_ENDPOINT)
    mfa_url=$(get_env_value "${SSO_MFA_ENV}" MFA_STATUS_ENDPOINT)
    check_local_url "SSO_STATUS_ENDPOINT" "${sso_url}"
    check_local_url "MFA_STATUS_ENDPOINT" "${mfa_url}"
  fi
fi

# Deploy Gitea on Proxmox LXC
if [[ "${RUN_DEPLOY_GITEA}" == "true" ]]; then
  require_file "${GITEA_LXC_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/proxmox/deploy-gitea-lxc.sh" "${GITEA_LXC_ENV}"
fi

# Hardening
if [[ "${RUN_HARDEN}" == "true" ]]; then
  require_file "${HARDEN_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/compliance/gitea-hardening.sh" "${HARDEN_ENV}"
fi

# Compliance labels/milestones
if [[ "${RUN_COMPLIANCE_LABELS}" == "true" ]]; then
  require_file "${COMPLIANCE_LABELS_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/compliance/create-compliance-labels-milestones.sh" "${COMPLIANCE_LABELS_ENV}"
fi

# Repo type labels/milestones
if [[ "${RUN_REPO_TYPE_LABELS}" == "true" ]]; then
  require_file "${REPO_TYPE_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/compliance/repo-type-labels-milestones.sh" "${REPO_TYPE_ENV}"
fi

# Validate SSO/MFA API
if [[ "${RUN_VALIDATE_SSO_MFA}" == "true" ]]; then
  require_file "${SSO_MFA_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/compliance/validate-sso-mfa-api.sh" "${SSO_MFA_ENV}"
fi

# Compliance report
if [[ "${RUN_COMPLIANCE_REPORT}" == "true" ]]; then
  require_file "${COMPLIANCE_REPORT_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/compliance/eu-compliance-report.sh" "${COMPLIANCE_REPORT_ENV}"
fi

# GitHub migrations (external)
if [[ "${RUN_GITHUB_BOOTSTRAP}" == "true" ]]; then
  require_external_allowed "GitHub bootstrap"
  require_file "${GITHUB_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/migrations/github-to-gitea-bootstrap.sh" "${GITHUB_ENV}"
fi

if [[ "${RUN_GITHUB_SYNC}" == "true" ]]; then
  require_external_allowed "GitHub sync"
  require_file "${GITHUB_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/migrations/github-to-gitea-sync.sh" "${GITHUB_ENV}"
fi

if [[ "${RUN_GITHUB_EXPORT}" == "true" ]]; then
  require_external_allowed "GitHub export issues/PRs"
  require_file "${GITHUB_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/migrations/github-issues-prs-export.sh" "${GITHUB_ENV}"
fi

if [[ "${RUN_GITHUB_IMPORT}" == "true" ]]; then
  require_file "${GITHUB_IMPORT_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/migrations/github-to-gitea-import-issues-prs.sh" "${GITHUB_IMPORT_ENV}"
fi

# GitLab migrations (external)
if [[ "${RUN_GITLAB_BOOTSTRAP}" == "true" ]]; then
  require_external_allowed "GitLab bootstrap"
  require_file "${GITLAB_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/migrations/gitlab-to-gitea-bootstrap.sh" "${GITLAB_ENV}"
fi

if [[ "${RUN_GITLAB_SYNC}" == "true" ]]; then
  require_external_allowed "GitLab sync"
  require_file "${GITLAB_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/migrations/gitlab-to-gitea-sync.sh" "${GITLAB_ENV}"
fi

# Validate user map
if [[ "${RUN_VALIDATE_USER_MAP}" == "true" ]]; then
  require_file "${USER_MAP_VALIDATE_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/platforms/migrations/validate-gitea-user-map.sh" "${USER_MAP_VALIDATE_ENV}"
fi

# Secrets rehydration
if [[ "${RUN_SECRETS}" == "true" ]]; then
  require_file "${SECRETS_ENV}"
  run_script "${root_dir}/bash/GitDevSecDataAIOps/tooling/secrets/rehydrate-secrets.sh" "${SECRETS_ENV}"
fi

log "All requested steps completed."
