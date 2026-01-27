#!/usr/bin/env bash

cs_log() {
  local prefix="${CS_LOG_PREFIX:-cs}"
  printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${prefix}" "$*"
}

cs_warn() {
  cs_log "WARN: $*"
}

cs_die() {
  cs_log "ERROR: $*"
  exit 1
}

cs_require_cmd() {
  command -v "$1" >/dev/null 2>&1 || cs_die "Missing required command: $1"
}

cs_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

cs_strip_quotes() {
  local value="$1"
  if [[ "${value}" == \"*\" && "${value}" == *\" ]]; then
    value="${value#\"}"
    value="${value%\"}"
  elif [[ "${value}" == \'*\' && "${value}" == *\' ]]; then
    value="${value#\'}"
    value="${value%\'}"
  fi
  printf '%s' "${value}"
}

cs_array_contains() {
  local needle="$1"
  shift || true
  local item
  for item in "$@"; do
    if [[ "${item}" == "${needle}" ]]; then
      return 0
    fi
  done
  return 1
}

cs_read_env_example_keys() {
  local example_file="$1"
  awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/{print $1}' "${example_file}" | sort -u
}

cs_load_env_file() {
  local config_file="$1"
  local example_file="${2:-}"
  local strict="${3:-false}"

  if [[ ! -f "${config_file}" ]]; then
    return 1
  fi

  local -a allowlist=()
  if [[ -n "${example_file}" && -f "${example_file}" ]]; then
    mapfile -t allowlist < <(cs_read_env_example_keys "${example_file}")
  elif [[ "${strict}" == "true" ]]; then
    cs_die "Missing env example for strict parsing: ${example_file}"
  else
    cs_warn "Env example not found for allowlist; only basic validation applied (${example_file})."
  fi

  local line key value
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%#*}"
    line="$(cs_trim "${line}")"
    [[ -z "${line}" ]] && continue
    line="${line#export }"

    if [[ ! "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*= ]]; then
      if [[ "${strict}" == "true" ]]; then
        cs_die "Invalid line in ${config_file}: ${line}"
      fi
      cs_warn "Skipping invalid line in ${config_file}: ${line}"
      continue
    fi

    key="$(cs_trim "${line%%=*}")"
    value="$(cs_trim "${line#*=}")"
    value="$(cs_strip_quotes "${value}")"

    if [[ "${#allowlist[@]}" -gt 0 ]] && ! cs_array_contains "${key}" "${allowlist[@]}"; then
      if [[ "${strict}" == "true" ]]; then
        cs_die "Unknown key in ${config_file}: ${key}"
      fi
      cs_warn "Ignoring unknown key in ${config_file}: ${key}"
      continue
    fi

    if [[ -n "${!key+x}" ]]; then
      continue
    fi

    printf -v "${key}" '%s' "${value}"
    # shellcheck disable=SC2163
    export "${key}"
  done < "${config_file}"

  return 0
}

cs_load_env_chain() {
  local config_path="$1"
  local example_file="$2"
  local strict="${3:-false}"

  local global_settings="${CS_GLOBAL_SETTINGS_PATH:-/opt/cognitive-suite/.settings}"
  local compat_settings="/opt/community-scripts/.settings"

  if [[ -f "${compat_settings}" ]]; then
    cs_load_env_file "${compat_settings}" "${example_file}" "${strict}" || true
  fi
  if [[ -f "${global_settings}" ]]; then
    cs_load_env_file "${global_settings}" "${example_file}" "${strict}" || true
  fi
  if [[ -n "${config_path}" ]]; then
    cs_load_env_file "${config_path}" "${example_file}" "${strict}" || cs_die "Config not found: ${config_path}"
  fi
}

cs_get_env_value() {
  local config_file="$1"
  local key="$2"
  local example_file="${3:-}"
  local strict="${4:-false}"

  if [[ ! -f "${config_file}" ]]; then
    return 0
  fi

  local -a allowlist=()
  if [[ -n "${example_file}" && -f "${example_file}" ]]; then
    mapfile -t allowlist < <(cs_read_env_example_keys "${example_file}")
    if [[ "${#allowlist[@]}" -gt 0 ]] && ! cs_array_contains "${key}" "${allowlist[@]}"; then
      if [[ "${strict}" == "true" ]]; then
        cs_die "Key ${key} not permitted by allowlist"
      fi
      return 0
    fi
  elif [[ "${strict}" == "true" ]]; then
    cs_die "Missing env example for strict parsing: ${example_file}"
  fi

  local line value
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%#*}"
    line="$(cs_trim "${line}")"
    [[ -z "${line}" ]] && continue
    line="${line#export }"
    if [[ ! "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*= ]]; then
      if [[ "${strict}" == "true" ]]; then
        cs_die "Invalid line in ${config_file}: ${line}"
      fi
      continue
    fi
    if [[ "$(cs_trim "${line%%=*}")" == "${key}" ]]; then
      value="$(cs_trim "${line#*=}")"
      value="$(cs_strip_quotes "${value}")"
      printf '%s' "${value}"
      return 0
    fi
  done < "${config_file}"
  return 0
}

cs_check_pve_version() {
  local strict="${1:-false}"
  if ! command -v pveversion >/dev/null 2>&1; then
    return 0
  fi
  local version
  version=$(pveversion 2>/dev/null | awk -F/ '/pve-manager/ {print $2}' | cut -d- -f1)
  if [[ -z "${version}" ]]; then
    return 0
  fi
  case "${version}" in
    8.4.*|9.0.*|9.1.*)
      return 0
      ;;
    8.0.*|8.1.*|8.2.*|8.3.*)
      cs_warn "Proxmox VE ${version} has limited support; prefer 8.4.x or newer."
      ;;
    *)
      if [[ "${strict}" == "true" ]]; then
        cs_die "Unsupported Proxmox VE version: ${version}"
      fi
      cs_warn "Proxmox VE ${version} is untested."
      ;;
  esac
}

cs_warn_debian13_template() {
  local template="${1:-}"
  if [[ "${template}" == *"debian-13"* ]]; then
    cs_warn "Debian 13 containers may fail; prefer Debian 12 templates."
  fi
}
