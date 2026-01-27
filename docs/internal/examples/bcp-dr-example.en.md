# BCP / DR Example (Fictional)

## 1. Objectives
- RTO: 4 hours
- RPO: 24 hours
- Availability targets: 99.5%

## 2. Critical services
- Ingestor
- Pipeline
- Frontend
- GitOps
- Storage (outputs, audit logs)

## 3. Dependencies
- Container runtime: Docker
- Host filesystem: local SSD
- External services: none

## 4. Backup strategy
- Backup scope: outputs, audit logs, config
- Backup frequency: daily
- Backup location: offline encrypted volume (EU region)
- Encryption at rest: AES-256
- Retention policy: 30 days

## 5. Recovery procedures
- Restore from backup to clean host
- Validate integrity via hash checks
- Rollback procedures: restore last known good backup
- Communication plan: internal status channel

## 6. Testing
- Test frequency: quarterly
- Last test date: 2026-01-20
- Issues found: none
- Remediation actions: not required

## 7. Roles and responsibilities
- Incident commander: ops@example.test
- Operations lead: ops-lead@example.test
- Security lead: sec@example.test
- Communications lead: comms@example.test

## 8. Evidence
- Backup logs: audit/backup.log
- Restore test reports: restore-test-report.md
- Change records: ../control-evidence-log.md
