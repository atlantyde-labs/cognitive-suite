# Learning by Doing: GitOps + Streamlit (Early Adopters)

This guide is a hands-on path for early adopters to run the suite locally, learn GitOps flow, and validate the Streamlit UI in a safe way.

## 0. Goals
- Run ingest -> analyze -> view in Streamlit.
- Practice GitOps sync with redacted outputs.
- Validate audit logs and access controls.

## 1. Prerequisites
- Python 3.10+
- Docker (optional)
- Git

## 2. Local run (dev)
```bash
python cogctl.py init
python cogctl.py ingest demo_input.json
python cogctl.py analyze
```

View results:
```bash
python frontend/app.py
```

## 3. Streamlit UI (local)
```bash
streamlit run frontend/streamlit_app.py --server.headless true --server.port 8501
```
Open: http://localhost:8501

## 4. GitOps sync (dev with real data)
Set repo target:
```bash
export GIT_REPO_URL=git@github.com:example-org/example-repo.git
export GIT_BRANCH=main
export COGNITIVE_ENV=dev
```

Sync (dev allows raw outputs):
```bash
bash gitops/sync.sh
```

## 5. GitOps sync (prod redacted outputs only)
```bash
export COGNITIVE_ENV=prod
export GITOPS_DATA_MODE=redacted
export COGNITIVE_HASH_SALT=change_me
```

Run analysis with redaction:
```bash
python pipeline/analyze.py --input outputs/raw --output outputs/insights/analysis.json
```

Sync redacted outputs:
```bash
bash gitops/sync.sh
```

## 6. Streamlit auth (prod behavior)
Set tokens:
```bash
export COGNITIVE_UI_TOKEN_VIEWER=viewer_token
export COGNITIVE_UI_TOKEN_ANALYST=analyst_token
export COGNITIVE_UI_TOKEN_ADMIN=admin_token
export COGNITIVE_ENV=prod
```

Start UI:
```bash
streamlit run frontend/streamlit_app.py --server.headless true --server.port 8501
```

## 7. Audit logs (evidence)
- Analysis audit log: `outputs/audit/analysis.jsonl`
- UI access log: `outputs/audit/ui_access.jsonl`

## 8. Learning tasks (checklist)
- [ ] Run ingest -> analyze locally
- [ ] Open Streamlit and review a record
- [ ] Enable redaction and confirm outputs are masked
- [ ] Sync redacted outputs via GitOps
- [ ] Review audit logs and record evidence

## 9. Air-gap note
- For sovereign builds, mirror dependencies and models offline.
- Disable external network egress in prod.

## Success criteria
- Redacted outputs only in prod GitOps
- UI access is token gated
- Audit logs captured for analysis and access
