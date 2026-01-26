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
require_cmd jq

GITEA_APP_INI=${GITEA_APP_INI:-""}
GITEA_DATA_DIR=${GITEA_DATA_DIR:-""}
BACKUP_DIR=${BACKUP_DIR:-""}
GITEA_LXC_CTID=${GITEA_LXC_CTID:-""}

SSO_ENABLED=${SSO_ENABLED:-""}
MFA_ENFORCED=${MFA_ENFORCED:-""}
AUDIT_LOG_ENABLED=${AUDIT_LOG_ENABLED:-""}
RETENTION_DAYS=${RETENTION_DAYS:-""}
LOG_RETENTION_DAYS=${LOG_RETENTION_DAYS:-""}
BACKUP_TESTED=${BACKUP_TESTED:-""}
INCIDENT_RESPONSE_PLAN=${INCIDENT_RESPONSE_PLAN:-""}
VULN_MANAGEMENT=${VULN_MANAGEMENT:-""}
DATA_RESIDENCY_EU=${DATA_RESIDENCY_EU:-""}
THIRD_PARTY_RISK_ASSESSMENT=${THIRD_PARTY_RISK_ASSESSMENT:-""}
CHANGE_MANAGEMENT=${CHANGE_MANAGEMENT:-""}
ACCESS_REVIEWS=${ACCESS_REVIEWS:-""}
BACKUP_MAX_AGE_DAYS=${BACKUP_MAX_AGE_DAYS:-"2"}

COMPLIANCE_REPORT_PATH=${COMPLIANCE_REPORT_PATH:-""}

SSO_STATUS_ENDPOINT=${SSO_STATUS_ENDPOINT:-""}
MFA_STATUS_ENDPOINT=${MFA_STATUS_ENDPOINT:-""}
SSO_MFA_API_TOKEN=${SSO_MFA_API_TOKEN:-""}
SSO_MFA_API_HEADER=${SSO_MFA_API_HEADER:-"Authorization: Bearer ${SSO_MFA_API_TOKEN}"}
SSO_STATUS_JQ=${SSO_STATUS_JQ:-".sso_enabled // .enabled"}
MFA_STATUS_JQ=${MFA_STATUS_JQ:-".mfa_enforced // .enabled"}

if [[ -n "${GITEA_LXC_CTID}" ]]; then
  require_cmd pct
fi

run_cmd() {
  if [[ -n "${GITEA_LXC_CTID}" ]]; then
    pct exec "${GITEA_LXC_CTID}" -- bash -c "$1"
  else
    bash -c "$1"
  fi
}

get_app_ini_value() {
  local key=$1
  if [[ -z "${GITEA_APP_INI}" ]]; then
    echo ""
    return
  fi
  run_cmd "grep -E '^${key} *= *' '${GITEA_APP_INI}' 2>/dev/null | tail -n1 | awk -F= '{gsub(/^[ \t]+|[ \t]+$/,\"\",$2); print $2}'" || true
}

fetch_flag() {
  local endpoint=$1
  local filter=$2
  if [[ -z "${endpoint}" ]]; then
    echo ""
    return
  fi

  local header_args=()
  if [[ -n "${SSO_MFA_API_TOKEN}" ]]; then
    header_args=(-H "${SSO_MFA_API_HEADER}")
  fi

  local json
  if ! json=$(curl -fsSL "${header_args[@]}" "${endpoint}"); then
    echo ""
    return
  fi

  local value
  value=$(echo "${json}" | jq -r "${filter}" 2>/dev/null || true)
  if [[ "${value}" == "true" || "${value}" == "false" ]]; then
    echo "${value}"
  else
    echo ""
  fi
}

api_sso=$(fetch_flag "${SSO_STATUS_ENDPOINT}" "${SSO_STATUS_JQ}")
if [[ -n "${api_sso}" ]]; then
  SSO_ENABLED="${api_sso}"
fi

api_mfa=$(fetch_flag "${MFA_STATUS_ENDPOINT}" "${MFA_STATUS_JQ}")
if [[ -n "${api_mfa}" ]]; then
  MFA_ENFORCED="${api_mfa}"
fi

check_encryption_at_rest() {
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

check_tls() {
  local protocol root_url
  protocol=$(get_app_ini_value "PROTOCOL")
  root_url=$(get_app_ini_value "ROOT_URL")

  if [[ -n "${root_url}" ]]; then
    if echo "${root_url}" | grep -qi '^https://'; then
      echo "pass|ROOT_URL uses https"
      return
    fi
    if echo "${root_url}" | grep -qi '^http://'; then
      echo "fail|ROOT_URL uses http"
      return
    fi
  fi

  if [[ -n "${protocol}" ]]; then
    if [[ "${protocol}" == "https" ]]; then
      echo "pass|PROTOCOL=https"
    else
      echo "fail|PROTOCOL=${protocol}"
    fi
    return
  fi

  echo "unknown|no TLS settings found"
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

declared_check() {
  local name=$1
  local value=$2
  if [[ -z "${value}" ]]; then
    echo "unknown|${name} not declared"
    return
  fi
  if [[ "${value}" == "true" ]]; then
    echo "pass|${name}=true"
  else
    echo "fail|${name}=${value}"
  fi
}

numeric_check() {
  local name=$1
  local value=$2
  if [[ -z "${value}" ]]; then
    echo "unknown|${name} not set"
    return
  fi
  if [[ "${value}" =~ ^[0-9]+$ ]] && [[ "${value}" -gt 0 ]]; then
    echo "pass|${name}=${value}"
  else
    echo "fail|${name}=${value}"
  fi
}

emit_item() {
  local id=$1
  local title=$2
  local status=$3
  local detail=$4
  local frameworks=$5
  jq -n \
    --arg id "${id}" \
    --arg title "${title}" \
    --arg status "${status}" \
    --arg detail "${detail}" \
    --argjson frameworks "${frameworks}" \
    '{id: $id, title: $title, status: $status, detail: $detail, frameworks: $frameworks}'
}

now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

enc=$(check_encryption_at_rest)
enc_status=${enc%%|*}
enc_detail=${enc#*|}

tls=$(check_tls)
tls_status=${tls%%|*}
tls_detail=${tls#*|}

backup=$(check_backup_freshness)
backup_status=${backup%%|*}
backup_detail=${backup#*|}

sso=$(declared_check "sso_enabled" "${SSO_ENABLED}")
sso_status=${sso%%|*}
sso_detail=${sso#*|}

mfa=$(declared_check "mfa_enforced" "${MFA_ENFORCED}")
mfa_status=${mfa%%|*}
mfa_detail=${mfa#*|}

audit=$(declared_check "audit_log_enabled" "${AUDIT_LOG_ENABLED}")
audit_status=${audit%%|*}
audit_detail=${audit#*|}

retention=$(numeric_check "retention_days" "${RETENTION_DAYS}")
retention_status=${retention%%|*}
retention_detail=${retention#*|}

log_retention=$(numeric_check "log_retention_days" "${LOG_RETENTION_DAYS}")
log_retention_status=${log_retention%%|*}
log_retention_detail=${log_retention#*|}

backup_tested=$(declared_check "backup_tested" "${BACKUP_TESTED}")
backup_tested_status=${backup_tested%%|*}
backup_tested_detail=${backup_tested#*|}

incident=$(declared_check "incident_response_plan" "${INCIDENT_RESPONSE_PLAN}")
incident_status=${incident%%|*}
incident_detail=${incident#*|}

vuln=$(declared_check "vulnerability_management" "${VULN_MANAGEMENT}")
vuln_status=${vuln%%|*}
vuln_detail=${vuln#*|}

data_residency=$(declared_check "data_residency_eu" "${DATA_RESIDENCY_EU}")
data_residency_status=${data_residency%%|*}
data_residency_detail=${data_residency#*|}

third_party=$(declared_check "third_party_risk_assessment" "${THIRD_PARTY_RISK_ASSESSMENT}")
third_party_status=${third_party%%|*}
third_party_detail=${third_party#*|}

change_mgmt=$(declared_check "change_management" "${CHANGE_MANAGEMENT}")
change_mgmt_status=${change_mgmt%%|*}
change_mgmt_detail=${change_mgmt#*|}

access_reviews=$(declared_check "access_reviews" "${ACCESS_REVIEWS}")
access_reviews_status=${access_reviews%%|*}
access_reviews_detail=${access_reviews#*|}

items=()
items+=("$(emit_item "encryption_at_rest" "Encryption at rest" "${enc_status}" "${enc_detail}" '["GDPR Art32","ISO27001 A.8","NIS2","DORA"]')")
items+=("$(emit_item "encryption_in_transit" "Encryption in transit" "${tls_status}" "${tls_detail}" '["GDPR Art32","ISO27001 A.8","NIS2","DORA"]')")
items+=("$(emit_item "backup_freshness" "Backup freshness" "${backup_status}" "${backup_detail}" '["GDPR Art32","ISO27001 A.8/A.17","NIS2","DORA"]')")
items+=("$(emit_item "backup_testing" "Backup restore testing" "${backup_tested_status}" "${backup_tested_detail}" '["ISO27001 A.8/A.17","DORA"]')")
items+=("$(emit_item "sso" "SSO enforcement" "${sso_status}" "${sso_detail}" '["ISO27001 A.5","NIS2"]')")
items+=("$(emit_item "mfa" "MFA enforcement" "${mfa_status}" "${mfa_detail}" '["GDPR Art32","ISO27001 A.5","NIS2"]')")
items+=("$(emit_item "audit_logging" "Audit logging" "${audit_status}" "${audit_detail}" '["GDPR Art32","ISO27001 A.8","NIS2","DORA"]')")
items+=("$(emit_item "retention" "Data retention policy" "${retention_status}" "${retention_detail}" '["GDPR Art5(1)(e)","ISO27001 A.8"]')")
items+=("$(emit_item "log_retention" "Log retention policy" "${log_retention_status}" "${log_retention_detail}" '["ISO27001 A.8","NIS2"]')")
items+=("$(emit_item "incident_response" "Incident response plan" "${incident_status}" "${incident_detail}" '["NIS2","DORA","ISO27001 A.5"]')")
items+=("$(emit_item "vulnerability_mgmt" "Vulnerability management" "${vuln_status}" "${vuln_detail}" '["NIS2","DORA","ISO27001 A.8"]')")
items+=("$(emit_item "data_residency" "EU data residency" "${data_residency_status}" "${data_residency_detail}" '["GDPR"]')")
items+=("$(emit_item "third_party_risk" "Third-party risk assessment" "${third_party_status}" "${third_party_detail}" '["DORA","NIS2","ISO27001 A.5"]')")
items+=("$(emit_item "change_management" "Change management" "${change_mgmt_status}" "${change_mgmt_detail}" '["ISO27001 A.8","DORA"]')")
items+=("$(emit_item "access_reviews" "Access reviews" "${access_reviews_status}" "${access_reviews_detail}" '["ISO27001 A.5","NIS2"]')")

report=$(printf '%s\n' "${items[@]}" | jq -s --arg ts "${now}" '{timestamp: $ts, checks: .}')

echo "${report}"

if [[ -n "${COMPLIANCE_REPORT_PATH}" ]]; then
  echo "${report}" > "${COMPLIANCE_REPORT_PATH}"
  echo "Report written to ${COMPLIANCE_REPORT_PATH}"
fi
