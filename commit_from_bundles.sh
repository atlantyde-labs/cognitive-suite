#!/usr/bin/env bash
set -euo pipefail

# commit_from_bundles.sh
# Applies Cognitive Suite patch bundles (v2->v3->v4) to an existing branch
# and commits/pushes each step. Also ensures labels exist/are updated.

REPO_DEFAULT="atlantyde-labs/cognitive-suite"

usage() {
  cat <<'USAGE'
Usage:
  ./commit_from_bundles.sh \
    --branch temp \
    --repo atlantyde-labs/cognitive-suite \
    --v2 /path/to/cognitive-suite_upgrade_patch_v2.zip \
    --v3 /path/to/cognitive-suite_upgrade_patch_v3.zip \
    --v4 /path/to/cognitive-suite_upgrade_patch_v4.zip \
    [--workdir /tmp/cognitive-suite-work]

Notes:
- The branch should already exist on origin; if not, the script will create it.
- Bundles are applied with rsync overlay (non-destructive).
- Labels are ensured via gh label create/edit (exact names/colors/descriptions).
USAGE
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 2; }; }

BRANCH=""
REPO="$REPO_DEFAULT"
V2=""
V3=""
V4=""
WORKDIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) BRANCH="$2"; shift 2;;
    --repo) REPO="$2"; shift 2;;
    --v2) V2="$2"; shift 2;;
    --v3) V3="$2"; shift 2;;
    --v4) V4="$2"; shift 2;;
    --workdir) WORKDIR="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

[[ -n "$BRANCH" ]] || { echo "Missing --branch"; usage; exit 2; }
[[ -f "$V2" ]] || { echo "Missing or not found --v2: $V2"; exit 2; }
[[ -f "$V3" ]] || { echo "Missing or not found --v3: $V3"; exit 2; }
[[ -f "$V4" ]] || { echo "Missing or not found --v4: $V4"; exit 2; }

need gh
need git
need unzip
need rsync

# Validate gh auth
gh auth status >/dev/null 2>&1 || { echo "Run: gh auth login"; exit 2; }

# Prepare workdir
if [[ -z "$WORKDIR" ]]; then
  WORKDIR="$(mktemp -d)"
else
  mkdir -p "$WORKDIR"
fi

echo "Workdir: $WORKDIR"
cd "$WORKDIR"

# Clone if missing
if [[ ! -d "cognitive-suite/.git" ]]; then
  echo "Cloning $REPO ..."
  gh repo clone "$REPO" cognitive-suite
fi

cd cognitive-suite

# Fetch and checkout branch (existing or create)
git fetch origin --prune
if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  echo "Checking out existing remote branch: $BRANCH"
  git checkout -B "$BRANCH" "origin/$BRANCH"
else
  echo "Branch $BRANCH not found on origin. Creating from default branch..."
  DEFAULT_BRANCH="$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)"
  git checkout -B "$BRANCH" "origin/$DEFAULT_BRANCH"
fi

# Ensure clean tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree not clean. Commit/stash first."
  git status --porcelain
  exit 2
fi

apply_bundle() {
  local zip="$1"
  local name="$2"
  local commit_msg="$3"

  echo "Applying bundle $name: $zip"
  local tmpdir
  tmpdir="$(mktemp -d)"
  unzip -q "$zip" -d "$tmpdir"

  # Overlay without deleting; protect runtime dirs and secrets-ish stuff
  rsync -av "$tmpdir"/ ./ \
    --exclude ".git" \
    --exclude ".venv" \
    --exclude "data" \
    --exclude "outputs" \
    --exclude ".env" \
    --exclude "qdrant_storage" \
    --exclude "local_runtime" \
    --exclude "tmp" \
    --exclude "logs"

  rm -rf "$tmpdir"

  git add -A

  if git diff --cached --quiet; then
    echo "No changes staged for $name (already applied?)"
    return 0
  fi

  git commit -m "$commit_msg"
}

# 1) Apply v2
apply_bundle "$V2" "v2" \
  "upgrade(v2): README+CONTRIBUTING + CI optimized + CPU-only docker + dockerignore + upgrade script"

# 2) Apply v3
apply_bundle "$V3" "v3" \
  "upgrade(v3): mkdocs-material requirements + pages auto-deploy + project v2 gamification workflows + metrics page"

# 3) Apply v4
apply_bundle "$V4" "v4" \
  "upgrade(v4): mkdocs.yml complete nav + metrics (learning/delivery/ci/ecosystem) + identity-ecosystem portal page"

echo "Pushing branch $BRANCH ..."
git push -u origin "$BRANCH"

# Ensure exact labels (create if missing, update if exists)
# Format: name|color|description
LABELS=(
  "good first issue|7057ff|Good first issue for new contributors"
  "learning-task|f9d0c4|Learning by Doing task (guided challenge)"
  "ci-gitops|1d76db|CI/CD, GitOps, automation and release engineering"
  "automation|0e8a16|Automation scripts, workflows, bots"
  "ci-boott|b60205|Bootstrap and operational tests (CI smoke / e2e)"
)

echo "Ensuring labels exist/updated..."
for entry in "${LABELS[@]}"; do
  IFS="|" read -r name color desc <<< "$entry"
  if gh label view "$name" --repo "$REPO" >/dev/null 2>&1; then
    gh label edit "$name" --repo "$REPO" --color "$color" --description "$desc" >/dev/null
    echo "Updated label: $name"
  else
    gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" >/dev/null
    echo "Created label: $name"
  fi
done

echo
echo "✅ Done."
echo "Branch pushed: $BRANCH"
echo "Repo: $REPO"
echo "Workdir kept at: $WORKDIR"
echo
echo "Next:"
echo " - Check Actions: gh run list --repo $REPO --branch $BRANCH"
echo " - If you enabled Pages workflow: Settings -> Pages -> Source = GitHub Actions"
