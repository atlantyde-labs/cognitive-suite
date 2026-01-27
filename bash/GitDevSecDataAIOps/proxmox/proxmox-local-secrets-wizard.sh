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
CS_LOG_PREFIX="proxmox-secrets-wizard"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/proxmox/proxmox-local-secrets-wizard.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

INTERACTIVE=${INTERACTIVE:-"true"}
DRY_RUN=${DRY_RUN:-"true"}

DEFAULT_OUTPUT_ROOT="./outputs/secrets"
if [[ "$(id -u)" -eq 0 ]]; then
  DEFAULT_OUTPUT_ROOT="/opt/cognitive-suite/secrets"
fi
OUTPUT_DIR=${OUTPUT_DIR:-"${DEFAULT_OUTPUT_ROOT}"}

WRITE_PVE_API_ENV=${WRITE_PVE_API_ENV:-"true"}
WRITE_GITEA_ONBOARD_ENV=${WRITE_GITEA_ONBOARD_ENV:-"true"}
WRITE_BOT_EVIDENCE_ENV=${WRITE_BOT_EVIDENCE_ENV:-"true"}
COPY_CONTRIBUTORS_EXAMPLE=${COPY_CONTRIBUTORS_EXAMPLE:-"true"}

EVIDENCE_DIR=${EVIDENCE_DIR:-""}

PVE_API_URL=${PVE_API_URL:-"https://127.0.0.1:8006/api2/json"}
PVE_API_TOKEN=${PVE_API_TOKEN:-""}
PVE_INSECURE=${PVE_INSECURE:-"true"}
PVE_DRY_RUN=${PVE_DRY_RUN:-"true"}

GITEA_URL=${GITEA_URL:-"https://gitea.example.com"}
GITEA_TOKEN=${GITEA_TOKEN:-""}
ORG=${ORG:-"founders-org"}
USERS_CSV=${USERS_CSV:-"${OUTPUT_DIR}/contributors.csv"}
DEFAULT_PASSWORD=${DEFAULT_PASSWORD:-""}
GENERATE_PASSWORDS=${GENERATE_PASSWORDS:-"true"}
PASSWORD_OUTPUT=${PASSWORD_OUTPUT:-"${OUTPUT_DIR}/contributors-passwords.csv"}
GITEA_DRY_RUN=${GITEA_DRY_RUN:-"true"}

ENFORCE_MUST_CHANGE_PASSWORD=${ENFORCE_MUST_CHANGE_PASSWORD:-"true"}
ADD_SSH_KEYS=${ADD_SSH_KEYS:-"true"}
ADD_ORG_MEMBERSHIP=${ADD_ORG_MEMBERSHIP:-"true"}

EVIDENCE_SOURCE_DIR=${EVIDENCE_SOURCE_DIR:-"outputs/ci-evidence"}
EVIDENCE_SUBDIR=${EVIDENCE_SUBDIR:-""}
EVIDENCE_COMMIT_MESSAGE=${EVIDENCE_COMMIT_MESSAGE:-"chore(evidence): publish bot evidence"}
GITEA_EVIDENCE_REPO=${GITEA_EVIDENCE_REPO:-"founders/evidence"}
GITEA_EVIDENCE_USER=${GITEA_EVIDENCE_USER:-"bot"}
GITEA_EVIDENCE_TOKEN=${GITEA_EVIDENCE_TOKEN:-""}
BOT_NAME=${BOT_NAME:-"ops-bot"}
BOT_EMAIL=${BOT_EMAIL:-"ops-bot@example.local"}
BOT_DRY_RUN=${BOT_DRY_RUN:-"true"}

require_root_if_apply() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    return 0
  fi
  if [[ ! -w "${OUTPUT_DIR}" ]]; then
    if [[ "$(id -u)" -ne 0 ]]; then
      fail "Run as root (sudo) or choose a writable OUTPUT_DIR"
    fi
  fi
}

ensure_output_dir() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would create ${OUTPUT_DIR}"
    return
  fi
  install -d -m 0700 "${OUTPUT_DIR}"
}

escape_value() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_kv() {
  local file=$1
  local key=$2
  local value=$3
  printf '%s="%s"\n' "${key}" "$(escape_value "${value}")" >> "${file}"
}

write_env_file() {
  local path=$1
  shift
  local -a lines=("$@")
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would write ${path}"
    return 0
  fi
  : > "${path}"
  chmod 600 "${path}"
  for line in "${lines[@]}"; do
    printf '%s\n' "${line}" >> "${path}"
  done
}

prompt_secret() {
  local label=$1
  local default=${2:-""}
  local value=""
  if [[ "${INTERACTIVE}" != "true" ]]; then
    printf '%s' "${default}"
    return
  fi
  cs_color "1;37"
  printf '%s: ' "${label}"
  cs_ui_reset
  read -r -s value
  printf '\n'
  if [[ -z "${value}" ]]; then
    value="${default}"
  fi
  printf '%s' "${value}"
}

write_evidence() {
  if [[ -z "${EVIDENCE_DIR}" ]]; then
    return 0
  fi
  mkdir -p "${EVIDENCE_DIR}"
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local record
  record=$(printf '{"timestamp":"%s","output_dir":"%s","dry_run":%s,"pve_env":%s,"gitea_onboard_env":%s,"bot_evidence_env":%s}' \
    "${timestamp}" \
    "$(escape_value "${OUTPUT_DIR}")" \
    "${DRY_RUN}" \
    "${WRITE_PVE_API_ENV}" \
    "${WRITE_GITEA_ONBOARD_ENV}" \
    "${WRITE_BOT_EVIDENCE_ENV}")
  printf '%s\n' "${record}" >> "${EVIDENCE_DIR}/proxmox-local-secrets-wizard.jsonl"
}

if [[ "${INTERACTIVE}" == "true" ]]; then
  cs_ui_header "Proxmox Local Secrets Wizard"
  cs_ui_note "DRY_RUN=${DRY_RUN}"
  cs_ui_note "OUTPUT_DIR=${OUTPUT_DIR}"
fi

if [[ "${INTERACTIVE}" == "true" ]]; then
  if cs_ui_confirm "Write PVE API env?" "Y"; then
    WRITE_PVE_API_ENV="true"
  else
    WRITE_PVE_API_ENV="false"
  fi
  if cs_ui_confirm "Write Gitea onboard env?" "Y"; then
    WRITE_GITEA_ONBOARD_ENV="true"
  else
    WRITE_GITEA_ONBOARD_ENV="false"
  fi
  if cs_ui_confirm "Write bot evidence env?" "Y"; then
    WRITE_BOT_EVIDENCE_ENV="true"
  else
    WRITE_BOT_EVIDENCE_ENV="false"
  fi
fi

require_root_if_apply
ensure_output_dir

if [[ "${WRITE_PVE_API_ENV}" == "true" ]]; then
  cs_ui_step "PVE API env"
  if [[ "${INTERACTIVE}" == "true" ]]; then
    PVE_API_URL=$(cs_ui_prompt "PVE API URL" "${PVE_API_URL}")
    PVE_API_TOKEN=$(prompt_secret "PVE API TOKEN" "${PVE_API_TOKEN}")
    PVE_INSECURE=$(cs_ui_prompt "PVE INSECURE (true/false)" "${PVE_INSECURE}")
    PVE_DRY_RUN=$(cs_ui_prompt "DRY_RUN" "${PVE_DRY_RUN}")
  fi
  PVE_ENV_PATH="${OUTPUT_DIR}/pve-api.env"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would write ${PVE_ENV_PATH}"
  else
    : > "${PVE_ENV_PATH}"
    chmod 600 "${PVE_ENV_PATH}"
    write_kv "${PVE_ENV_PATH}" "PVE_API_URL" "${PVE_API_URL}"
    write_kv "${PVE_ENV_PATH}" "PVE_API_TOKEN" "${PVE_API_TOKEN}"
    write_kv "${PVE_ENV_PATH}" "PVE_INSECURE" "${PVE_INSECURE}"
    write_kv "${PVE_ENV_PATH}" "DRY_RUN" "${PVE_DRY_RUN}"
    cs_ui_ok "Wrote ${PVE_ENV_PATH}"
  fi
fi

if [[ "${WRITE_GITEA_ONBOARD_ENV}" == "true" ]]; then
  cs_ui_step "Gitea onboard env"
  if [[ "${INTERACTIVE}" == "true" ]]; then
    GITEA_URL=$(cs_ui_prompt "Gitea URL" "${GITEA_URL}")
    GITEA_TOKEN=$(prompt_secret "Gitea token" "${GITEA_TOKEN}")
    ORG=$(cs_ui_prompt "Org" "${ORG}")
    USERS_CSV=$(cs_ui_prompt "Contributors CSV path" "${USERS_CSV}")
    if cs_ui_confirm "Generate passwords per user?" "Y"; then
      GENERATE_PASSWORDS="true"
      DEFAULT_PASSWORD=""
      PASSWORD_OUTPUT=$(cs_ui_prompt "Password output CSV" "${PASSWORD_OUTPUT}")
    else
      GENERATE_PASSWORDS="false"
      DEFAULT_PASSWORD=$(prompt_secret "Default password" "${DEFAULT_PASSWORD}")
    fi
    GITEA_DRY_RUN=$(cs_ui_prompt "DRY_RUN" "${GITEA_DRY_RUN}")
    ENFORCE_MUST_CHANGE_PASSWORD=$(cs_ui_prompt "Must change password" "${ENFORCE_MUST_CHANGE_PASSWORD}")
    ADD_SSH_KEYS=$(cs_ui_prompt "Add SSH keys" "${ADD_SSH_KEYS}")
    ADD_ORG_MEMBERSHIP=$(cs_ui_prompt "Add org membership" "${ADD_ORG_MEMBERSHIP}")
  fi
  ONBOARD_ENV_PATH="${OUTPUT_DIR}/gitea-onboard.env"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would write ${ONBOARD_ENV_PATH}"
  else
    : > "${ONBOARD_ENV_PATH}"
    chmod 600 "${ONBOARD_ENV_PATH}"
    write_kv "${ONBOARD_ENV_PATH}" "GITEA_URL" "${GITEA_URL}"
    write_kv "${ONBOARD_ENV_PATH}" "GITEA_TOKEN" "${GITEA_TOKEN}"
    write_kv "${ONBOARD_ENV_PATH}" "ORG" "${ORG}"
    write_kv "${ONBOARD_ENV_PATH}" "USERS_CSV" "${USERS_CSV}"
    write_kv "${ONBOARD_ENV_PATH}" "DEFAULT_PASSWORD" "${DEFAULT_PASSWORD}"
    write_kv "${ONBOARD_ENV_PATH}" "GENERATE_PASSWORDS" "${GENERATE_PASSWORDS}"
    write_kv "${ONBOARD_ENV_PATH}" "PASSWORD_OUTPUT" "${PASSWORD_OUTPUT}"
    write_kv "${ONBOARD_ENV_PATH}" "DRY_RUN" "${GITEA_DRY_RUN}"
    write_kv "${ONBOARD_ENV_PATH}" "ENFORCE_MUST_CHANGE_PASSWORD" "${ENFORCE_MUST_CHANGE_PASSWORD}"
    write_kv "${ONBOARD_ENV_PATH}" "ADD_SSH_KEYS" "${ADD_SSH_KEYS}"
    write_kv "${ONBOARD_ENV_PATH}" "ADD_ORG_MEMBERSHIP" "${ADD_ORG_MEMBERSHIP}"
    cs_ui_ok "Wrote ${ONBOARD_ENV_PATH}"
  fi

  if [[ "${COPY_CONTRIBUTORS_EXAMPLE}" == "true" ]]; then
    local_example="${CS_ROOT}/tooling/secrets/contributors.csv.example"
    if [[ -f "${local_example}" ]]; then
      if [[ "${DRY_RUN}" == "true" ]]; then
        log "[dry-run] would copy ${local_example} to ${USERS_CSV}"
      else
        install -d -m 0700 "$(dirname "${USERS_CSV}")"
        if [[ ! -f "${USERS_CSV}" ]]; then
          cp "${local_example}" "${USERS_CSV}"
          chmod 600 "${USERS_CSV}"
          cs_ui_ok "Copied example contributors CSV"
        fi
      fi
    fi
  fi
fi

if [[ "${WRITE_BOT_EVIDENCE_ENV}" == "true" ]]; then
  cs_ui_step "Bot evidence env"
  if [[ "${INTERACTIVE}" == "true" ]]; then
    EVIDENCE_SOURCE_DIR=$(cs_ui_prompt "Evidence source dir" "${EVIDENCE_SOURCE_DIR}")
    EVIDENCE_SUBDIR=$(cs_ui_prompt "Evidence subdir (optional)" "${EVIDENCE_SUBDIR}")
    EVIDENCE_COMMIT_MESSAGE=$(cs_ui_prompt "Evidence commit message" "${EVIDENCE_COMMIT_MESSAGE}")
    GITEA_URL=$(cs_ui_prompt "Gitea URL" "${GITEA_URL}")
    GITEA_EVIDENCE_REPO=$(cs_ui_prompt "Evidence repo" "${GITEA_EVIDENCE_REPO}")
    GITEA_EVIDENCE_USER=$(cs_ui_prompt "Evidence user" "${GITEA_EVIDENCE_USER}")
    GITEA_EVIDENCE_TOKEN=$(prompt_secret "Evidence token" "${GITEA_EVIDENCE_TOKEN}")
    BOT_NAME=$(cs_ui_prompt "Bot name" "${BOT_NAME}")
    BOT_EMAIL=$(cs_ui_prompt "Bot email" "${BOT_EMAIL}")
    BOT_DRY_RUN=$(cs_ui_prompt "DRY_RUN" "${BOT_DRY_RUN}")
  fi
  EVIDENCE_ENV_PATH="${OUTPUT_DIR}/bot-evidence.env"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would write ${EVIDENCE_ENV_PATH}"
  else
    : > "${EVIDENCE_ENV_PATH}"
    chmod 600 "${EVIDENCE_ENV_PATH}"
    write_kv "${EVIDENCE_ENV_PATH}" "DRY_RUN" "${BOT_DRY_RUN}"
    write_kv "${EVIDENCE_ENV_PATH}" "EVIDENCE_SOURCE_DIR" "${EVIDENCE_SOURCE_DIR}"
    write_kv "${EVIDENCE_ENV_PATH}" "EVIDENCE_SUBDIR" "${EVIDENCE_SUBDIR}"
    write_kv "${EVIDENCE_ENV_PATH}" "EVIDENCE_COMMIT_MESSAGE" "${EVIDENCE_COMMIT_MESSAGE}"
    write_kv "${EVIDENCE_ENV_PATH}" "GITEA_URL" "${GITEA_URL}"
    write_kv "${EVIDENCE_ENV_PATH}" "GITEA_EVIDENCE_REPO" "${GITEA_EVIDENCE_REPO}"
    write_kv "${EVIDENCE_ENV_PATH}" "GITEA_EVIDENCE_USER" "${GITEA_EVIDENCE_USER}"
    write_kv "${EVIDENCE_ENV_PATH}" "GITEA_EVIDENCE_TOKEN" "${GITEA_EVIDENCE_TOKEN}"
    write_kv "${EVIDENCE_ENV_PATH}" "BOT_NAME" "${BOT_NAME}"
    write_kv "${EVIDENCE_ENV_PATH}" "BOT_EMAIL" "${BOT_EMAIL}"
    cs_ui_ok "Wrote ${EVIDENCE_ENV_PATH}"
  fi
fi

write_evidence

cs_ui_ok "Wizard completed"
