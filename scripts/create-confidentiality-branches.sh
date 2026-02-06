#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CS_ROOT=$(git rev-parse --show-toplevel)
PLAN_PATH="${CS_ROOT}/scripts/repo-visibility-plan.json"
BASE_BRANCH=${BASE_BRANCH:-}
BRANCH_PREFIX=${BRANCH_PREFIX:-confidentiality}
DRY_RUN="false"

usage() {
  cat <<'EOF'
Usage: create-confidentiality-branches.sh [options]

Options:
  --config <path>         Plan JSON (default scripts/repo-visibility-plan.json)
  --base-branch <name>    Rama base desde donde crear los branches (por defecto HEAD)
  --prefix <text>         Prefijo para los branches creados (default confidentiality)
  --dry-run               Reporta sin crear branches
  -h, --help              Mostrar esta ayuda
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      PLAN_PATH="$2"
      shift 2
      ;;
    --base-branch)
      BASE_BRANCH="$2"
      shift 2
      ;;
    --prefix)
      BRANCH_PREFIX="$2"
      shift 2
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
      echo "Argumento desconocido: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "${PLAN_PATH}" ]]; then
  echo "Plan JSON no encontrado: ${PLAN_PATH}" >&2
  exit 1
fi

if [[ -z "${BASE_BRANCH}" ]]; then
  BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

echo "Base branch: ${BASE_BRANCH}"
mapfile -t TARGETS < <(jq -c '.targets[]' "${PLAN_PATH}")
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "No hay targets definidos en ${PLAN_PATH}" >&2
  exit 1
fi

copy_snapshot() {
  local dest_dir="$1"
  local includes_json="$2"
  local excludes_json="$3"
  python3 - "$dest_dir" "${CS_ROOT}" "${includes_json}" "${excludes_json}" <<'PY'
import glob
import json
import pathlib
import shutil
import subprocess
import sys

dest = pathlib.Path(sys.argv[1])
root = pathlib.Path(sys.argv[2])
includes = json.loads(sys.argv[3])
excludes = json.loads(sys.argv[4])

tracked = subprocess.run(
    ["git", "-C", str(root), "ls-files"],
    check=True,
    text=True,
    capture_output=True,
).stdout.splitlines()

selected = set()
if includes:
    for pattern in includes:
        pattern_path = root / pattern
        for candidate_str in glob.glob(str(pattern_path), recursive=True):
            candidate = pathlib.Path(candidate_str)
            if not candidate.is_file():
                continue
            rel = candidate.relative_to(root).as_posix()
            selected.add(rel)
else:
    selected = set(tracked)

filtered = []
tracked_set = set(tracked)
for rel in sorted(selected):
    if rel not in tracked_set:
        continue
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
    raise SystemExit("Ningún archivo coincidió con las reglas de inclusión/exclusión.")

for rel in filtered:
    src = root / rel
    dst = dest / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)

print(len(filtered))
PY
}

ORIG_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "${ORIG_BRANCH}" != "${BASE_BRANCH}" ]]; then
  echo "Cambiar temporalmente a ${BASE_BRANCH} para crear branches."
  git checkout "${BASE_BRANCH}"
fi

for target_blob in "${TARGETS[@]}"; do
  id=$(jq -r '.id' <<<"${target_blob}")
  [[ -n "${id}" ]] || { echo "Target sin id válido" >&2; exit 1; }
  branch_name="${BRANCH_PREFIX}/${id}"
  includes_json=$(jq -c '.paths // []' <<<"${target_blob}")
  excludes_json=$(jq -c '.exclude // []' <<<"${target_blob}")

  echo "Procesando ${id} → ${branch_name}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "DRY-RUN: se omite creación real para ${branch_name}"
    continue
  fi

  if git show-ref --quiet "refs/heads/${branch_name}"; then
    git branch -D "${branch_name}"
  fi

  worktree_dir=$(mktemp -d)
  git worktree add --detach "${worktree_dir}" "${BASE_BRANCH}"
  pushd "${worktree_dir}" >/dev/null
  git checkout --orphan "${branch_name}"
  git rm -rf . >/dev/null 2>&1 || true
  git clean -fdx >/dev/null 2>&1 || true

  copy_snapshot "${worktree_dir}" "${includes_json}" "${excludes_json}"

  git add -A
  if git diff --cached --quiet; then
    echo "No se copiaron archivos para ${branch_name}; se omite el commit"
  else
    git commit -m "Split confidencial ${id}"
  fi
  popd >/dev/null
  git worktree remove "${worktree_dir}"
done

if [[ "${ORIG_BRANCH}" != "${BASE_BRANCH}" ]]; then
  git checkout "${ORIG_BRANCH}"
fi

echo "Branches de confidencialidad generados."
