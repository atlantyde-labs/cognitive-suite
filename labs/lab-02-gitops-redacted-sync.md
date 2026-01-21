# Lab 02 - GitOps Redacted Sync

- Difficulty: L2
- Objective: sync redacted outputs to a remote repo.

## Tasks
1) Set `COGNITIVE_ENV=prod` and `GITOPS_DATA_MODE=redacted`.
2) Generate redacted analysis.
3) Run `gitops/sync.sh` to push outputs.

## Required outputs
- PR with `insights/analysis.json` only.
- Evidence of redaction in output.

## Evidence
- CI logs and audit logs.
- GitOps commit hash.

## Guardrails
- No raw outputs in remote repo.

## Rewards
- 100 points
- Badge: `gitops-steward`
