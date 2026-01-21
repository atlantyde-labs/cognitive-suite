# Compliance Roadmap (Draft)

## Phase 0 - Local single-user (now)
- Document data classification, retention, and deletion policy.
- Add basic anonymization/redaction step before any GitOps sync in dev.
- Add local access guard for UI (simple password or token for Streamlit).
- Define allowlist/denylist for outbound network calls.
- Create minimal audit log for analysis runs (who/when/what input).

## Phase 1 - Multi-tenant beta
- Implement authentication + RBAC for UI and API.
- Separate tenants by storage and access boundaries.
- Add encryption at rest and in transit (TLS for UI/API).
- Add SCA/SBOM in CI (pip-audit, grype, gitleaks, sbom export).
- Add centralized logging and basic alerting.

## Phase 2 - Sovereign production / air-gap
- Offline dependency mirror and model registry.
- No external network egress in prod (allowlist only).
- Full data residency evidence and backup location controls.
- DR plan and restore tests with audit evidence.
- Formalize SOC2/ISO evidence collection and internal audits.

## Exit criteria
- P0 complete: policies published and enforced in dev tooling.
- P1 complete: multi-tenant isolation + auth + encryption + audit logs.
- P2 complete: air-gap build, sovereign data residency proof, and DR evidence.
