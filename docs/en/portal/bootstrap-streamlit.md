# Adoption Bootstrap (Streamlit)

This guide provides full onboarding for new contributors using Streamlit as
the initial experience.

## 1. Objectives
- Configure the local environment.
- Run ingest -> analyze.
- Complete basic Labs and generate evidence.

## 2. Preparation
```bash
python cogctl.py init
```

## 3. Run onboarding
```bash
streamlit run frontend/onboarding_app.py --server.headless true --server.port 8501
```

Open: http://localhost:8501

## 4. Recommended configuration (simulated prod)
```bash
export COGNITIVE_ENV=prod
export COGNITIVE_HASH_SALT=change_me
export COGNITIVE_UI_TOKEN_VIEWER=viewer_token
export COGNITIVE_UI_TOKEN_ANALYST=analyst_token
export COGNITIVE_UI_TOKEN_ADMIN=admin_token
```

## 5. Run pipeline
```bash
python cogctl.py ingest demo_input.json
python cogctl.py analyze
```

## 6. Minimum evidence
- `outputs/insights/analysis.json`
- `outputs/audit/analysis.jsonl`
- PR with redacted outputs (prod only)

## 7. Available Labs
- Lab 01: Secure Pipeline Baseline
- Lab 02: GitOps Redacted Sync
- Lab 03: Hardening Runbook

## 8. Good practices
- Do not sync raw outputs in prod.
- Keep tokens separated by environment.
- Attach logs and SBOMs as evidence.
