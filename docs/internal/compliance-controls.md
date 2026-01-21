# Compliance Controls Matrix (Draft)

## Scope and assumptions
- Current: single-user, local, offline preferred.
- Future: multi-tenant product.
- Dev: GitOps may use real data.
- Prod: GitOps outputs must be anonymized only.
- Sovereign compliance: data residency and air-gap required.

## Control domains and mappings

| Domain | SOC2 | ISO 27001 | NIST 800-53 | CIS | GDPR | HIPAA | PCI | Current evidence | Gaps | Recommended artifacts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Asset inventory | CC1/CC5 | A.5/A.8 | CM-8/PM-5 | 1 | Art. 30 | 164.310 | 12.5 | `README.md`, `docs/` | No formal inventory | Asset register, RoPA |
| Data classification | CC3 | A.5/A.8 | PL-2/RA-2 | 3 | Art. 5/25 | 164.312 | 3 | N/A | Missing policy | Data classification policy |
| Access control | CC6 | A.5/A.9 | AC-2/AC-6 | 5 | Art. 32 | 164.312 | 7 | Token-based UI auth + roles in `frontend/streamlit_app.py` | No central IdP/RBAC | Access policy, RBAC design |
| Encryption | CC6/CC7 | A.8/A.10 | SC-8/SC-13 | 3 | Art. 32 | 164.312 | 3/4 | N/A | No at-rest/in-transit plan | Encryption standard, KMS plan |
| Logging/audit | CC7 | A.8 | AU-2/AU-6 | 8 | Art. 5/30 | 164.312 | 10 | JSONL audit logs in `pipeline/analyze.py` and `frontend/streamlit_app.py` | No centralized audit trail | Audit logging policy |
| SDLC/change mgmt | CC8 | A.5/A.8 | CM-3/SA-10 | 16 | Art. 25 | 164.308 | 6 | `.github/workflows/*` | No formal change control | SDLC policy, change records |
| Vulnerability mgmt | CC7 | A.5 | RA-5 | 7 | Art. 32 | 164.308 | 6 | `ci-security.yml` runs SBOM + SCA + pip-audit | No patch cadence defined | SCA plan, SBOM, patch cadence |
| Backup/DR | CC7 | A.5/A.17 | CP-9/CP-10 | 11 | Art. 32 | 164.308 | 9 | N/A | No BCP/DR | Backup policy, restore tests |
| Third-party risk | CC1/CC3 | A.5/A.15 | SR-3 | 15 | Art. 28 | 164.308 | 12.8 | External deps in `requirements.txt` | No vendor review | TPRM checklist, DPA |
| Data minimization | CC3 | A.5 | PT-2 | 3 | Art. 5 | 164.306 | 3 | Redaction in `pipeline/analyze.py` + gating in `gitops/sync.sh` | Formal minimization rules missing | Redaction/anon spec |
| Sovereign/air-gap | CC3 | A.5 | SC-7/SC-12 | 4 | Art. 44 | 164.308 | 12.3 | `dev/bootstrap-dev.sh` downloads models | No offline mirror | Offline repo mirror, allowlist |

## Notes on current repo
- UI enforces token auth in prod with roles: `frontend/streamlit_app.py`, `docker-compose.prod.yml`.
- GitOps sync is gated by environment: `gitops/sync.sh`.
- Outputs are redacted in prod (env-gated): `pipeline/analyze.py`.
- Dependencies are pinned via `requirements.txt`, `requirements-docs.txt`, `frontend/requirements.txt`, plus per-service locks in `ingestor/requirements.txt` and `pipeline/requirements.txt`.
