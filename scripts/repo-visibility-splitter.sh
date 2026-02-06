#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to run this script" >&2
  exit 1
fi

CS_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Unable to locate repository root" >&2
  exit 1
}
CS_COMMON="${CS_ROOT}/bash/GitDevSecDataAIOps/lib/cs-common.sh"
if [[ ! -f "${CS_COMMON}" ]]; then
  echo "cs-common.sh not found at ${CS_COMMON}" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "${CS_COMMON}"
CS_LOG_PREFIX="repo-visibility-split"
export CS_ROOT

usage() {
  cat <<'EOF'
Usage: repo-visibility-splitter.sh [options]

Options:
  --config <path>   JSON manifest that describes how this repo should be sliced.
  --run | --push     Execute GitHub/Gitea creation and push (default is dry-run).
  --dry-run         Keep dry-run mode (overrides --run/--push).
  -h, --help        Show this help text.

By default the script evaluates scripts/repo-visibility-plan.json and only
reports what it would do. Pass --run to allow gh and gitea CLI calls to create
repositories, push the generated snapshots, and register remotes.
EOF
}

CONFIG_PATH="${CS_ROOT}/scripts/repo-visibility-plan.json"
DRY_RUN="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      if [[ $# -lt 2 ]]; then
        cs_die "--config requires a path"
      fi
      CONFIG_PATH="$2"
      shift 2
      ;;
    --run|--push)
      DRY_RUN="false"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      cs_die "Unsupported argument: $1"
      ;;
  esac
done

if [[ ! -f "${CONFIG_PATH}" ]]; then
  cs_die "Config file not found: ${CONFIG_PATH}"
fi

cs_require_cmd git
cs_require_cmd jq
cs_require_cmd gh
cs_require_cmd gitea
cs_require_cmd python3

DEFAULTS=$(jq -c '.defaults // {}' "${CONFIG_PATH}")
mapfile -t TARGETS < <(jq -c '.targets[]' "${CONFIG_PATH}")
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  cs_die "Config does not define any targets"
fi

CONFIG_GITEA_BASE_URL=$(jq -r '.gitea_base_url // empty' "${CONFIG_PATH}")
CONFIG_GITEA_CLONE_TEMPLATE=$(jq -r '.gitea_clone_url_template // empty' "${CONFIG_PATH}")

cs_log "Loaded ${CONFIG_PATH} (targets=${#TARGETS[@]}, dry-run=${DRY_RUN})"

populate_target_tree() {
  local dest_dir="$1"
  local includes_json="$2"
  local excludes_json="$3"
  python3 - "$dest_dir" "$includes_json" "$excludes_json" <<'PY'
import json
import os
import pathlib
import shutil
import subprocess
import sys

if len(sys.argv) != 4:
    raise SystemExit('populate_target_tree requires dest, includes, excludes')

dest = pathlib.Path(sys.argv[1])
root = pathlib.Path(os.environ['CS_ROOT'])
includes = json.loads(sys.argv[2])
excludes = json.loads(sys.argv[3])

tracked = subprocess.run(
    ['git', '-C', str(root), 'ls-files'],
    check=True,
    text=True,
    capture_output=True,
).stdout.splitlines()
tracked_set = set(tracked)

selected = set()
if includes:
    for pattern in includes:
        for candidate in root.glob(pattern):
            if not candidate.is_file():
                continue
            rel = candidate.relative_to(root).as_posix()
            if rel in tracked_set:
                selected.add(rel)
else:
    selected = tracked_set.copy()

filtered = []
for rel in sorted(selected):
    candidate = pathlib.Path(rel)
    skip = False
    for pattern in excludes:
        if pattern and candidate.match(pattern):
            skip = True
            break
    if skip:
        continue
    filtered.append(rel)

if not filtered:
    print('No tracked files matched include/exclude selectors', file=sys.stderr)
    sys.exit(1)

for rel in filtered:
    source = root / rel
    dest_file = dest / rel
    dest_file.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, dest_file)

print(len(filtered))
PY
}

push_to_github() {
  local owner="$1"
  local repo="$2"
  local branch="$3"
  local description="$4"
  local visibility="$5"
  local workdir="$6"

  local target_name="${owner}/${repo}"
  local visibility_flag
  case "${visibility}" in
    private|internal|public)
      visibility_flag="--${visibility}"
      ;;
    *)
      cs_warn "Unknown GitHub visibility '${visibility}'; defaulting to private"
      visibility_flag="--private"
      ;;
  esac

  cs_log "Ensuring GitHub repo ${target_name} (${visibility})"
  pushd "${workdir}" >/dev/null
  if ! gh repo view "${target_name}" >/dev/null 2>&1; then
    local gh_args=(repo create "${target_name}" "${visibility_flag}" --confirm)
    if [[ -n "${description:-}" ]]; then
      gh_args+=(--description "${description}")
    fi
    gh "${gh_args[@]}"
  else
    cs_log "GitHub repo ${target_name} already exists"
  fi
  local remote_url
  remote_url=$(gh repo view "${target_name}" --json sshUrl,httpUrl --jq '.sshUrl // .httpUrl')
  if git remote | grep -qx origin >/dev/null 2>&1; then
    git remote set-url origin "${remote_url}"
  else
    git remote add origin "${remote_url}"
  fi
  git push -u origin "${branch}"
  popd >/dev/null
}

push_to_gitea() {
  local owner="$1"
  local repo="$2"
  local branch="$3"
  local description="$4"
  local is_private="$5"
  local workdir="$6"

  if [[ -z "${CONFIG_GITEA_BASE_URL}" ]]; then
    cs_die "gitea_base_url is required to push to Gitea"
  fi

  cs_log "Ensuring Gitea repo ${owner}/${repo} (private=${is_private})"
  local global_opts=()
  if [[ -n "${GITEA_CONFIG:-}" ]]; then
    global_opts+=(--config "${GITEA_CONFIG}")
  fi
  local args=(admin repo create --owner "${owner}" --name "${repo}")
  if [[ "${is_private}" == "true" ]]; then
    args+=(--private)
  fi
  if [[ -n "${description:-}" ]]; then
    args+=(--description "${description}")
  fi
  if ! gitea "${global_opts[@]}" "${args[@]}"; then
    cs_warn "gitea repository creation returned non-zero; continuing"
  fi

  local base_url
  if [[ -n "${CONFIG_GITEA_CLONE_TEMPLATE}" ]]; then
    base_url="${CONFIG_GITEA_CLONE_TEMPLATE//\{owner\}/${owner}}"
    base_url="${base_url//\{repo\}/${repo}}"
  else
    base_url="${CONFIG_GITEA_BASE_URL%/}/${owner}/${repo}.git"
  fi
  if git -C "${workdir}" remote | grep -qx gitea >/dev/null 2>&1; then
    git -C "${workdir}" remote set-url gitea "${base_url}"
  else
    git -C "${workdir}" remote add gitea "${base_url}"
  fi
  git -C "${workdir}" push -u gitea "${branch}"
}

for target_blob in "${TARGETS[@]}"; do
  combined=$(jq -nc --argjson defaults "${DEFAULTS}" --argjson target "${target_blob}" '$defaults + $target')
  id=$(jq -r '.id // empty' <<< "${combined}")
  [[ -n "${id}" ]] || cs_die "Each target must define an id"
  name=$(jq -r '.name // empty' <<< "${combined}")
  [[ -n "${name}" ]] || cs_die "Target ${id} must define a name"

  description=$(jq -r '.description // empty' <<< "${combined}")
  branch=$(jq -r '.branch // "main"' <<< "${combined}")
  commit_message=$(jq -r '.commit_message // empty' <<< "${combined}")
  if [[ -z "${commit_message}" ]]; then
    commit_message="Segmented split for ${id}"
  fi

  visibility=$(jq -r '.visibility // empty' <<< "${combined}")
  github_visibility=$(jq -r '.github_visibility // empty' <<< "${combined}")
  if [[ -z "${github_visibility}" ]]; then
    case "${visibility}" in
      secret|private)
        github_visibility="private"
        ;;
      internal)
        github_visibility="internal"
        ;;
      public)
        github_visibility="public"
        ;;
      *)
        github_visibility="private"
        ;;
    esac
  fi

  gitea_private=$(jq -r '.gitea_private // empty' <<< "${combined}")
  if [[ -z "${gitea_private}" ]]; then
    case "${visibility}" in
      public)
        gitea_private="false"
        ;;
      *)
        gitea_private="true"
        ;;
    esac
  fi

  github_owner=$(jq -r '.github_owner // empty' <<< "${combined}")
  gitea_owner=$(jq -r '.gitea_owner // empty' <<< "${combined}")
  [[ -n "${github_owner}" ]] || cs_die "Target ${id} is missing github_owner"
  [[ -n "${gitea_owner}" ]] || cs_die "Target ${id} is missing gitea_owner"

  mapfile -t platform_list < <(jq -r '.platforms // ["github","gitea"] | .[]' <<< "${combined}")
  if [[ ${#platform_list[@]} -eq 0 ]]; then
    platform_list=(github gitea)
  fi
  declare -A seen_platform=()
  platforms=()
  for platform in "${platform_list[@]}"; do
    platform=$(printf '%s' "${platform}" | tr '[:upper:]' '[:lower:]')
    [[ -z "${platform}" ]] && continue
    if [[ -z "${seen_platform[${platform}]:-}" ]]; then
      seen_platform[${platform}]=1
      platforms+=("${platform}")
    fi
  done
  if [[ ${#platforms[@]} -eq 0 ]]; then
    platforms=(github gitea)
  fi

  includes_json=$(jq -c '.paths // []' <<< "${combined}")
  excludes_json=$(jq -c '.exclude // []' <<< "${combined}")

  cs_log "Preparing target ${id} (${name})"
  target_dir=$(mktemp -d "${TMPDIR:-/tmp}/repo-visibility-${id}-XXXX")
  selected_count=$(populate_target_tree "${target_dir}" "${includes_json}" "${excludes_json}")
  cs_log "Copied ${selected_count} files into ${target_dir}"

  git -C "${target_dir}" init
  git -C "${target_dir}" checkout -b "${branch}"
  git -C "${target_dir}" add -A
  git -C "${target_dir}" commit -m "${commit_message}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    cs_log "Dry-run mode: skipping GitHub/Gitea pushes for ${name}"
  else
    if cs_array_contains github "${platforms[@]}"; then
      push_to_github "${github_owner}" "${name}" "${branch}" "${description}" "${github_visibility}" "${target_dir}"
    fi
    if cs_array_contains gitea "${platforms[@]}"; then
      push_to_gitea "${gitea_owner}" "${name}" "${branch}" "${description}" "${gitea_private}" "${target_dir}"
    fi
  fi

  rm -rf "${target_dir}"
done

cs_log "All targets processed"
