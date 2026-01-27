# Access Review Example (Fictional)

## 1. Review metadata
- Review period: 2026-01
- Reviewer: security@example.test
- Date: 2026-02-05
- Scope: prod UI, GitOps repo, CI

## 2. Access inventory
| User / Service | Role | Access scope | Justification | Last used | Action |
| --- | --- | --- | --- | --- | --- |
| alice@example.test | admin | prod UI | ops owner | 2026-02-03 | keep |
| bob@example.test | analyst | prod UI | analyst | 2026-02-02 | keep |
| svc-gitops | admin | repo write | automation | 2026-02-01 | keep |
| temp-user@example.test | viewer | prod UI | test | 2025-12-01 | remove |

## 3. Findings
- Over-privileged accounts: none
- Orphaned accounts: temp-user@example.test
- MFA coverage: 100%

## 4. Actions
- Remove access: temp-user@example.test
- Reduce access: none
- Exceptions approved: none

## 5. Evidence
- Access export snapshot: audit/access-export-2026-02-05.csv
- Approvals: change-log-2026-02-05.md
