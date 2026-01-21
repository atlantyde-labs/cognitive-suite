# Incident Response Example (Fictional)

## Incident summary
- Incident ID: IR-2026-001
- Severity: SEV2
- Detected at: 2026-02-10 09:12 UTC
- Resolved at: 2026-02-10 12:05 UTC
- Summary: unauthorized access attempt to UI detected and blocked

## Timeline
- 09:12 UTC: alert triggered by repeated failed logins
- 09:15 UTC: access token rotated
- 09:20 UTC: audit logs reviewed
- 10:00 UTC: source IP blocked at edge
- 12:05 UTC: incident closed

## Containment actions
- Disabled GitOps sync during review
- Rotated UI tokens

## Root cause
- Token reused from test environment

## Corrective actions
- Enforce unique tokens per environment
- Add token rotation schedule

## Evidence
- Audit logs: audit/ui_access.jsonl
- Change record: control-evidence-log.md
