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

require_cmd curl
require_cmd jq

GITEA_URL=${GITEA_URL:-""}
GITEA_TOKEN=${GITEA_TOKEN:-""}
GITEA_OWNER_MAP=${GITEA_OWNER_MAP:-""}

EXPORT_DIR=${EXPORT_DIR:-"./exports/github"}
IMPORT_ISSUES=${IMPORT_ISSUES:-"true"}
IMPORT_PULLS=${IMPORT_PULLS:-"true"}
PULL_REQUEST_MODE=${PULL_REQUEST_MODE:-"issue"} # issue|pr
IMPORT_LABELS=${IMPORT_LABELS:-"false"}
IMPORT_ASSIGNEES=${IMPORT_ASSIGNEES:-"false"}
IMPORT_MILESTONES=${IMPORT_MILESTONES:-"false"}
CREATE_MISSING_LABELS=${CREATE_MISSING_LABELS:-"false"}
CREATE_MISSING_MILESTONES=${CREATE_MISSING_MILESTONES:-"false"}
USER_MAP=${USER_MAP:-""}
USER_MAP_FILE=${USER_MAP_FILE:-""}
SET_CLOSED_STATE=${SET_CLOSED_STATE:-"false"}
DRY_RUN=${DRY_RUN:-"false"}

if [[ "${FORCE_DRY_RUN:-false}" == "true" ]]; then
  DRY_RUN="true"
fi

if [[ -z "${GITEA_URL}" || -z "${GITEA_TOKEN}" ]]; then
  echo "GITEA_URL and GITEA_TOKEN are required" >&2
  exit 1
fi

map_owner() {
  local gh_owner=$1
  if [[ -z "${GITEA_OWNER_MAP}" ]]; then
    echo "${gh_owner}"
    return
  fi
  local mapping
  IFS=',' read -r -a mapping <<< "${GITEA_OWNER_MAP}"
  for pair in "${mapping[@]}"; do
    local k=${pair%%=*}
    local v=${pair#*=}
    if [[ "${k}" == "${gh_owner}" ]]; then
      echo "${v}"
      return
    fi
  done
  echo "${gh_owner}"
}

declare -A USER_MAP_TABLE

load_user_map() {
  if [[ -n "${USER_MAP}" ]]; then
    local mapping
    IFS=',' read -r -a mapping <<< "${USER_MAP}"
    for pair in "${mapping[@]}"; do
      local k=${pair%%=*}
      local v=${pair#*=}
      if [[ -n "${k}" && -n "${v}" ]]; then
        USER_MAP_TABLE["${k}"]="${v}"
      fi
    done
  fi

  if [[ -n "${USER_MAP_FILE}" && -f "${USER_MAP_FILE}" ]]; then
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      [[ "${line}" == \#* ]] && continue

      if [[ "${line}" == *","* ]]; then
        local gh_user gitea_user
        IFS=',' read -r gh_user gitea_user _ <<< "${line}"
        if [[ "${gh_user}" == "github_user" ]]; then
          continue
        fi
        gh_user=$(echo "${gh_user}" | xargs)
        gitea_user=$(echo "${gitea_user}" | xargs)
        if [[ -n "${gh_user}" && -n "${gitea_user}" ]]; then
          USER_MAP_TABLE["${gh_user}"]="${gitea_user}"
        fi
      else
        local gh_user gitea_user
        IFS='=' read -r gh_user gitea_user <<< "${line}"
        gh_user=$(echo "${gh_user}" | xargs)
        gitea_user=$(echo "${gitea_user}" | xargs)
        if [[ -n "${gh_user}" && -n "${gitea_user}" ]]; then
          USER_MAP_TABLE["${gh_user}"]="${gitea_user}"
        fi
      fi
    done < "${USER_MAP_FILE}"
  fi
}

map_user() {
  local gh_user=$1
  if [[ -z "${gh_user}" ]]; then
    echo ""
    return
  fi
  if [[ -n "${USER_MAP_TABLE[${gh_user}]:-}" ]]; then
    echo "${USER_MAP_TABLE[${gh_user}]}"
    return
  fi
  echo ""
}

load_user_map

api_get() {
  local path=$1
  curl -fsSL -H "Authorization: token ${GITEA_TOKEN}" "${GITEA_URL}/api/v1${path}"
}

api_post() {
  local path=$1
  local payload=$2
  curl -sS -o /tmp/gitea-import.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${GITEA_URL}/api/v1${path}" \
    -d "${payload}"
}

api_patch() {
  local path=$1
  local payload=$2
  curl -sS -o /tmp/gitea-import.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X PATCH "${GITEA_URL}/api/v1${path}" \
    -d "${payload}"
}

api_post_raw() {
  local path=$1
  local payload=$2
  curl -sS -o /tmp/gitea-import.json -w '%{http_code}' \
    -H "Authorization: token ${GITEA_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${GITEA_URL}/api/v1${path}" \
    -d "${payload}"
}

labels_map_for_repo() {
  local owner=$1
  local repo=$2
  api_get "/repos/${owner}/${repo}/labels" | jq -r '.[] | "\(.name)\t\(.id)"'
}

create_label() {
  local owner=$1
  local repo=$2
  local name=$3
  local color=$4

  if [[ -z "${color}" ]]; then
    color="ffffff"
  fi

  local payload
  payload=$(jq -n --arg name "${name}" --arg color "${color}" '{name: $name, color: $color}')

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would create label ${owner}/${repo}:${name}"
    echo ""
    return 0
  fi

  local status
  status=$(api_post_raw "/repos/${owner}/${repo}/labels" "${payload}")
  if [[ "${status}" != "201" ]]; then
    echo "Failed to create label ${owner}/${repo}:${name} (HTTP ${status})" >&2
    cat /tmp/gitea-import.json >&2
    echo ""
    return 1
  fi

  jq -r '.id' /tmp/gitea-import.json
}

milestones_map_for_repo() {
  local owner=$1
  local repo=$2
  api_get "/repos/${owner}/${repo}/milestones" | jq -r '.[] | "\(.title)\t\(.id)"'
}

create_milestone() {
  local owner=$1
  local repo=$2
  local title=$3
  local description=$4
  local due_on=$5
  local state=$6

  local payload
  payload=$(jq -n \
    --arg title "${title}" \
    --arg description "${description}" \
    --arg due_on "${due_on}" \
    --arg state "${state}" \
    '{title: $title} + ( $description | if length>0 then {description: $description} else {} end ) + ( $due_on | if length>0 then {due_on: $due_on} else {} end ) + ( $state | if length>0 then {state: $state} else {} end )')

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would create milestone ${owner}/${repo}:${title}"
    echo ""
    return 0
  fi

  local status
  status=$(api_post_raw "/repos/${owner}/${repo}/milestones" "${payload}")
  if [[ "${status}" != "201" ]]; then
    echo "Failed to create milestone ${owner}/${repo}:${title} (HTTP ${status})" >&2
    cat /tmp/gitea-import.json >&2
    echo ""
    return 1
  fi

  jq -r '.id' /tmp/gitea-import.json
}

resolve_label_ids() {
  local name_list=$1
  local map_file=$2
  local ids=()
  while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    local id
    id=$(awk -F '\t' -v n="${name}" '$1 == n {print $2}' "${map_file}")
    if [[ -n "${id}" ]]; then
      ids+=("${id}")
    fi
  done <<< "${name_list}"

  if [[ "${#ids[@]}" -eq 0 ]]; then
    echo "[]"
    return
  fi

  printf '%s\n' "${ids[@]}" | jq -R . | jq -cs .
}

resolve_milestone_id() {
  local title=$1
  local map_file=$2
  local id
  id=$(awk -F '\t' -v n="${title}" '$1 == n {print $2}' "${map_file}")
  echo "${id}"
}

resolve_assignees() {
  local raw=$1
  local mapped=()
  while IFS= read -r user; do
    [[ -z "${user}" ]] && continue
    local mapped_user
    mapped_user=$(map_user "${user}")
    if [[ -n "${mapped_user}" ]]; then
      mapped+=("${mapped_user}")
    fi
  done <<< "${raw}"

  if [[ "${#mapped[@]}" -eq 0 ]]; then
    echo "[]"
    return
  fi

  printf '%s\n' "${mapped[@]}" | awk 'NF' | sort -u | jq -R . | jq -cs .
}

format_issue_body() {
  local body=$1
  local url=$2
  local author=$3
  local created_at=$4
  cat <<EOF_BODY
${body}

---
Imported from GitHub
Author: ${author}
Created: ${created_at}
Source: ${url}
EOF_BODY
}

create_issue() {
  local owner=$1
  local repo=$2
  local title=$3
  local body=$4
  local label_ids=$5
  local assignees_json=$6
  local milestone_id=$7
  local close_state=$8

  local payload
  payload=$(jq -n \
    --arg title "${title}" \
    --arg body "${body}" \
    --argjson labels "${label_ids}" \
    --argjson assignees "${assignees_json}" \
    --argjson milestone "${milestone_id}" \
    '{title: $title, body: $body} + ( $labels | if length>0 then {labels: $labels} else {} end ) + ( $assignees | if length>0 then {assignees: $assignees} else {} end ) + ( $milestone | if $milestone>0 then {milestone: $milestone} else {} end )')

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would create issue ${owner}/${repo}: ${title}"
    return 0
  fi

  local status
  status=$(api_post "/repos/${owner}/${repo}/issues" "${payload}")
  if [[ "${status}" != "201" ]]; then
    echo "Failed to create issue ${owner}/${repo}: ${title} (HTTP ${status})" >&2
    cat /tmp/gitea-import.json >&2
    return 1
  fi

  if [[ "${close_state}" == "true" && "${SET_CLOSED_STATE}" == "true" ]]; then
    local index
    index=$(jq -r '.number' /tmp/gitea-import.json)
    if [[ -n "${index}" && "${index}" != "null" ]]; then
      local close_payload
      close_payload=$(jq -n --arg state "closed" '{state: $state}')
      api_patch "/repos/${owner}/${repo}/issues/${index}" "${close_payload}" >/dev/null
    fi
  fi
}

create_pull_request() {
  local owner=$1
  local repo=$2
  local title=$3
  local body=$4
  local base=$5
  local head=$6

  local payload
  payload=$(jq -n \
    --arg title "${title}" \
    --arg body "${body}" \
    --arg base "${base}" \
    --arg head "${head}" \
    '{title: $title, body: $body, base: $base, head: $head}')

  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY_RUN: would create PR ${owner}/${repo}: ${title}"
    return 0
  fi

  local status
  status=$(api_post "/repos/${owner}/${repo}/pulls" "${payload}")
  if [[ "${status}" != "201" ]]; then
    echo "Failed to create PR ${owner}/${repo}: ${title} (HTTP ${status})" >&2
    cat /tmp/gitea-import.json >&2
    return 1
  fi
}

import_repo() {
  local gh_owner=$1
  local repo=$2
  local target_owner
  target_owner=$(map_owner "${gh_owner}")

  local labels_map_file
  local milestones_map_file
  labels_map_file=$(mktemp)
  milestones_map_file=$(mktemp)

  if [[ "${IMPORT_LABELS}" == "true" ]]; then
    labels_map_for_repo "${target_owner}" "${repo}" > "${labels_map_file}" || true
  fi
  if [[ "${IMPORT_MILESTONES}" == "true" ]]; then
    milestones_map_for_repo "${target_owner}" "${repo}" > "${milestones_map_file}" || true
  fi

  if [[ "${IMPORT_ISSUES}" == "true" && -f "${EXPORT_DIR}/${gh_owner}/${repo}/issues.jsonl" ]]; then
    while IFS= read -r line; do
      local title body url author created_at state labels assignees milestone milestone_desc milestone_due milestone_state
      title=$(echo "${line}" | jq -r '.title')
      body=$(echo "${line}" | jq -r '.body // ""')
      url=$(echo "${line}" | jq -r '.html_url')
      author=$(echo "${line}" | jq -r '.user.login')
      created_at=$(echo "${line}" | jq -r '.created_at')
      state=$(echo "${line}" | jq -r '.state')
      labels=$(echo "${line}" | jq -r '.labels[]?.name')
      assignees=$(echo "${line}" | jq -r '.assignees[]?.login')
      milestone=$(echo "${line}" | jq -r '.milestone.title // empty')
      milestone_desc=$(echo "${line}" | jq -r '.milestone.description // empty')
      milestone_due=$(echo "${line}" | jq -r '.milestone.due_on // empty')
      milestone_state=$(echo "${line}" | jq -r '.milestone.state // empty')

      local body_out
      body_out=$(format_issue_body "${body}" "${url}" "${author}" "${created_at}")

      local label_ids_json="[]"
      if [[ "${IMPORT_LABELS}" == "true" ]]; then
        if [[ "${CREATE_MISSING_LABELS}" == "true" ]]; then
          while IFS= read -r label; do
            [[ -z "${label}" ]] && continue
            local existing
            existing=$(awk -F '\t' -v n="${label}" '$1 == n {print $2}' "${labels_map_file}")
            if [[ -z "${existing}" ]]; then
              local color
              color=$(echo "${line}" | jq -r --arg name "${label}" '.labels[]? | select(.name == $name) | .color' | head -n1)
              local new_id
              new_id=$(create_label "${target_owner}" "${repo}" "${label}" "${color}" || true)
              if [[ -n "${new_id}" ]]; then
                printf '%s\t%s\n' "${label}" "${new_id}" >> "${labels_map_file}"
              fi
            fi
          done <<< "${labels}"
        fi
        label_ids_json=$(resolve_label_ids "${labels}" "${labels_map_file}")
      fi

      local assignees_json="[]"
      if [[ "${IMPORT_ASSIGNEES}" == "true" ]]; then
        assignees_json=$(resolve_assignees "${assignees}")
      fi

      local milestone_id="0"
      if [[ "${IMPORT_MILESTONES}" == "true" && -n "${milestone}" ]]; then
        milestone_id=$(resolve_milestone_id "${milestone}" "${milestones_map_file}")
        if [[ -z "${milestone_id}" && "${CREATE_MISSING_MILESTONES}" == "true" ]]; then
          local new_id
          new_id=$(create_milestone "${target_owner}" "${repo}" "${milestone}" "${milestone_desc}" "${milestone_due}" "${milestone_state}" || true)
          if [[ -n "${new_id}" ]]; then
            printf '%s\t%s\n' "${milestone}" "${new_id}" >> "${milestones_map_file}"
            milestone_id="${new_id}"
          fi
        fi
        milestone_id=${milestone_id:-0}
      fi

      local close_state="false"
      if [[ "${state}" == "closed" ]]; then
        close_state="true"
      fi

      create_issue "${target_owner}" "${repo}" "${title}" "${body_out}" "${label_ids_json}" "${assignees_json}" "${milestone_id}" "${close_state}"
    done < "${EXPORT_DIR}/${gh_owner}/${repo}/issues.jsonl"
  fi

  if [[ "${IMPORT_PULLS}" == "true" && -f "${EXPORT_DIR}/${gh_owner}/${repo}/pulls.jsonl" ]]; then
    while IFS= read -r line; do
      local title body url author created_at base_ref head_ref head_repo base_repo
      title=$(echo "${line}" | jq -r '.title')
      body=$(echo "${line}" | jq -r '.body // ""')
      url=$(echo "${line}" | jq -r '.html_url')
      author=$(echo "${line}" | jq -r '.user.login')
      created_at=$(echo "${line}" | jq -r '.created_at')
      base_ref=$(echo "${line}" | jq -r '.base.ref')
      head_ref=$(echo "${line}" | jq -r '.head.ref')
      head_repo=$(echo "${line}" | jq -r '.head.repo.full_name')
      base_repo=$(echo "${line}" | jq -r '.base.repo.full_name')

      local body_out
      body_out=$(format_issue_body "${body}" "${url}" "${author}" "${created_at}")

      if [[ "${PULL_REQUEST_MODE}" == "pr" ]]; then
        if [[ "${head_repo}" != "${base_repo}" ]]; then
          echo "Skipping fork PR ${head_repo} -> ${base_repo}"
          continue
        fi
        create_pull_request "${target_owner}" "${repo}" "${title}" "${body_out}" "${base_ref}" "${head_ref}"
      else
        local pr_body
        pr_body="${body_out}\n\nImported PR: ${head_ref} -> ${base_ref}"
        create_issue "${target_owner}" "${repo}" "[PR] ${title}" "${pr_body}" "[]" "[]" "0" "false"
      fi
    done < "${EXPORT_DIR}/${gh_owner}/${repo}/pulls.jsonl"
  fi

  rm -f "${labels_map_file}" "${milestones_map_file}"
}

if [[ ! -d "${EXPORT_DIR}" ]]; then
  echo "EXPORT_DIR not found: ${EXPORT_DIR}" >&2
  exit 1
fi

for owner_dir in "${EXPORT_DIR}"/*; do
  [[ ! -d "${owner_dir}" ]] && continue
  gh_owner=$(basename "${owner_dir}")
  for repo_dir in "${owner_dir}"/*; do
    [[ ! -d "${repo_dir}" ]] && continue
    repo=$(basename "${repo_dir}")
    echo "Importing ${gh_owner}/${repo}"
    import_repo "${gh_owner}" "${repo}"
  done
done
