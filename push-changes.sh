#!/usr/bin/env bash
# Script para pushear todos los cambios al repositorio

set -euo pipefail

echo "🚀 Starting git push process..."
echo ""

# Step 1: Stage all changes
echo "[1/4] Staging all changes..."
git add -A
echo "✓ All changes staged"
echo ""

# Step 2: Check what will be committed
echo "[2/4] Changes to commit:"
git status --short
echo ""

# Step 3: Commit
echo "[3/4] Creating commit..."
git commit -m "feat: VSCode development tooling improvements and E2E local validation

- Added .vscode/ configuration (extensions, settings, tasks, keybindings)
- Added 18 recommended VSCode extensions (Ruff, ShellCheck, Pylance, GitLens, etc.)
- Added 12 automated tasks for linting, formatting, testing, and building
- Added 5 keyboard shortcuts for common development tasks
- Created comprehensive documentation (6 markdown files)
- Added E2E local validation script with no timeout limits
- Added E2E configuration template
- Added local development environment setup script
- Improved developer experience with on-save formatting and real-time linting

This improves workflow quality and integrates with PR #37 (Scripts Bash Managements Ops Systems)"

echo "✓ Commit created"
echo ""

# Step 4: Push
echo "[4/4] Pushing to remote..."
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $BRANCH"
git push -u origin "$BRANCH"

echo ""
echo "✅ All changes successfully pushed to $BRANCH"
echo ""
echo "📊 Summary:"
echo "  • VSCode configuration files: 5 files"
echo "  • Documentation files: 8 files"
echo "  • Scripts: 2 files"
echo "  • Configuration examples: 2 files"
echo "  • Total: 17 new files"
echo ""
echo "🎯 Next steps:"
echo "  1. Go to GitHub PR #37"
echo "  2. Verify the changes in the PR"
echo "  3. Share with team"
