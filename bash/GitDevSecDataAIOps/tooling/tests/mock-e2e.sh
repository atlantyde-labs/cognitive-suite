#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)
TMP_DIR=$(mktemp -d)
MOCK_BIN="${TMP_DIR}/mock-bin"
mkdir -p "${MOCK_BIN}"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

write_stub() {
  local name=$1
  local path="${MOCK_BIN}/${name}"
  cat <<'EOF' > "${path}"
#!/usr/bin/env bash
set -euo pipefail
EOF
  cat >> "${path}"
  chmod +x "${path}"
}

write_stub apt-get <<'EOF'
echo "[mock] apt-get $*" >&2
exit 0
EOF

write_stub systemctl <<'EOF'
if [[ "$1" == "is-active" ]]; then
  exit 0
fi
exit 0
EOF

write_stub systemd-inhibit <<'EOF'
last="${@: -1}"
if [[ "${last}" == "infinity" ]]; then
  sleep 0.1
else
  sleep "${last}"
fi
EOF

write_stub curl <<'EOF'
method="GET"
url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --request)
      method="$2"
      shift 2
      continue
      ;;
    --get)
      method="GET"
      shift
      continue
      ;;
    http*)
      url="$1"
      ;;
  esac
  shift
done

if [[ "${url}" == *"/storage/"*"/content"* ]]; then
  cat <<JSON
{"data":[{"volid":"local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst","name":"debian-12-standard_12.2-1_amd64.tar.zst"}]}
JSON
  exit 0
fi

if [[ "${url}" == *"/lxc" ]] && [[ "${method}" == "GET" ]]; then
  echo "{\"data\":[]}"
  exit 0
fi

echo "{\"data\":{}}"
EOF

write_stub docker <<'EOF'
case "${1:-}" in
  ps)
    exit 0
    ;;
  run)
    exit 0
    ;;
  rm)
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF

write_stub cosign <<'EOF'
case "${1:-}" in
  sign-blob)
    out=""
    shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --output-signature)
          out="$2"
          shift 2
          ;;
        --key)
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    if [[ -z "${out}" ]]; then
      echo "[mock] missing output signature" >&2
      exit 1
    fi
    echo "mock-signature" > "${out}"
    ;;
  verify-blob)
    exit 0
    ;;
  generate-key-pair)
    echo "mockkey" > cosign.key
    echo "mockpub" > cosign.pub
    ;;
  *)
    exit 0
    ;;
esac
EOF

write_stub gpg <<'EOF'
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      out="$2"
      shift 2
      ;;
    --detach-sign)
      shift
      ;;
    --verify)
      shift
      ;;
    --armor|--batch|--status-fd=1)
      shift
      ;;
    *)
      shift
      ;;
  esac
done
if [[ -n "${out}" ]]; then
  echo "mock-gpg" > "${out}"
fi
exit 0
EOF

write_stub ssh <<'EOF'
args=("$@")
cmd=""
idx=0
while [[ ${idx} -lt ${#args[@]} ]]; do
  arg="${args[$idx]}"
  case "${arg}" in
    -p|-i|-o)
      idx=$((idx + 2))
      continue
      ;;
    -*)
      idx=$((idx + 1))
      continue
      ;;
    *)
      idx=$((idx + 1))
      break
      ;;
  esac
done
if [[ ${idx} -lt ${#args[@]} ]]; then
  cmd="${args[*]:$idx}"
fi
if [[ -n "${cmd}" ]]; then
  bash -c "${cmd}"
else
  cat >/dev/null
fi
EOF

export PATH="${MOCK_BIN}:${PATH}"

echo "[mock-e2e] temp=${TMP_DIR}"

if command -v git >/dev/null 2>&1 && [[ "$(id -u)" -eq 0 ]]; then
  git config --global --add safe.directory "${ROOT_DIR}" >/dev/null 2>&1 || true
fi

EXECUTED_SCRIPTS=()

record_script() {
  EXECUTED_SCRIPTS+=("$1")
}

run_script() {
  local script=$1
  shift
  record_script "${script}"
  bash "${script}" "$@"
}

# Reboot guard scripts
RG_ENV="${TMP_DIR}/reboot-guard.env"
cat <<EOF > "${RG_ENV}"
RG_OVERRIDE_FILE="${TMP_DIR}/allow"
RG_OVERRIDE_TTL="1"
RG_AUDIT_LOG="${TMP_DIR}/audit.log"
RG_WINDOW_DAYS="Sun"
RG_WINDOW_START="00:00"
RG_WINDOW_END="23:59"
RG_CHECK_INTERVAL="1"
EOF

run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/platforms/ops-systems/allow-reboot-now.sh" "${RG_ENV}"
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/platforms/ops-systems/reboot-guard-status.sh" "${RG_ENV}"
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/platforms/ops-systems/close-reboot-override.sh" "${RG_ENV}"
record_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/platforms/ops-systems/reboot-guard.sh"
ENV_FILE="${RG_ENV}" timeout 2 bash "${ROOT_DIR}/bash/GitDevSecDataAIOps/platforms/ops-systems/reboot-guard.sh" || true
record_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/platforms/ops-systems/install-reboot-guard.sh"
DRY_RUN=true bash "${ROOT_DIR}/bash/GitDevSecDataAIOps/platforms/ops-systems/install-reboot-guard.sh" "${RG_ENV}"

# Proxmox API deploy (dry-run)
API_ENV="${TMP_DIR}/gitea-api.env"
cat <<EOF > "${API_ENV}"
PVE_API_URL="https://mock/pve"
PVE_API_TOKEN="token"
PVE_INSECURE="true"
PVE_NODE="pve"
PVE_STORAGE="local"
PVE_TEMPLATE="local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
GITEA_CTID="9000"
GITEA_HOSTNAME="gitea"
DRY_RUN="true"
BOOTSTRAP_SSH="true"
BOOTSTRAP_SSH_HOST="127.0.0.1"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/deploy-gitea-lxc-api.sh" "${API_ENV}"

# Proxmox API client (smoke)
record_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/pve-api-client.sh"
bash "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/pve-api-client.sh" "${API_ENV}" GET /nodes >/dev/null

# Orchestrator dry-run with minimal suite env
SUITE_ENV="${TMP_DIR}/suite.env"
cat <<EOF > "${SUITE_ENV}"
LOCAL_FIRST="true"
ALLOW_EXTERNAL="false"
DRY_RUN="true"
DRY_RUN_REPORT="true"
DRY_RUN_REPORT_PATH="${TMP_DIR}/dry-run-report.json"
RUN_DEPLOY_GITEA="false"
RUN_HARDEN="false"
RUN_COMPLIANCE_LABELS="false"
RUN_REPO_TYPE_LABELS="false"
RUN_VALIDATE_SSO_MFA="false"
RUN_COMPLIANCE_REPORT="false"
RUN_GITHUB_BOOTSTRAP="false"
RUN_GITHUB_SYNC="false"
RUN_GITHUB_EXPORT="false"
RUN_GITHUB_IMPORT="false"
RUN_GITLAB_BOOTSTRAP="false"
RUN_GITLAB_SYNC="false"
RUN_VALIDATE_USER_MAP="false"
RUN_SECRETS="false"
RUN_REBOOT_GUARD="false"
EOF

run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/deploy-all-secret-suite.sh" "${SUITE_ENV}"

# Bootstrap (dry-run)
BOOTSTRAP_ENV="${TMP_DIR}/bootstrap.env"
cat <<EOF > "${BOOTSTRAP_ENV}"
REPO_DIR="${ROOT_DIR}"
SUITE_ENV="${SUITE_ENV}"
COPY_EXAMPLES="false"
FIX_PERMS="false"
CHECK_PLACEHOLDERS="false"
APPLY="false"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/bootstrap.sh" "${BOOTSTRAP_ENV}"

# Started-kit deployments (local clone)
if ! git -C "${ROOT_DIR}" show-ref --verify --quiet refs/heads/chore/scripts-testing; then
  git -C "${ROOT_DIR}" branch -f chore/scripts-testing HEAD
fi
STARTED_ENV="${TMP_DIR}/started-kit.env"
cat <<EOF > "${STARTED_ENV}"
REPO_URL="${ROOT_DIR}"
BRANCH="chore/scripts-testing"
DEST_DIR="${TMP_DIR}/clone"
USE_GH="false"
RUN_BOOTSTRAP="false"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/started-kit-deployments-cli-ops.sh" "${STARTED_ENV}"

# Prepare air-gap bundle + verify
AIRGAP_DIR="${TMP_DIR}/airgap"
mkdir -p "${AIRGAP_DIR}"
echo "fixture" > "${AIRGAP_DIR}/fixture.txt"
echo "mockpub" > "${AIRGAP_DIR}/cosign.pub"
echo "mockkey" > "${AIRGAP_DIR}/cosign.key"

PREP_ENV="${TMP_DIR}/prepare-airgap.env"
cat <<EOF > "${PREP_ENV}"
SOURCE_DIR="${AIRGAP_DIR}"
OUTPUT_DIR="${AIRGAP_DIR}"
SIGNATURE_TOOL="cosign"
COPY_REPO="false"
COSIGN_KEY="${AIRGAP_DIR}/cosign.key"
COSIGN_PUB="${AIRGAP_DIR}/cosign.pub"
GENERATE_COSIGN_KEYS="false"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/prepare-airgap-bundle.sh" "${PREP_ENV}"

COSIGN_HASH=$(sha256sum "${AIRGAP_DIR}/cosign.pub" | awk '{print $1}')
AIRGAP_ENV="${TMP_DIR}/started-airgap.env"
cat <<EOF > "${AIRGAP_ENV}"
SOURCE_DIR="${AIRGAP_DIR}"
DEST_DIR="${TMP_DIR}/airgap-dest"
RUN_BOOTSTRAP="false"
SYNC_MODE="tar"
HASH_MANIFEST="SHA256SUMS"
HASH_REQUIRED="true"
SIGNATURE_FILE="SHA256SUMS.sig"
SIGNATURE_REQUIRED="true"
SIGNATURE_TOOL="cosign"
COSIGN_PUBLIC_KEY="${AIRGAP_DIR}/cosign.pub"
COSIGN_PUBLIC_KEY_HASH="${COSIGN_HASH}"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/started-kit-airgap.sh" "${AIRGAP_ENV}"

# Ops state machine (local, mocked)
record_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/tooling/ops-state/ops-state-machine.sh"
OPS_STATE_ENV="${TMP_DIR}/ops-state.env"
cat <<EOF > "${OPS_STATE_ENV}"
REPO_DIR="${ROOT_DIR}"
OUTPUT_DIR="${TMP_DIR}/ops-state"
REQUIRE_CLEAN_GIT="false"
REQUIRE_GITLEAKS="false"
REQUIRE_DETECT_SECRETS="false"
HITL_REQUIRED="false"
REQUIRE_APPROVALS="false"
RUN_ORCHESTRATOR_DRY_RUN="false"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/tooling/ops-state/ops-state-machine.sh" "${OPS_STATE_ENV}"

# Gitea runner scripts (dry-run)
RUNNER_ENV="${TMP_DIR}/runner.env"
cat <<EOF > "${RUNNER_ENV}"
GITEA_INSTANCE_URL="http://gitea.local"
RUNNER_TOKEN="token"
DRY_RUN="true"
EOF

record_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/install-gitea-runner.sh"
bash "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/install-gitea-runner.sh" "${RUNNER_ENV}"

record_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/gitea-runner-service.sh"
ENV_FILE="${RUNNER_ENV}" DRY_RUN=true bash "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/gitea-runner-service.sh" start

record_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/install-gitea-runner-systemd.sh"
DRY_RUN=true bash "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/install-gitea-runner-systemd.sh" "${RUNNER_ENV}"

AIRGAP_SAFE_ENV="${TMP_DIR}/airgap-safe.env"
cat <<EOF > "${AIRGAP_SAFE_ENV}"
DRY_RUN="true"
ENABLE_REBOOT_GUARD="false"
PREPARE_AIRGAP="false"
APPLY_AIRGAP="false"
PRE_PUBLISH_CHECKS="false"
SYNC_PUBLIC="false"
HITL_REQUIRED="false"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/airgap-safe-ops.sh" "${AIRGAP_SAFE_ENV}"

# Proxmox secrets wizard (non-interactive, dry-run)
WIZARD_ENV="${TMP_DIR}/wizard.env"
cat <<EOF > "${WIZARD_ENV}"
INTERACTIVE="false"
DRY_RUN="true"
OUTPUT_DIR="${TMP_DIR}/wizard-secrets"
WRITE_PVE_API_ENV="true"
WRITE_GITEA_ONBOARD_ENV="true"
WRITE_BOT_EVIDENCE_ENV="true"
COPY_CONTRIBUTORS_EXAMPLE="true"
PVE_API_TOKEN="token"
GITEA_TOKEN="token"
GITEA_EVIDENCE_TOKEN="token"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/proxmox/proxmox-local-secrets-wizard.sh" "${WIZARD_ENV}"

# Gitea model repo lockdown (dry-run)
LOCK_ENV="${TMP_DIR}/gitea-lock.env"
cat <<EOF > "${LOCK_ENV}"
GITEA_URL="http://gitea.local"
GITEA_TOKEN="token"
OWNER="founders"
REPOS="models-private"
FOUNDERS="founder1,founder2,founder3"
DRY_RUN="true"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/tooling/secrets/gitea-model-repo-lockdown.sh" "${LOCK_ENV}"

# Gitea contributor onboarding (dry-run)
CONTRIB_CSV="${TMP_DIR}/contributors.csv"
cat <<EOF > "${CONTRIB_CSV}"
username,email,full_name,ssh_key
contrib1,contrib1@example.com,Contributor One,ssh-ed25519 AAAAC3NzExampleKey1
contrib2,contrib2@example.com,Contributor Two,ssh-ed25519 AAAAC3NzExampleKey2
EOF

ONBOARD_ENV="${TMP_DIR}/onboard.env"
cat <<EOF > "${ONBOARD_ENV}"
GITEA_URL="http://gitea.local"
GITEA_TOKEN="token"
ORG="founders"
USERS_CSV="${CONTRIB_CSV}"
GENERATE_PASSWORDS="true"
PASSWORD_OUTPUT="${TMP_DIR}/passwords.csv"
DRY_RUN="true"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/tooling/secrets/gitea-onboard-contributors.sh" "${ONBOARD_ENV}"

# Bot review (dry-run)
BOT_REVIEW_ENV="${TMP_DIR}/bot-review.env"
cat <<EOF > "${BOT_REVIEW_ENV}"
PLATFORM="gitea"
BOT_NAME="ops-bot"
BOT_ACTION="comment"
DRY_RUN="true"
GITEA_URL="http://gitea.local"
GITEA_TOKEN="token"
REPO_OWNER="founders"
REPO_NAME="repo"
PR_INDEX="1"
EVIDENCE_DIR="${TMP_DIR}/bot-evidence"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/tooling/bots/bot-review.sh" "${BOT_REVIEW_ENV}"

# Bot evidence publish (dry-run)
BOT_EVIDENCE_ENV="${TMP_DIR}/bot-evidence.env"
cat <<EOF > "${BOT_EVIDENCE_ENV}"
DRY_RUN="true"
EVIDENCE_SOURCE_DIR="${TMP_DIR}/bot-evidence"
GITEA_URL="http://gitea.local"
GITEA_EVIDENCE_REPO="founders/evidence"
GITEA_EVIDENCE_USER="bot"
GITEA_EVIDENCE_TOKEN="token"
BOT_NAME="ops-bot"
BOT_EMAIL="ops-bot@example.local"
EOF
run_script "${ROOT_DIR}/bash/GitDevSecDataAIOps/tooling/bots/bot-evidence-publish.sh" "${BOT_EVIDENCE_ENV}"

if [[ -n "${EVIDENCE_DIR:-}" ]]; then
  mkdir -p "${EVIDENCE_DIR}"
  printf '%s\n' "${EXECUTED_SCRIPTS[@]}" | sort -u > "${EVIDENCE_DIR}/mock-e2e-scripts.txt"
  EVIDENCE_DIR="${EVIDENCE_DIR}" python3 - <<'PY' > "${EVIDENCE_DIR}/mock-e2e-hashes.json"
import json
import os

paths = []
with open(os.path.join(os.environ["EVIDENCE_DIR"], "mock-e2e-scripts.txt"), "r", encoding="utf-8") as fh:
    paths = [line.strip() for line in fh if line.strip()]

def sha256(path):
    import hashlib
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

payload = {"scripts":[{"path": p, "sha256": sha256(p)} for p in paths if os.path.exists(p)]}
print(json.dumps(payload, ensure_ascii=True, indent=2))
PY
fi

echo "[mock-e2e] complete"
