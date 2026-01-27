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
CS_LOG_PREFIX="onboard-wizard"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/tooling/secrets/contributor-onboarding-wizard.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

INTERACTIVE=${INTERACTIVE:-"true"}
DRY_RUN=${DRY_RUN:-"true"}
OUTPUT_DIR=${OUTPUT_DIR:-"./outputs/secrets"}
CSV_PATH=${CSV_PATH:-"${OUTPUT_DIR}/contributors.csv"}
TAGS_JSONL_PATH=${TAGS_JSONL_PATH:-"${OUTPUT_DIR}/contributors-tags.jsonl"}
TAGS_CSV_PATH=${TAGS_CSV_PATH:-"${OUTPUT_DIR}/contributors-tags.csv"}
SEED_PLACEHOLDER=${SEED_PLACEHOLDER:-"true"}
EVIDENCE_DIR=${EVIDENCE_DIR:-""}

DEFAULT_ROLE=${DEFAULT_ROLE:-"contributor"}
DEFAULT_DOMAIN=${DEFAULT_DOMAIN:-"infra"}
DEFAULT_ACCESS=${DEFAULT_ACCESS:-"internal"}
DEFAULT_TRUST=${DEFAULT_TRUST:-"tier1"}
DEFAULT_BEHAVIOR_TAGS=${DEFAULT_BEHAVIOR_TAGS:-"onboarding"}
DEFAULT_RISK=${DEFAULT_RISK:-"low"}
DEFAULT_MFA=${DEFAULT_MFA:-"true"}
DEFAULT_SSO=${DEFAULT_SSO:-"true"}
DEFAULT_HITL=${DEFAULT_HITL:-"false"}

require_root_if_apply() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    return 0
  fi
  local dir
  dir=$(dirname "${CSV_PATH}")
  if [[ ! -w "${dir}" && "$(id -u)" -ne 0 ]]; then
    fail "Run as root (sudo) or choose a writable OUTPUT_DIR"
  fi
}

ensure_output_dir() {
  local dir
  dir=$(dirname "${CSV_PATH}")
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would create ${dir}"
    return 0
  fi
  install -d -m 0700 "${dir}"
}

csv_escape() {
  local value="$1"
  if [[ "${value}" == *"\""* ]]; then
    value="${value//\"/\"\"}"
  fi
  if [[ "${value}" == *","* || "${value}" == *$'\n'* ]]; then
    printf '"%s"' "${value}"
  else
    printf '%s' "${value}"
  fi
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

json_array_from_csv() {
  local csv="$1"
  local out="["
  IFS=',' read -r -a items <<< "${csv}"
  local item
  for item in "${items[@]}"; do
    item=$(cs_trim "${item}")
    [[ -z "${item}" ]] && continue
    out+="\"$(json_escape "${item}")\","
  done
  out="${out%,}"
  out+="]"
  printf '%s' "${out}"
}

write_header_files() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] would write ${CSV_PATH}, ${TAGS_JSONL_PATH}, ${TAGS_CSV_PATH}"
    return 0
  fi
  : > "${CSV_PATH}"
  : > "${TAGS_JSONL_PATH}"
  : > "${TAGS_CSV_PATH}"
  chmod 600 "${CSV_PATH}" "${TAGS_JSONL_PATH}" "${TAGS_CSV_PATH}"
  printf '%s\n' "username,email,full_name,ssh_key" >> "${CSV_PATH}"
  printf '%s\n' "username,role,domain,access,trust,risk,behavior_tags,mfa_required,sso_required,hitl_required,notes" >> "${TAGS_CSV_PATH}"
}

append_contributor() {
  local username=$1
  local email=$2
  local full_name=$3
  local ssh_key=$4
  local role=$5
  local domain=$6
  local access=$7
  local trust=$8
  local risk=$9
  local tags=${10}
  local mfa=${11}
  local sso=${12}
  local hitl=${13}
  local notes=${14}

  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[dry-run] add contributor ${username} (${role}/${domain})"
    return 0
  fi

  printf '%s,%s,%s,%s\n' \
    "$(csv_escape "${username}")" \
    "$(csv_escape "${email}")" \
    "$(csv_escape "${full_name}")" \
    "$(csv_escape "${ssh_key}")" >> "${CSV_PATH}"

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$(csv_escape "${username}")" \
    "$(csv_escape "${role}")" \
    "$(csv_escape "${domain}")" \
    "$(csv_escape "${access}")" \
    "$(csv_escape "${trust}")" \
    "$(csv_escape "${risk}")" \
    "$(csv_escape "${tags}")" \
    "$(csv_escape "${mfa}")" \
    "$(csv_escape "${sso}")" \
    "$(csv_escape "${hitl}")" \
    "$(csv_escape "${notes}")" >> "${TAGS_CSV_PATH}"

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local record
  record=$(printf '{"record_id":"onboard-%s-%s","category":"contributor-onboarding","user":{"username":"%s","email":"%s","full_name":"%s"},"role":"%s","domain":"%s","access":"%s","trust":"%s","risk":"%s","behavior_tags":%s,"controls":{"mfa_required":%s,"sso_required":%s,"hitl_required":%s},"notes":"%s","created_at":"%s"}' \
    "${username}" "$(date -u +%Y%m%d%H%M%S)" \
    "$(json_escape "${username}")" \
    "$(json_escape "${email}")" \
    "$(json_escape "${full_name}")" \
    "$(json_escape "${role}")" \
    "$(json_escape "${domain}")" \
    "$(json_escape "${access}")" \
    "$(json_escape "${trust}")" \
    "$(json_escape "${risk}")" \
    "$(json_array_from_csv "${tags}")" \
    "${mfa}" \
    "${sso}" \
    "${hitl}" \
    "$(json_escape "${notes}")" \
    "${timestamp}")
  printf '%s\n' "${record}" >> "${TAGS_JSONL_PATH}"
}

write_evidence() {
  if [[ -z "${EVIDENCE_DIR}" ]]; then
    return 0
  fi
  mkdir -p "${EVIDENCE_DIR}"
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local record
  record=$(printf '{"timestamp":"%s","csv_path":"%s","tags_jsonl":"%s","tags_csv":"%s","dry_run":%s}' \
    "${timestamp}" \
    "$(json_escape "${CSV_PATH}")" \
    "$(json_escape "${TAGS_JSONL_PATH}")" \
    "$(json_escape "${TAGS_CSV_PATH}")" \
    "${DRY_RUN}")
  printf '%s\n' "${record}" >> "${EVIDENCE_DIR}/contributor-onboarding-wizard.jsonl"
}

if [[ "${INTERACTIVE}" == "true" ]]; then
  cs_ui_header "Wizard de onboarding de colaboradores"
  cs_ui_note "Genera CSV para Gitea + JSONL de etiquetas de comportamiento."
  cs_ui_note "DRY_RUN=${DRY_RUN}"
fi

require_root_if_apply
ensure_output_dir
write_header_files

if [[ "${INTERACTIVE}" == "true" ]]; then
  if cs_ui_confirm "Editar rutas de salida?" "N"; then
    CSV_PATH=$(cs_ui_prompt "CSV path" "${CSV_PATH}")
    TAGS_JSONL_PATH=$(cs_ui_prompt "Tags JSONL path" "${TAGS_JSONL_PATH}")
    TAGS_CSV_PATH=$(cs_ui_prompt "Tags CSV path" "${TAGS_CSV_PATH}")
  fi
fi

add_loop=true
if [[ "${INTERACTIVE}" != "true" ]]; then
  add_loop=false
fi

if [[ "${add_loop}" == "true" ]]; then
  while true; do
    cs_ui_step "Nuevo colaborador"
    username=$(cs_ui_prompt "Username" "")
    if [[ -z "${username}" ]]; then
      if cs_ui_confirm "Terminar?" "Y"; then
        break
      fi
      continue
    fi
    email=$(cs_ui_prompt "Email" "${username}@example.com")
    full_name=$(cs_ui_prompt "Nombre completo" "${username}")
    ssh_key=$(cs_ui_prompt "SSH key (path o key)" "")

    role=$(cs_ui_prompt "Rol (founder/owner/maintainer/contributor/contractor)" "${DEFAULT_ROLE}")
    domain=$(cs_ui_prompt "Dominio (infra/security/data/ai/compliance/ops)" "${DEFAULT_DOMAIN}")
    access=$(cs_ui_prompt "Acceso (public/internal/private/secret)" "${DEFAULT_ACCESS}")
    trust=$(cs_ui_prompt "Trust tier (tier0/tier1/tier2)" "${DEFAULT_TRUST}")
    risk=$(cs_ui_prompt "Riesgo (low/medium/high)" "${DEFAULT_RISK}")
    tags=$(cs_ui_prompt "Behavior tags (comma)" "${DEFAULT_BEHAVIOR_TAGS}")
    mfa=$(cs_ui_prompt "MFA required (true/false)" "${DEFAULT_MFA}")
    sso=$(cs_ui_prompt "SSO required (true/false)" "${DEFAULT_SSO}")
    hitl=$(cs_ui_prompt "HITL required (true/false)" "${DEFAULT_HITL}")
    notes=$(cs_ui_prompt "Notas" "")

    append_contributor "${username}" "${email}" "${full_name}" "${ssh_key}" \
      "${role}" "${domain}" "${access}" "${trust}" "${risk}" "${tags}" \
      "${mfa}" "${sso}" "${hitl}" "${notes}"

    if ! cs_ui_confirm "Agregar otro colaborador?" "Y"; then
      break
    fi
  done
else
  if [[ "${SEED_PLACEHOLDER}" == "true" ]]; then
    append_contributor "contrib1" "contrib1@example.com" "Contributor One" "/home/contrib1/.ssh/id_ed25519.pub" \
      "${DEFAULT_ROLE}" "${DEFAULT_DOMAIN}" "${DEFAULT_ACCESS}" "${DEFAULT_TRUST}" "${DEFAULT_RISK}" "${DEFAULT_BEHAVIOR_TAGS}" \
      "${DEFAULT_MFA}" "${DEFAULT_SSO}" "${DEFAULT_HITL}" "placeholder"
  fi
fi

write_evidence

cs_ui_ok "Wizard completado"
if [[ "${DRY_RUN}" != "true" ]]; then
  cs_ui_note "CSV: ${CSV_PATH}"
  cs_ui_note "Tags JSONL: ${TAGS_JSONL_PATH}"
fi
