# Lab 03 - Hardening Runbook

- Difficulty: L3
- Objective: validate container hardening and document risks.

## Tasks
1) Confirm non-root user, read-only FS, and no-new-privileges in prod.
2) Run compose config validation.
3) Write a short hardening note.

## Required outputs
- `docker-compose.prod.yml` evidence (config or diff).
- `docs/internal/examples/hardening-note.md`.

## Evidence
- CI logs or `docker compose config` output.

## Guardrails
- Do not relax security settings to pass tests.

## Rewards
- 200 points
- Badge: `runtime-guardian`
