#!/usr/bin/env bash
set -euo pipefail

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
CS_LOG_PREFIX="gitea-hardening"

CONFIG_PATH="${1:-}"
ENV_EXAMPLE="${CS_ROOT}/platforms/compliance/gitea-hardening.env.example"
if [[ -n "${CONFIG_PATH}" ]]; then
  cs_load_env_chain "${CONFIG_PATH}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}"
fi

require_cmd() {
  cs_require_cmd "$1"
}

GITEA_APP_INI=${GITEA_APP_INI:-""}
GITEA_LXC_CTID=${GITEA_LXC_CTID:-""}
SETTINGS_FILE=${SETTINGS_FILE:-""}
HARDENING_PROFILE=${HARDENING_PROFILE:-""}
BACKUP_SUFFIX=${BACKUP_SUFFIX:-".bak"}
RESTART_CMD=${RESTART_CMD:-""}
DRY_RUN=${DRY_RUN:-"false"}

if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

if [[ -z "${GITEA_APP_INI}" ]]; then
  echo "GITEA_APP_INI is required" >&2
  exit 1
fi
if [[ -z "${SETTINGS_FILE}" ]]; then
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  if [[ "${HARDENING_PROFILE}" == "high" ]]; then
    SETTINGS_FILE="${script_dir}/gitea-hardening-high.ini"
  elif [[ "${HARDENING_PROFILE}" == "strict" ]]; then
    SETTINGS_FILE="${script_dir}/gitea-hardening-strict.ini"
  fi
fi

if [[ -z "${SETTINGS_FILE}" || ! -f "${SETTINGS_FILE}" ]]; then
  echo "SETTINGS_FILE not found and no HARDENING_PROFILE resolved" >&2
  exit 1
fi

apply_ini_settings() {
  local file=$1
  local settings=$2

  if [[ ! -f "${file}" ]]; then
    echo "app.ini not found: ${file}" >&2
    exit 1
  fi

  local backup="${file}${BACKUP_SUFFIX}"
  if [[ "${DRY_RUN}" != "true" ]]; then
    cp "${file}" "${backup}"
  fi

  local current_section=""
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    [[ "${line}" == \#* ]] && continue
    if [[ "${line}" =~ ^\[.*\]$ ]]; then
      current_section="${line}"
      continue
    fi
    if [[ "${line}" == *"="* ]]; then
      local key=${line%%=*}
      local value=${line#*=}
      key=$(echo "${key}" | xargs)
      value=$(echo "${value}" | xargs)
      ini_set "${file}" "${current_section}" "${key}" "${value}"
    fi
  done < "${settings}"
}

ini_set() {
  local file=$1
  local section=$2
  local key=$3
  local value=$4

  if [[ -z "${section}" ]]; then
    echo "Settings missing section for ${key}" >&2
    exit 1
  fi

  local tmp
  tmp=$(mktemp)

  awk -v section="${section}" -v key="${key}" -v value="${value}" '
    BEGIN { in_section=0; key_written=0 }
    $0 ~ /^\[/ {
      if (in_section && !key_written) {
        print key " = " value
        key_written=1
      }
      in_section = ($0 == section)
    }
    in_section && $0 ~ "^" key "[[:space:]]*=" {
      print key " = " value
      key_written=1
      next
    }
    { print }
    END {
      if (!key_written) {
        if (!in_section) {
          print section
        }
        print key " = " value
      }
    }
  ' "${file}" > "${tmp}"

  if [[ "${DRY_RUN}" != "true" ]]; then
    mv "${tmp}" "${file}"
  else
    rm -f "${tmp}"
  fi
}

apply_local() {
  apply_ini_settings "${GITEA_APP_INI}" "${SETTINGS_FILE}"
  if [[ -n "${RESTART_CMD}" && "${DRY_RUN}" != "true" ]]; then
    bash -c "${RESTART_CMD}"
  fi
}

apply_lxc() {
  require_cmd pct
  local ctid=$1
  local remote_dir="/tmp/gitea-hardening"
  local settings_remote="${remote_dir}/settings.ini"
  local apply_remote="${remote_dir}/apply.sh"

  pct exec "${ctid}" -- mkdir -p "${remote_dir}"
  pct push "${ctid}" "${SETTINGS_FILE}" "${settings_remote}"

  local helper
  helper=$(mktemp)
  cat <<'EOS' > "${helper}"
#!/usr/bin/env bash
set -euo pipefail

GITEA_APP_INI=${GITEA_APP_INI:-""}
SETTINGS_FILE=${SETTINGS_FILE:-""}
BACKUP_SUFFIX=${BACKUP_SUFFIX:-".bak"}
RESTART_CMD=${RESTART_CMD:-""}
DRY_RUN=${DRY_RUN:-"false"}

if [[ -z "${GITEA_APP_INI}" || -z "${SETTINGS_FILE}" ]]; then
  echo "Missing GITEA_APP_INI or SETTINGS_FILE" >&2
  exit 1
fi

ini_set() {
  local file=$1
  local section=$2
  local key=$3
  local value=$4

  local tmp
  tmp=$(mktemp)

  awk -v section="${section}" -v key="${key}" -v value="${value}" '
    BEGIN { in_section=0; key_written=0 }
    $0 ~ /^\[/ {
      if (in_section && !key_written) {
        print key " = " value
        key_written=1
      }
      in_section = ($0 == section)
    }
    in_section && $0 ~ "^" key "[[:space:]]*=" {
      print key " = " value
      key_written=1
      next
    }
    { print }
    END {
      if (!key_written) {
        if (!in_section) {
          print section
        }
        print key " = " value
      }
    }
  ' "${file}" > "${tmp}"

  if [[ "${DRY_RUN}" != "true" ]]; then
    mv "${tmp}" "${file}"
  else
    rm -f "${tmp}"
  fi
}

apply_ini_settings() {
  local file=$1
  local settings=$2
  if [[ ! -f "${file}" ]]; then
    echo "app.ini not found: ${file}" >&2
    exit 1
  fi

  local backup="${file}${BACKUP_SUFFIX}"
  if [[ "${DRY_RUN}" != "true" ]]; then
    cp "${file}" "${backup}"
  fi

  local current_section=""
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    [[ "${line}" == \#* ]] && continue
    if [[ "${line}" =~ ^\[.*\]$ ]]; then
      current_section="${line}"
      continue
    fi
    if [[ "${line}" == *"="* ]]; then
      local key=${line%%=*}
      local value=${line#*=}
      key=$(echo "${key}" | xargs)
      value=$(echo "${value}" | xargs)
      ini_set "${file}" "${current_section}" "${key}" "${value}"
    fi
  done < "${settings}"
}

apply_ini_settings "${GITEA_APP_INI}" "${SETTINGS_FILE}"

if [[ -n "${RESTART_CMD}" && "${DRY_RUN}" != "true" ]]; then
  bash -c "${RESTART_CMD}"
fi
EOS

  pct push "${ctid}" "${helper}" "${apply_remote}"

  pct exec "${ctid}" -- env \
    GITEA_APP_INI="${GITEA_APP_INI}" \
    SETTINGS_FILE="${settings_remote}" \
    BACKUP_SUFFIX="${BACKUP_SUFFIX}" \
    RESTART_CMD="${RESTART_CMD}" \
    DRY_RUN="${DRY_RUN}" \
    bash "${apply_remote}"

  rm -f "${helper}"
}

if [[ -n "${GITEA_LXC_CTID}" ]]; then
  apply_lxc "${GITEA_LXC_CTID}"
else
  apply_local
fi
