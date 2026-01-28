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
CS_LOG_PREFIX="bot-evidence"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/tooling/bots/bot-evidence.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

DRY_RUN=${DRY_RUN:-"true"}
EVIDENCE_SOURCE_DIR=${EVIDENCE_SOURCE_DIR:-""}
EVIDENCE_SUBDIR=${EVIDENCE_SUBDIR:-""}
EVIDENCE_COMMIT_MESSAGE=${EVIDENCE_COMMIT_MESSAGE:-"chore(evidence): publish bot evidence"}
INTERACTIVE=${INTERACTIVE:-"false"}

GITEA_URL=${GITEA_URL:-""}
GITEA_EVIDENCE_REPO=${GITEA_EVIDENCE_REPO:-"founders/evidence"} # placeholder
GITEA_EVIDENCE_USER=${GITEA_EVIDENCE_USER:-"bot"}
GITEA_EVIDENCE_TOKEN=${GITEA_EVIDENCE_TOKEN:-""}

require_cmd() {
  cs_require_cmd "$1"
}

require_cmd git
require_cmd rsync
require_cmd date

if [[ "${INTERACTIVE}" == "true" ]]; then
  if [[ ! -t 0 ]]; then
    cs_die "INTERACTIVE=true requires a TTY"
  fi
  cs_ui_header "Bot Evidence Publisher"
  DRY_RUN=$(cs_ui_prompt "DRY_RUN (true|false)" "${DRY_RUN}")
  EVIDENCE_SOURCE_DIR=$(cs_ui_prompt "Evidence source dir" "${EVIDENCE_SOURCE_DIR:-outputs/ci-evidence}")
  GITEA_URL=$(cs_ui_prompt "Gitea URL" "${GITEA_URL:-}")
  GITEA_EVIDENCE_REPO=$(cs_ui_prompt "Evidence repo (owner/repo)" "${GITEA_EVIDENCE_REPO}")
  GITEA_EVIDENCE_USER=$(cs_ui_prompt "Evidence user" "${GITEA_EVIDENCE_USER}")
  cs_ui_note "Set GITEA_EVIDENCE_TOKEN via env or .env file before running in non-dry-run."
fi

if [[ -z "${EVIDENCE_SOURCE_DIR}" || ! -d "${EVIDENCE_SOURCE_DIR}" ]]; then
  cs_die "EVIDENCE_SOURCE_DIR not found"
fi
if [[ -z "${GITEA_URL}" || -z "${GITEA_EVIDENCE_TOKEN}" ]]; then
  cs_die "GITEA_URL and GITEA_EVIDENCE_TOKEN are required"
fi

timestamp=$(date -u +%Y%m%d)
if [[ -z "${EVIDENCE_SUBDIR}" ]]; then
  EVIDENCE_SUBDIR="runs/${timestamp}"
fi

tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

askpass="${tmp_dir}/askpass.sh"
cat <<EOF > "${askpass}"
#!/usr/bin/env bash
prompt="\$1"
case "\${prompt}" in
  *Username*|*username*)
    echo "${GITEA_EVIDENCE_USER}"
    ;;
  *)
    echo "${GITEA_EVIDENCE_TOKEN}"
    ;;
esac
EOF
chmod 700 "${askpass}"

repo_url="${GITEA_URL}/${GITEA_EVIDENCE_REPO}.git"
clone_dir="${tmp_dir}/repo"

if [[ "${DRY_RUN}" == "true" ]]; then
  cs_log "[dry-run] would clone ${repo_url}"
else
  GIT_TERMINAL_PROMPT=0 GIT_ASKPASS="${askpass}" git clone "${repo_url}" "${clone_dir}"
fi

dest_dir="${clone_dir}/${EVIDENCE_SUBDIR}"

if [[ "${DRY_RUN}" == "true" ]]; then
  cs_log "[dry-run] would copy ${EVIDENCE_SOURCE_DIR} -> ${dest_dir}"
else
  mkdir -p "${dest_dir}"
  rsync -a "${EVIDENCE_SOURCE_DIR}/" "${dest_dir}/"
  git -C "${clone_dir}" add "${EVIDENCE_SUBDIR}"
  if git -C "${clone_dir}" diff --cached --quiet; then
    cs_log "No evidence changes to commit."
    exit 0
  fi
  git -C "${clone_dir}" -c user.name="${BOT_NAME:-ops-bot}" -c user.email="${BOT_EMAIL:-ops-bot@example.local}" \
    commit -m "${EVIDENCE_COMMIT_MESSAGE}"
  GIT_TERMINAL_PROMPT=0 GIT_ASKPASS="${askpass}" git -C "${clone_dir}" push origin HEAD
fi

cs_log "Evidence publish complete"
