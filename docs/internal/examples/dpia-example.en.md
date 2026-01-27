# DPIA Example (Fictional)

## 1. Overview
- Project: Cognitive Suite
- Environment: prod
- Processing owner: Example Cooperative Ltd
- Date: 2026-02-14
- Version: 1.0

## 2. Processing description
- Purpose of processing: analyze internal documents to produce redacted insights
- Data sources: user provided files in data/input
- Data flow summary: ingest -> analyze -> redacted outputs -> GitOps sync
- Systems involved: ingestor, pipeline, frontend, gitops
- Data storage locations: local host volume, GitOps repo (redacted only)
- Data retention period: raw 0 days (disabled), outputs 90 days

## 3. Data categories
- Personal data categories: names, emails, work content
- Special categories (if any): none expected
- Data subjects: employees, contractors

## 4. Lawful basis (GDPR)
- Lawful basis: legitimate interest
- Legitimate interest assessment: internal knowledge management
- Consent mechanism: not used

## 5. Necessity and proportionality
- Is the data necessary for the purpose: yes
- Data minimization measures: redaction, hashing, no raw outputs in prod
- Access controls: token auth + RBAC
- Transparency and user notice: internal policy notice

## 6. Risk assessment
- Identified risks: unauthorized access to outputs; accidental sync of raw data
- Likelihood: medium
- Impact: high
- Risk rating: high

## 7. Mitigation measures
- Technical controls: redaction, audit logs, read-only FS, RBAC
- Organizational controls: access review, change management
- Residual risk after mitigation: medium

## 8. Data transfers
- Cross-border transfers: none
- Safeguards (SCC, adequacy, etc): not applicable

## 9. Consultation and approvals
- DPO consulted: yes
- Security review completed: yes
- Final approval: pending

## 10. References
- Policies: ../policies.md
- Evidence logs: ../control-evidence-log.md
- System diagrams: ../execution-plan.md
