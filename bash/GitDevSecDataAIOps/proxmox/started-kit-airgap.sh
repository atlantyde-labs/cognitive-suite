#!/usr/bin/env bash
set -euo pipefail
umask 077

LOG_PREFIX="[started-kit-airgap]"

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
DEST_DIR=${DEST_DIR:-"${HOME}/cognitive-suite"}
RUN_BOOTSTRAP=${RUN_BOOTSTRAP:-"true"}
BOOTSTRAP_ENV=${BOOTSTRAP_ENV:-"${DEST_DIR}/bash/GitDevSecDataAIOps/proxmox/bootstrap.env"}
BOOTSTRAP_PATH=${BOOTSTRAP_PATH:-"${DEST_DIR}/bash/GitDevSecDataAIOps/proxmox/bootstrap.sh"}
SYNC_MODE=${SYNC_MODE:-"rsync"}
RSYNC_ARGS=${RSYNC_ARGS:-"-a --delete"}
HASH_MANIFEST=${HASH_MANIFEST:-""}
HASH_REQUIRED=${HASH_REQUIRED:-"false"}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
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

verify_hashes

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
