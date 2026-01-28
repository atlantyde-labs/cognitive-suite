#!/usr/bin/env bash
set -euo pipefail

# E2E Local Validation Script (NO TIMEOUT)
# Ejecuta el suite E2E completo localmente sin límites de tiempo
# Uso: bash scripts/e2e-local-validation.sh [--verbose] [--output-dir PATH]

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

# Variables
OUTPUT_DIR="${PROJECT_ROOT}/outputs/e2e-local"
VERBOSE=false
START_TIME=$(date +%s)

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Logging functions
log() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [E2E LOCAL] $*"
}

error() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [E2E LOCAL:ERROR] $*" >&2
}

elapsed_time() {
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - START_TIME))
  printf "%02d:%02d:%02d" $((duration / 3600)) $((duration % 3600 / 60)) $((duration % 60))
}

# Create output directory
mkdir -p "${OUTPUT_DIR}"
cd "${PROJECT_ROOT}"

log "=========================================="
log "E2E LOCAL VALIDATION - NO TIMEOUT"
log "=========================================="
log "Project root: ${PROJECT_ROOT}"
log "Output dir:   ${OUTPUT_DIR}"
log "Verbose:      ${VERBOSE}"
log ""

# Track results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
FAILED_STEPS=()

# Function to run test step
run_step() {
  local step_name=$1
  local step_command=$2

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  log "[$((TOTAL_TESTS))/11] Running: $step_name"

  if eval "$step_command" 2>&1 | tee -a "${OUTPUT_DIR}/${TOTAL_TESTS}-${step_name// /-}.log"; then
    log "  ✓ PASS: $step_name ($(elapsed_time))"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    local exit_code=$?
    error "  ✗ FAIL: $step_name (exit code: $exit_code)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    FAILED_STEPS+=("$step_name")
  fi
  log ""
}

# ============================================
# 1. Install tooling
# ============================================
run_step "Install tooling" "
  sudo apt-get update -qq
  sudo apt-get install -y -qq shellcheck ripgrep jq python3-pip 2>&1 | grep -v '^Reading\|^Building\|^Selecting'
"

# ============================================
# 2. Install Python dependencies
# ============================================
run_step "Install Python dependencies" "
  python3 -m pip install --upgrade pip --quiet
  python3 -m pip install jsonschema --quiet
"

# ============================================
# 3. Shellcheck scripts
# ============================================
run_step "Shellcheck scripts" "
  mkdir -p ${OUTPUT_DIR}
  scripts=\$(rg --files -g '*.sh' bash/GitDevSecDataAIOps scripts)
  if [[ -n \"\${scripts}\" ]]; then
    printf '%s\n' \${scripts} > ${OUTPUT_DIR}/shellcheck-files.txt
    bash -n \${scripts} 2> ${OUTPUT_DIR}/bash-n.txt || true
    shellcheck \${scripts} | tee ${OUTPUT_DIR}/shellcheck.txt || true
  else
    echo 'No shell scripts found' > ${OUTPUT_DIR}/shellcheck.txt
  fi
"

# ============================================
# 4. Python syntax check
# ============================================
run_step "Python syntax check" "
  mkdir -p ${OUTPUT_DIR}
  pyfiles=\$(rg --files -g '*.py' bash/GitDevSecDataAIOps)
  if [[ -n \"\${pyfiles}\" ]]; then
    printf '%s\n' \${pyfiles} > ${OUTPUT_DIR}/python-files.txt
    python3 -m py_compile \${pyfiles}
  else
    echo 'No Python files found' > ${OUTPUT_DIR}/python-files.txt
  fi
"

# ============================================
# 5. Validate fine-tune dataset
# ============================================
run_step "Validate fine-tune dataset" "
  mkdir -p ${OUTPUT_DIR}/ft_outputs
  python3 bash/GitDevSecDataAIOps/tooling/fine-tune/ft_prepare.py \
    datasets/atlantityqa_cognitive_suite_ft_v2.jsonl --validate-only 2>&1 | tee ${OUTPUT_DIR}/ft-validate.log
  python3 bash/GitDevSecDataAIOps/tooling/fine-tune/ft_prepare.py \
    datasets/atlantityqa_cognitive_suite_ft_v2.jsonl --split-by-sensitivity --out-dir ${OUTPUT_DIR}/ft_outputs 2>&1 | tee -a ${OUTPUT_DIR}/ft-validate.log
"

# ============================================
# 6. Model inventory (dry-run)
# ============================================
run_step "Model inventory (dry-run)" "
  python3 bash/GitDevSecDataAIOps/tooling/models/model_inventory.py \
    --roots datasets \
    --output ${OUTPUT_DIR}/model-inventory.json \
    --whitelist-output ${OUTPUT_DIR}/model-whitelist.json \
    --alerts-output ${OUTPUT_DIR}/model-alerts.json \
    --hash none \
    --default-sensitivity INTERNAL \
    --dry-run 2>&1 | tee ${OUTPUT_DIR}/model-inventory.log
"

# ============================================
# 7. Mocked ops simulation
# ============================================
run_step "Mocked ops simulation (air-gap + Proxmox)" "
  EVIDENCE_DIR=${OUTPUT_DIR} bash bash/GitDevSecDataAIOps/tooling/tests/mock-e2e.sh 2>&1 | tee ${OUTPUT_DIR}/mock-e2e.log
"

# ============================================
# 8. Validate GitHub migration ClickOps
# ============================================
run_step "Validate GitHub migration ClickOps schema" "
  python3 bash/GitDevSecDataAIOps/tooling/forensics/validate-jsonl.py \
    --schema schemas/github-migration-clickops.schema.json \
    --input datasets/github-migration-clickops.example.jsonl 2>&1 | tee ${OUTPUT_DIR}/clickops-validate.log
"

# ============================================
# 9. Validate Bot ClickOps
# ============================================
run_step "Validate Bot ClickOps schema" "
  python3 bash/GitDevSecDataAIOps/tooling/forensics/validate-jsonl.py \
    --schema schemas/bot-clickops.schema.json \
    --input datasets/bot-clickops.example.jsonl 2>&1 | tee ${OUTPUT_DIR}/bot-clickops-validate.log
"

# ============================================
# 10. Ops state machine (mocked)
# ============================================
run_step "Ops state machine (mocked)" "
  OUTPUT_DIR=${OUTPUT_DIR}/ops-state \
    REQUIRE_CLEAN_GIT='false' \
    REQUIRE_GITLEAKS='false' \
    REQUIRE_DETECT_SECRETS='false' \
    HITL_REQUIRED='false' \
    REQUIRE_APPROVALS='false' \
    RUN_ORCHESTRATOR_DRY_RUN='false' \
    bash bash/GitDevSecDataAIOps/tooling/ops-state/ops-state-machine.sh 2>&1 | tee ${OUTPUT_DIR}/ops-state.log
"

# ============================================
# 11. Write evidence summary
# ============================================
run_step "Write evidence summary" "
  python3 - <<'PY' > ${OUTPUT_DIR}/summary.json
import json
import os
import subprocess
from datetime import datetime, timezone

try:
  commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
except:
  commit = 'unknown'

summary = {
  'timestamp': datetime.now(timezone.utc).isoformat(),
  'commit': commit,
  'total_tests': $TOTAL_TESTS,
  'passed': $PASSED_TESTS,
  'failed': $FAILED_TESTS,
  'success_rate': f'{($PASSED_TESTS * 100 / $TOTAL_TESTS):.1f}%',
  'duration': '$(elapsed_time)',
  'environment': 'local-no-timeout',
  'workflow': 'E2E Local Validation'
}
print(json.dumps(summary, ensure_ascii=True, indent=2))
PY
"

# ============================================
# FINAL SUMMARY
# ============================================
log ""
log "=========================================="
log "E2E LOCAL VALIDATION - SUMMARY"
log "=========================================="
log "Total tests:     $TOTAL_TESTS"
log "Passed:          $PASSED_TESTS ✓"
log "Failed:          $FAILED_TESTS ✗"
log "Success rate:    $(printf "%.1f%%" $((PASSED_TESTS * 100 / TOTAL_TESTS)))"
log "Total duration:  $(elapsed_time)"
log "Output dir:      ${OUTPUT_DIR}"
log ""

if [[ $FAILED_TESTS -gt 0 ]]; then
  error "FAILED STEPS:"
  for step in "${FAILED_STEPS[@]}"; do
    error "  - $step"
  done
  error ""
  error "Check logs in: ${OUTPUT_DIR}"
  exit 1
else
  log "✓ ALL TESTS PASSED!"
  log ""
  log "Evidence stored in: ${OUTPUT_DIR}"
  log "Summary: ${OUTPUT_DIR}/summary.json"
  exit 0
fi
