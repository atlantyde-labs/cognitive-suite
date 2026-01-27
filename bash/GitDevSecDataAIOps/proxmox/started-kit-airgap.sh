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
CS_LOG_PREFIX="started-kit-airgap"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/proxmox/started-kit-airgap.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

SOURCE_DIR=${SOURCE_DIR:-""}
DEST_DIR=${DEST_DIR:-"${HOME}/cognitive-suite"}
RUN_BOOTSTRAP=${RUN_BOOTSTRAP:-"true"}
BOOTSTRAP_ENV=${BOOTSTRAP_ENV:-"${DEST_DIR}/bash/GitDevSecDataAIOps/proxmox/bootstrap.env"}
BOOTSTRAP_PATH=${BOOTSTRAP_PATH:-"${DEST_DIR}/bash/GitDevSecDataAIOps/proxmox/bootstrap.sh"}
SYNC_MODE=${SYNC_MODE:-"rsync"}
RSYNC_ARGS=${RSYNC_ARGS:-"-a --delete"}
HASH_MANIFEST=${HASH_MANIFEST:-""}
HASH_REQUIRED=${HASH_REQUIRED:-"false"}
SIGNATURE_FILE=${SIGNATURE_FILE:-""}
SIGNATURE_REQUIRED=${SIGNATURE_REQUIRED:-"false"}
SIGNATURE_TOOL=${SIGNATURE_TOOL:-""}
COSIGN_PUBLIC_KEY=${COSIGN_PUBLIC_KEY:-""}
COSIGN_PUBLIC_KEY_HASH=${COSIGN_PUBLIC_KEY_HASH:-""}
GPG_HOMEDIR=${GPG_HOMEDIR:-""}
GPG_FINGERPRINT=${GPG_FINGERPRINT:-""}

require_cmd() {
  cs_require_cmd "$1"
}

if [[ -z "${SOURCE_DIR}" ]]; then
  fail "SOURCE_DIR is required for air-gapped install"
fi

if [[ ! -d "${SOURCE_DIR}" ]]; then
  fail "SOURCE_DIR not found: ${SOURCE_DIR}"
fi

if [[ "${SYNC_MODE}" == "rsync" ]]; then
  require_cmd rsync
  log "Syncing from ${SOURCE_DIR} to ${DEST_DIR} via rsync"
  # shellcheck disable=SC2086
  rsync ${RSYNC_ARGS} "${SOURCE_DIR}/" "${DEST_DIR}/"
elif [[ "${SYNC_MODE}" == "tar" ]]; then
  require_cmd tar
  log "Syncing from ${SOURCE_DIR} to ${DEST_DIR} via tar"
  mkdir -p "${DEST_DIR}"
  tar -C "${SOURCE_DIR}" -cf - . | tar -C "${DEST_DIR}" -xf -
else
  fail "Unsupported SYNC_MODE: ${SYNC_MODE}"
fi

verify_hashes() {
  if [[ -z "${HASH_MANIFEST}" ]]; then
    if [[ "${HASH_REQUIRED}" == "true" ]]; then
      fail "HASH_MANIFEST is required but not set"
    fi
    log "Hash manifest not configured; skipping integrity check"
    return
  fi

  local manifest_path="${HASH_MANIFEST}"
  if [[ "${HASH_MANIFEST}" != /* ]]; then
    manifest_path="${SOURCE_DIR}/${HASH_MANIFEST}"
  fi

  if [[ ! -f "${manifest_path}" ]]; then
    fail "Hash manifest not found: ${manifest_path}"
  fi

  case "${manifest_path}" in
    "${SOURCE_DIR}"/*) ;;
    *) fail "Hash manifest must live under SOURCE_DIR" ;;
  esac

  local manifest_rel="${manifest_path#"${SOURCE_DIR}"/}"
  log "Verifying hash manifest ${manifest_rel}"

  if command -v sha256sum >/dev/null 2>&1; then
    (cd "${SOURCE_DIR}" && sha256sum -c "${manifest_rel}")
  elif command -v shasum >/dev/null 2>&1; then
    (cd "${SOURCE_DIR}" && shasum -a 256 -c "${manifest_rel}")
  else
    fail "No sha256 tool found (sha256sum or shasum required)"
  fi
}

verify_signature() {
  if [[ -z "${SIGNATURE_FILE}" ]]; then
    if [[ "${SIGNATURE_REQUIRED}" == "true" ]]; then
      fail "SIGNATURE_FILE is required but not set"
    fi
    log "Signature file not configured; skipping signature check"
    return
  fi

  if [[ -z "${HASH_MANIFEST}" ]]; then
    fail "HASH_MANIFEST is required to verify signatures"
  fi

  local manifest_path="${HASH_MANIFEST}"
  if [[ "${HASH_MANIFEST}" != /* ]]; then
    manifest_path="${SOURCE_DIR}/${HASH_MANIFEST}"
  fi

  local sig_path="${SIGNATURE_FILE}"
  if [[ "${SIGNATURE_FILE}" != /* ]]; then
    sig_path="${SOURCE_DIR}/${SIGNATURE_FILE}"
  fi

  if [[ ! -f "${sig_path}" ]]; then
    fail "Signature file not found: ${sig_path}"
  fi

  case "${sig_path}" in
    "${SOURCE_DIR}"/*) ;;
    *) fail "Signature file must live under SOURCE_DIR" ;;
  esac

  local tool="${SIGNATURE_TOOL}"
  if [[ -z "${tool}" ]]; then
    if command -v cosign >/dev/null 2>&1 && [[ -n "${COSIGN_PUBLIC_KEY}" ]]; then
      tool="cosign"
    elif command -v gpg >/dev/null 2>&1; then
      tool="gpg"
    else
      if [[ "${SIGNATURE_REQUIRED}" == "true" ]]; then
        fail "No signature tool available (cosign or gpg)"
      fi
      log "No signature tool available; skipping signature check"
      return
    fi
  fi

  case "${tool}" in
    cosign)
      require_cmd cosign
      if [[ -z "${COSIGN_PUBLIC_KEY}" ]]; then
        fail "COSIGN_PUBLIC_KEY is required for cosign verification"
      fi
      if [[ -n "${COSIGN_PUBLIC_KEY_HASH}" ]]; then
        local key_hash=""
        if command -v sha256sum >/dev/null 2>&1; then
          key_hash=$(sha256sum "${COSIGN_PUBLIC_KEY}" | awk '{print $1}')
        elif command -v shasum >/dev/null 2>&1; then
          key_hash=$(shasum -a 256 "${COSIGN_PUBLIC_KEY}" | awk '{print $1}')
        else
          fail "No sha256 tool found to verify COSIGN_PUBLIC_KEY_HASH"
        fi
        if [[ "${key_hash}" != "${COSIGN_PUBLIC_KEY_HASH}" ]]; then
          fail "COSIGN_PUBLIC_KEY_HASH mismatch"
        fi
      fi
      log "Verifying signature with cosign"
      cosign verify-blob --key "${COSIGN_PUBLIC_KEY}" --signature "${sig_path}" "${manifest_path}"
      ;;
    gpg)
      require_cmd gpg
      log "Verifying signature with gpg"
      if [[ -n "${GPG_HOMEDIR}" ]]; then
        GNUPGHOME="${GPG_HOMEDIR}" gpg --batch --verify "${sig_path}" "${manifest_path}"
        if [[ -n "${GPG_FINGERPRINT}" ]]; then
          GNUPGHOME="${GPG_HOMEDIR}" gpg --batch --status-fd=1 --verify "${sig_path}" "${manifest_path}" 2>/dev/null \
            | grep -q "VALIDSIG ${GPG_FINGERPRINT}" || fail "GPG fingerprint mismatch"
        fi
      else
        gpg --batch --verify "${sig_path}" "${manifest_path}"
        if [[ -n "${GPG_FINGERPRINT}" ]]; then
          gpg --batch --status-fd=1 --verify "${sig_path}" "${manifest_path}" 2>/dev/null \
            | grep -q "VALIDSIG ${GPG_FINGERPRINT}" || fail "GPG fingerprint mismatch"
        fi
      fi
      ;;
    *)
      fail "Unsupported SIGNATURE_TOOL: ${tool}"
      ;;
  esac
}

verify_hashes
verify_signature

if [[ "${RUN_BOOTSTRAP}" == "true" ]]; then
  if [[ ! -x "${BOOTSTRAP_PATH}" ]]; then
    fail "Bootstrap not found at ${BOOTSTRAP_PATH}"
  fi
  if [[ ! -f "${BOOTSTRAP_ENV}" && -f "${BOOTSTRAP_ENV}.example" ]]; then
    install -m 0600 "${BOOTSTRAP_ENV}.example" "${BOOTSTRAP_ENV}"
    log "Created ${BOOTSTRAP_ENV} from ${BOOTSTRAP_ENV}.example"
  fi
  if [[ -f "${BOOTSTRAP_ENV}" ]]; then
    log "Running bootstrap with ${BOOTSTRAP_ENV}"
    bash "${BOOTSTRAP_PATH}" "${BOOTSTRAP_ENV}"
  else
    log "Running bootstrap without config (using defaults)"
    bash "${BOOTSTRAP_PATH}"
  fi
else
  log "Bootstrap disabled (RUN_BOOTSTRAP=false)"
fi
