# Policies (Draft)

## Data classification
- Levels: public, internal, confidential, restricted.
- Default: all ingested data is confidential or restricted.
- Owners approve classification for any dataset.

## Data retention and deletion
- Dev: retain raw inputs for 30 days max, outputs for 90 days max.
- Prod: raw inputs disabled by default; only anonymized outputs retained.
- Deletion: on request within 7 days; verify removal from GitOps remotes.

## Data minimization and anonymization
- Store only fields required for analysis outputs.
- Redact personal identifiers from summaries and entities.
- Prohibit syncing raw data to remote repos in prod.
- Production runs must use `COGNITIVE_ENV=prod` and set `COGNITIVE_HASH_SALT`.
- GitOps in prod must use `GITOPS_DATA_MODE=redacted`.

## Access control
- Principle of least privilege.
- MFA required for admin and CI/CD.
- RBAC roles: viewer, analyst, admin.
- UI access requires tokens in production (COGNITIVE_UI_TOKEN_*).

## Encryption and key management
- TLS for UI/API in multi-tenant or prod.
- Encrypt data at rest (disk or object storage).
- Centralized key management (KMS or vault).

## Logging and audit
- Log who ran analysis, when, input source, output location.
- Store audit logs in append-only storage.
- Retain audit logs for 1 year minimum.

## Secure SDLC
- Code reviews required for changes to security-sensitive areas.
- SCA and SBOM required for release builds (Grype + SBOM artifacts).
- Dependency updates on a defined cadence.
- Dependency versions must be pinned via lockfiles (`requirements*.txt`).

## Vulnerability management
- Triage within 5 business days.
- Patch SLAs: critical 7 days, high 14 days, medium 30 days.
- Secrets scanning required on PRs (Gitleaks).

## Incident response
- Defined on-call and escalation path.
- Post-incident review and corrective actions tracked.

## Sovereign and air-gap rules
- Production builds must be reproducible offline.
- No external network egress in prod unless approved.
- Data must stay in approved regions.
