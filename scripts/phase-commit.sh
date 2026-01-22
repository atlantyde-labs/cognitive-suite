#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/phase-commit.sh --list
  bash scripts/phase-commit.sh --phase <number|name> [--dry-run]
  bash scripts/phase-commit.sh --all [--dry-run]

Notes:
  - Run after the merge overlay is applied (rsync/upgrade_rollback.sh).
  - The index must be clean before committing each phase.
USAGE
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 2; }; }

PHASE_NAMES=(
  "phase-1-foundation"
  "phase-2-docs"
  "phase-3-ci-cd"
  "phase-4-tooling-ops"
  "phase-5-core-app"
)

PHASE_COMMITS=(
  "phase(1): governance and onboarding"
  "phase(2): docs and mkdocs site"
  "phase(3): ci/cd workflows and security automation"
  "phase(4): tooling and ops automation"
  "phase(5): core app and insight schema output"
)

PHASE_PATHS=(
  "README.md LICENSE SECURITY.md CONTRIBUTING.md CODE_OF_CONDUCT.md .gitignore .dockerignore PR_DESCRIPTION.md .github/pull_request_template.md .github/CODEOWNERS"
  "mkdocs.yml docs knowledge requirements-docs.txt PATCH_MKDOCS_NAV_APPEND.md"
  ".github/workflows .github/ISSUE_TEMPLATE .github/labels.yml .github/project_v2 .gitleaks.toml requirements-ci.txt scripts/validate-knowledge.py"
  "Makefile dev ops scripts gitops test-bootstrap.sh upgrade_rollback.sh commit_from_bundles.sh"
  "ingestor pipeline frontend vectorstore wrappers cogctl.py schemas datasets requirements.txt docker-compose.yml docker-compose.prod.yml"
)

DRY_RUN=0
MODE=""
TARGET=""

list_phases() {
  for i in "${!PHASE_NAMES[@]}"; do
    local number=$((i + 1))
    echo "${number}. ${PHASE_NAMES[$i]}"
    echo "   commit: ${PHASE_COMMITS[$i]}"
    echo "   paths:  ${PHASE_PATHS[$i]}"
  done
}

resolve_phase_index() {
  local input="$1"
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    local idx=$((input - 1))
    if [[ "$idx" -lt 0 || "$idx" -ge "${#PHASE_NAMES[@]}" ]]; then
      echo "Invalid phase number: $input"
      exit 2
    fi
    echo "$idx"
    return 0
  fi

  for i in "${!PHASE_NAMES[@]}"; do
    if [[ "${PHASE_NAMES[$i]}" == "$input" ]]; then
      echo "$i"
      return 0
    fi
  done

  echo "Unknown phase: $input"
  exit 2
}

ensure_clean_index() {
  if ! git diff --cached --quiet; then
    echo "Staging area not clean. Commit or unstage first."
    exit 2
  fi
}

stage_phase() {
  local idx="$1"
  local paths="${PHASE_PATHS[$idx]}"
  local -a add_paths=()

  for path in $paths; do
    if [[ -e "$path" ]]; then
      add_paths+=("$path")
    else
      echo "skip missing path: $path"
    fi
  done

  if [[ "${#add_paths[@]}" -eq 0 ]]; then
    echo "No existing paths for ${PHASE_NAMES[$idx]}"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Would add: ${add_paths[*]}"
    return 0
  fi

  git add -A -- "${add_paths[@]}"
}

commit_phase() {
  local idx="$1"
  ensure_clean_index
  stage_phase "$idx"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi

  if git diff --cached --quiet; then
    echo "No changes staged for ${PHASE_NAMES[$idx]}"
    return 0
  fi

  git commit -m "${PHASE_COMMITS[$idx]}"
}

main() {
  need git

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list) MODE="list"; shift;;
      --all) MODE="all"; shift;;
      --phase) MODE="phase"; TARGET="${2:-}"; shift 2;;
      --dry-run) DRY_RUN=1; shift;;
      -h|--help) usage; exit 0;;
      *) echo "Unknown arg: $1"; usage; exit 2;;
    esac
  done

  if [[ -z "$MODE" ]]; then
    usage
    exit 2
  fi

  case "$MODE" in
    list) list_phases;;
    all)
      for i in "${!PHASE_NAMES[@]}"; do
        commit_phase "$i"
      done
      ;;
    phase)
      if [[ -z "$TARGET" ]]; then
        echo "Missing phase target"
        exit 2
      fi
      commit_phase "$(resolve_phase_index "$TARGET")"
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
