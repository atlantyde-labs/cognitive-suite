#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CS_LIB_FALLBACK="/usr/local/lib/cognitive-suite/cs-common.sh"
if [[ -f "${CS_LIB_FALLBACK}" ]]; then
  # shellcheck disable=SC1090,SC1091
  source "${CS_LIB_FALLBACK}"
else
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
fi

# shellcheck disable=SC2034
CS_LOG_PREFIX="reboot-guard"

log() {
  cs_log "$*"
}

fail() {
  cs_die "$*"
}

ENV_FILE=${ENV_FILE:-"/etc/reboot-guard.env"}
ENV_EXAMPLE="${SCRIPT_DIR}/reboot-guard.env.example"
if [[ -f "${ENV_FILE}" ]]; then
  cs_load_env_file "${ENV_FILE}" "${ENV_EXAMPLE}" "${CS_STRICT_CONFIG:-false}" || true
fi

RG_WINDOW_START=${RG_WINDOW_START:-"02:00"}
RG_WINDOW_END=${RG_WINDOW_END:-"03:00"}
RG_WINDOW_DAYS=${RG_WINDOW_DAYS:-"Sun"}
RG_CHECK_INTERVAL=${RG_CHECK_INTERVAL:-"60"}

RG_INHIBIT_WHAT=${RG_INHIBIT_WHAT:-"shutdown"}
RG_INHIBIT_MODE=${RG_INHIBIT_MODE:-"block"}
RG_INHIBIT_WHO=${RG_INHIBIT_WHO:-"reboot-guard"}
RG_INHIBIT_WHY=${RG_INHIBIT_WHY:-"Reboot guard active"}

RG_OVERRIDE_FILE=${RG_OVERRIDE_FILE:-"/run/reboot-guard/allow"}
RG_OVERRIDE_TTL=${RG_OVERRIDE_TTL:-"0"}

require_cmd() {
  cs_require_cmd "$1"
}

require_cmd systemd-inhibit
require_cmd sleep
require_cmd date

day_to_index() {
  case "$1" in
    mon) echo 1 ;;
    tue) echo 2 ;;
    wed) echo 3 ;;
    thu) echo 4 ;;
    fri) echo 5 ;;
    sat) echo 6 ;;
    sun) echo 7 ;;
    *) echo 0 ;;
  esac
}

normalize_day() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d ' '
}

day_allowed() {
  local days
  days=$(normalize_day "${RG_WINDOW_DAYS}")
  if [[ -z "${days}" || "${days}" == "all" || "${days}" == "*" ]]; then
    return 0
  fi
  local now_day
  now_day=$(normalize_day "$(date +%a)")
  local now_idx
  now_idx=$(day_to_index "${now_day}")
  IFS=',' read -r -a tokens <<< "${days}"
  for token in "${tokens[@]}"; do
    token=$(normalize_day "${token}")
    if [[ "${token}" == "${now_day}" ]]; then
      return 0
    fi
    if [[ "${token}" == *"-"* ]]; then
      local start end start_idx end_idx
      start=${token%%-*}
      end=${token##*-}
      start_idx=$(day_to_index "${start}")
      end_idx=$(day_to_index "${end}")
      if [[ "${start_idx}" -eq 0 || "${end_idx}" -eq 0 ]]; then
        continue
      fi
      if [[ "${start_idx}" -le "${end_idx}" ]]; then
        if [[ "${now_idx}" -ge "${start_idx}" && "${now_idx}" -le "${end_idx}" ]]; then
          return 0
        fi
      else
        if [[ "${now_idx}" -ge "${start_idx}" || "${now_idx}" -le "${end_idx}" ]]; then
          return 0
        fi
      fi
    fi
  done
  return 1
}

time_to_minutes() {
  local time=$1
  local hours=${time%%:*}
  local minutes=${time##*:}
  printf '%d\n' "$((10#${hours} * 60 + 10#${minutes}))"
}

time_allowed() {
  local now
  now=$(date +%H:%M)
  local now_m start_m end_m
  now_m=$(time_to_minutes "${now}")
  start_m=$(time_to_minutes "${RG_WINDOW_START}")
  end_m=$(time_to_minutes "${RG_WINDOW_END}")
  if [[ "${start_m}" -eq "${end_m}" ]]; then
    return 0
  fi
  if [[ "${start_m}" -lt "${end_m}" ]]; then
    [[ "${now_m}" -ge "${start_m}" && "${now_m}" -lt "${end_m}" ]]
  else
    [[ "${now_m}" -ge "${start_m}" || "${now_m}" -lt "${end_m}" ]]
  fi
}

override_active() {
  if [[ -z "${RG_OVERRIDE_TTL}" || "${RG_OVERRIDE_TTL}" == "0" ]]; then
    return 1
  fi
  if [[ ! -f "${RG_OVERRIDE_FILE}" ]]; then
    return 1
  fi
  local now ts age
  now=$(date +%s)
  if ts=$(stat -c %Y "${RG_OVERRIDE_FILE}" 2>/dev/null); then
    :
  elif ts=$(stat -f %m "${RG_OVERRIDE_FILE}" 2>/dev/null); then
    :
  else
    return 1
  fi
  age=$(( (now - ts) / 60 ))
  if [[ "${age}" -le "${RG_OVERRIDE_TTL}" ]]; then
    return 0
  fi
  return 1
}

inhibitor_pid=""
current_state="unknown"

start_inhibitor() {
  if [[ -n "${inhibitor_pid}" ]] && kill -0 "${inhibitor_pid}" 2>/dev/null; then
    return
  fi
  systemd-inhibit \
    --what="${RG_INHIBIT_WHAT}" \
    --mode="${RG_INHIBIT_MODE}" \
    --why="${RG_INHIBIT_WHY}" \
    --who="${RG_INHIBIT_WHO}" \
    sleep infinity &
  inhibitor_pid=$!
}

stop_inhibitor() {
  if [[ -n "${inhibitor_pid}" ]] && kill -0 "${inhibitor_pid}" 2>/dev/null; then
    kill "${inhibitor_pid}" >/dev/null 2>&1 || true
    wait "${inhibitor_pid}" 2>/dev/null || true
  fi
  inhibitor_pid=""
}

cleanup() {
  stop_inhibitor
  exit 0
}

trap cleanup INT TERM

if [[ ! "${RG_CHECK_INTERVAL}" =~ ^[0-9]+$ ]]; then
  RG_CHECK_INTERVAL="60"
fi

log "Reboot guard started. Window ${RG_WINDOW_DAYS} ${RG_WINDOW_START}-${RG_WINDOW_END}"

while true; do
  if override_active || (day_allowed && time_allowed); then
    if [[ "${current_state}" != "allowed" ]]; then
      log "Reboot allowed (within window or override)."
    fi
    current_state="allowed"
    stop_inhibitor
  else
    if [[ "${current_state}" != "blocked" ]]; then
      log "Reboot blocked (outside window)."
    fi
    current_state="blocked"
    start_inhibitor
  fi
  sleep "${RG_CHECK_INTERVAL}"
done
