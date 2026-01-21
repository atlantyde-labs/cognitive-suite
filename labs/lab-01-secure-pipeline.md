# Lab 01 - Secure Pipeline Baseline

- Difficulty: L1
- Objective: run analysis with redaction and generate audit evidence.

## Tasks
1) Run ingest and analysis in dev.
2) Run analysis in prod mode (redaction enabled).
3) Verify audit logs are written.

## Required outputs
- `outputs/insights/analysis.json`
- `outputs/audit/analysis.jsonl`

## Evidence
- PR diff or GitOps sync evidence.
- Screenshot or log excerpt showing redaction enabled.

## Guardrails
- No raw data synced in prod.
- Use `COGNITIVE_HASH_SALT` in prod.

## Rewards
- 50 points
- Badge: `secure-runner`
