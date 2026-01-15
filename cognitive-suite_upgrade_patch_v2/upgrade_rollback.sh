#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./upgrade_rollback.sh upgrade <bundle.zip>
  ./upgrade_rollback.sh rollback <backup-branch>

Behavior:
  - upgrade: creates a backup branch, then extracts bundle.zip and overlays files (no deletion).
  - rollback: restores working tree to the backup branch state.

Requirements:
  - git, unzip, rsync
USAGE
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1"; exit 2; }
}

is_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

cmd_upgrade() {
  local bundle="${1:-}"
  [[ -n "$bundle" ]] || { echo "Missing bundle.zip"; usage; exit 2; }
  [[ -f "$bundle" ]] || { echo "Bundle not found: $bundle"; exit 2; }

  require_cmd git
  require_cmd unzip
  require_cmd rsync

  is_git_repo || { echo "Run inside a git repository"; exit 2; }

  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  local backup="backup-${ts}"

  echo "Creating backup branch: ${backup}"
  git status --porcelain
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree not clean. Commit/stash first."
    exit 2
  fi
  git branch "${backup}"

  local tmpdir
  tmpdir="$(mktemp -d)"
  echo "Extracting bundle to: ${tmpdir}"
  unzip -q "$bundle" -d "$tmpdir"

  echo "Overlaying files (non-destructive)..."
  rsync -av "$tmpdir"/ ./ --exclude ".git" --exclude ".venv" --exclude "data" --exclude "outputs"

  echo "Done. Review changes with: git status && git diff"
  echo "If needed: ./upgrade_rollback.sh rollback ${backup}"
}

cmd_rollback() {
  local backup="${1:-}"
  [[ -n "$backup" ]] || { echo "Missing backup branch"; usage; exit 2; }

  require_cmd git
  is_git_repo || { echo "Run inside a git repository"; exit 2; }

  if ! git show-ref --verify --quiet "refs/heads/${backup}"; then
    echo "Backup branch not found: ${backup}"
    exit 2
  fi

  echo "Restoring working tree from ${backup} ..."
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree not clean. Commit/stash first."
    exit 2
  fi

  git checkout "${backup}"
  git checkout -  # return to previous branch
  git reset --hard "${backup}"
  echo "Rollback complete."
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    upgrade) shift; cmd_upgrade "$@";;
    rollback) shift; cmd_rollback "$@";;
    -h|--help|"") usage;;
    *) echo "Unknown command: $cmd"; usage; exit 2;;
  esac
}
main "$@"
