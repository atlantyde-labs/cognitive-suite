#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-}"
if [[ -n "${CONFIG_PATH}" ]]; then
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    echo "Config not found: ${CONFIG_PATH}" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "${CONFIG_PATH}"
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd date
require_cmd awk

GITEA_APP_INI=${GITEA_APP_INI:-""}
GITEA_DATA_DIR=${GITEA_DATA_DIR:-""}
BACKUP_DIR=${BACKUP_DIR:-""}
GITEA_LXC_CTID=${GITEA_LXC_CTID:-""}

if [[ -n "${GITEA_LXC_CTID}" ]]; then
  require_cmd pct
fi

SSO_ENABLED=${SSO_ENABLED:-"false"}
MFA_ENFORCED=${MFA_ENFORCED:-"false"}
AUDIT_LOG_ENABLED=${AUDIT_LOG_ENABLED:-"false"}
RETENTION_DAYS=${RETENTION_DAYS:-""}
BACKUP_MAX_AGE_DAYS=${BACKUP_MAX_AGE_DAYS:-"2"}

COMPLIANCE_REPORT_PATH=${COMPLIANCE_REPORT_PATH:-""}

run_cmd() {
  if [[ -n "${GITEA_LXC_CTID}" ]]; then
    pct exec "${GITEA_LXC_CTID}" -- bash -c "$1"
  else
    bash -c "$1"
  fi
}

check_encryption() {
  if [[ -z "${GITEA_DATA_DIR}" ]]; then
    echo "unknown|GITEA_DATA_DIR not set"
    return
  fi
  local source
  source=$(run_cmd "findmnt -no SOURCE '${GITEA_DATA_DIR}' 2>/dev/null" || true)
  if [[ -z "${source}" ]]; then
    echo "unknown|mount source not detected"
    return
  fi
  if echo "${source}" | grep -q "/dev/mapper/"; then
    echo "pass|encrypted block device detected (${source})"
  else
    echo "unknown|unable to confirm encryption (${source})"
  fi
}

check_backup_freshness() {
  if [[ -z "${BACKUP_DIR}" ]]; then
    echo "unknown|BACKUP_DIR not set"
    return
  fi
  local newest
  newest=$(run_cmd "find '${BACKUP_DIR}' -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1" || true)
  if [[ -z "${newest}" ]]; then
    echo "fail|no backup files found"
    return
  fi
  local newest_ts
  newest_ts=$(echo "${newest}" | awk '{print $1}')
  local now_ts
  now_ts=$(date +%s)
  local age_days
  age_days=$(( (now_ts - ${newest_ts%.*}) / 86400 ))
  if [[ "${age_days}" -le "${BACKUP_MAX_AGE_DAYS}" ]]; then
    echo "pass|latest backup age ${age_days}d"
  else
    echo "fail|latest backup age ${age_days}d"
  fi
}

check_config_flag() {
  local key=$1
  local want=$2
  if [[ -z "${GITEA_APP_INI}" ]]; then
    echo "unknown|GITEA_APP_INI not set"
    return
  fi
  local value
  value=$(run_cmd "grep -E '^${key} *= *' '${GITEA_APP_INI}' 2>/dev/null | tail -n1 | awk -F= '{gsub(/ /,\"\",$2); print $2}'" || true)
  if [[ -z "${value}" ]]; then
    echo "unknown|${key} not found"
    return
  fi
  if [[ "${value}" == "${want}" ]]; then
    echo "pass|${key}=${value}"
  else
    echo "fail|${key}=${value}"
  fi
}

check_declared_flag() {
  local name=$1
  local value=$2
  if [[ -z "${value}" ]]; then
    echo "unknown|${name} not declared"
    return
  fi
  if [[ "${value}" == "true" ]]; then
    echo "pass|${name}=${value}"
  else
    echo "fail|${name}=${value}"
  fi
}

report_item() {
  local id=$1
  local status=$2
  local detail=$3
  printf '  {"id":"%s","status":"%s","detail":"%s"}' "${id}" "${status}" "${detail}"
}

now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

enc=$(check_encryption)
enc_status=${enc%%|*}
enc_detail=${enc#*|}

backup=$(check_backup_freshness)
backup_status=${backup%%|*}
backup_detail=${backup#*|}

sso=$(check_declared_flag "sso_enabled" "${SSO_ENABLED}")
sso_status=${sso%%|*}
sso_detail=${sso#*|}

mfa=$(check_declared_flag "mfa_enforced" "${MFA_ENFORCED}")
mfa_status=${mfa%%|*}
mfa_detail=${mfa#*|}

audit=$(check_declared_flag "audit_log_enabled" "${AUDIT_LOG_ENABLED}")
audit_status=${audit%%|*}
audit_detail=${audit#*|}

retention=$(check_declared_flag "retention_days" "${RETENTION_DAYS}")
retention_status=${retention%%|*}
retention_detail=${retention#*|}

cat <<JSON
{
  "timestamp": "${now}",
  "checks": [
$(report_item "encryption_at_rest" "${enc_status}" "${enc_detail}"),
$(report_item "backup_freshness" "${backup_status}" "${backup_detail}"),
$(report_item "sso" "${sso_status}" "${sso_detail}"),
$(report_item "mfa" "${mfa_status}" "${mfa_detail}"),
$(report_item "audit_logging" "${audit_status}" "${audit_detail}"),
$(report_item "retention" "${retention_status}" "${retention_detail}")
  ]
}
JSON

if [[ -n "${COMPLIANCE_REPORT_PATH}" ]]; then
  cat <<JSON > "${COMPLIANCE_REPORT_PATH}"
{
  "timestamp": "${now}",
  "checks": [
$(report_item "encryption_at_rest" "${enc_status}" "${enc_detail}"),
$(report_item "backup_freshness" "${backup_status}" "${backup_detail}"),
$(report_item "sso" "${sso_status}" "${sso_detail}"),
$(report_item "mfa" "${mfa_status}" "${mfa_detail}"),
$(report_item "audit_logging" "${audit_status}" "${audit_detail}"),
$(report_item "retention" "${retention_status}" "${retention_detail}")
  ]
}
JSON
  echo "Report written to ${COMPLIANCE_REPORT_PATH}"
fi
