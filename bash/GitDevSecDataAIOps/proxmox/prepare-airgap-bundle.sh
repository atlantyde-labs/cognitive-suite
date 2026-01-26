#!/usr/bin/env bash
set -euo pipefail
umask 077

LOG_PREFIX="[prepare-airgap]"

log() {
  echo "${LOG_PREFIX} $*"
}

fail() {
  echo "${LOG_PREFIX} ERROR: $*" >&2
  exit 1
}

CONFIG_PATH="${1:-}"
if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    fail "Config not found: ${CONFIG_PATH}"
  fi
  # shellcheck disable=SC1090
  source "${CONFIG_PATH}"
fi

SOURCE_DIR=${SOURCE_DIR:-""}
OUTPUT_DIR=${OUTPUT_DIR:-""}
MANIFEST_NAME=${MANIFEST_NAME:-"SHA256SUMS"}
SIGNATURE_NAME=${SIGNATURE_NAME:-"SHA256SUMS.sig"}
SIGNATURE_TOOL=${SIGNATURE_TOOL:-"cosign"}
COPY_REPO=${COPY_REPO:-"false"}
SYNC_MODE=${SYNC_MODE:-"rsync"}
RSYNC_ARGS=${RSYNC_ARGS:-"-a --delete"}

COSIGN_KEY=${COSIGN_KEY:-""}
COSIGN_PUB=${COSIGN_PUB:-""}
GENERATE_COSIGN_KEYS=${GENERATE_COSIGN_KEYS:-"false"}

GPG_KEYID=${GPG_KEYID:-""}
GPG_HOMEDIR=${GPG_HOMEDIR:-""}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

if [[ -z "${SOURCE_DIR}" || -z "${OUTPUT_DIR}" ]]; then
  fail "SOURCE_DIR and OUTPUT_DIR are required"
fi

if [[ ! -d "${SOURCE_DIR}" ]]; then
  fail "SOURCE_DIR not found: ${SOURCE_DIR}"
fi

mkdir -p "${OUTPUT_DIR}"

if [[ "${COPY_REPO}" == "true" ]]; then
  if [[ "${SYNC_MODE}" == "rsync" ]]; then
    require_cmd rsync
    log "Syncing repo to ${OUTPUT_DIR}"
    # shellcheck disable=SC2086
    rsync ${RSYNC_ARGS} "${SOURCE_DIR}/" "${OUTPUT_DIR}/"
  elif [[ "${SYNC_MODE}" == "tar" ]]; then
    require_cmd tar
    log "Syncing repo to ${OUTPUT_DIR} via tar"
    tar -C "${SOURCE_DIR}" -cf - . | tar -C "${OUTPUT_DIR}" -xf -
  else
    fail "Unsupported SYNC_MODE: ${SYNC_MODE}"
  fi
fi

log "Generating manifest ${MANIFEST_NAME}"
(
  cd "${SOURCE_DIR}"
  find . -type f -not -path './.git/*' -print0 | sort -z | xargs -0 sha256sum > "${OUTPUT_DIR}/${MANIFEST_NAME}"
)

case "${SIGNATURE_TOOL}" in
  cosign)
    require_cmd cosign
    if [[ -z "${COSIGN_KEY}" || -z "${COSIGN_PUB}" ]]; then
      if [[ "${GENERATE_COSIGN_KEYS}" == "true" ]]; then
        log "Generating cosign key pair"
        cosign generate-key-pair
        COSIGN_KEY="${SOURCE_DIR}/cosign.key"
        COSIGN_PUB="${SOURCE_DIR}/cosign.pub"
      else
        fail "COSIGN_KEY and COSIGN_PUB are required for cosign"
      fi
    fi
    log "Signing manifest with cosign"
    cosign sign-blob --key "${COSIGN_KEY}" --output-signature "${OUTPUT_DIR}/${SIGNATURE_NAME}" "${OUTPUT_DIR}/${MANIFEST_NAME}"
    cp "${COSIGN_PUB}" "${OUTPUT_DIR}/cosign.pub"
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "${OUTPUT_DIR}/cosign.pub" | awk '{print $1}' > "${OUTPUT_DIR}/cosign.pub.sha256"
    elif command -v shasum >/dev/null 2>&1; then
      shasum -a 256 "${OUTPUT_DIR}/cosign.pub" | awk '{print $1}' > "${OUTPUT_DIR}/cosign.pub.sha256"
    fi
    ;;
  gpg)
    require_cmd gpg
    log "Signing manifest with gpg"
    if [[ -n "${GPG_HOMEDIR}" ]]; then
      GNUPGHOME="${GPG_HOMEDIR}" gpg --batch --output "${OUTPUT_DIR}/${SIGNATURE_NAME}" --detach-sign "${OUTPUT_DIR}/${MANIFEST_NAME}"
      if [[ -n "${GPG_KEYID}" ]]; then
        GNUPGHOME="${GPG_HOMEDIR}" gpg --armor --export "${GPG_KEYID}" > "${OUTPUT_DIR}/gpg.pub"
        GNUPGHOME="${GPG_HOMEDIR}" gpg --fingerprint "${GPG_KEYID}" > "${OUTPUT_DIR}/gpg.fingerprint"
      fi
    else
      gpg --batch --output "${OUTPUT_DIR}/${SIGNATURE_NAME}" --detach-sign "${OUTPUT_DIR}/${MANIFEST_NAME}"
      if [[ -n "${GPG_KEYID}" ]]; then
        gpg --armor --export "${GPG_KEYID}" > "${OUTPUT_DIR}/gpg.pub"
        gpg --fingerprint "${GPG_KEYID}" > "${OUTPUT_DIR}/gpg.fingerprint"
      fi
    fi
    ;;
  *)
    fail "Unsupported SIGNATURE_TOOL: ${SIGNATURE_TOOL}"
    ;;
esac

log "Bundle ready in ${OUTPUT_DIR}"
