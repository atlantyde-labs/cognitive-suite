# Control Evidence Log Example (Fictional)

## Evidence register
| Date | Control ID | Description | Artifact | Owner | Status |
| --- | --- | --- | --- | --- | --- |
| 2026-02-10 | AU-2 | Audit logging enabled | audit/analysis.jsonl | ops@example.test | verified |
| 2026-02-10 | AU-2 | UI access logging enabled | audit/ui_access.jsonl | ops@example.test | verified |
| 2026-02-11 | RA-5 | SCA scan results | ci-security.yml logs | sec@example.test | verified |
| 2026-02-11 | SBOM | SBOM artifacts | sbom.spdx.json, sbom.cdx.json | sec@example.test | verified |
| 2026-02-12 | CM-6 | Hardening config applied | docker-compose.prod.yml | ops@example.test | verified |

## Notes
- Store artifacts in a controlled location.
- Link to build logs, SBOMs, audit logs, and test reports.
