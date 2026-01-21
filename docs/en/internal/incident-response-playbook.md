# Incident Response Playbook (Draft)

## 0. Severity levels
- SEV1: Critical impact, data breach, or extended outage
- SEV2: Major impact, degraded service
- SEV3: Minor impact, limited scope

## 1. Detection and triage
- Trigger sources: alerts, user reports, monitoring
- Initial triage checklist:
  - Identify affected services
  - Determine severity
  - Start incident log

## 2. Containment
- Isolate affected components
- Disable risky workflows (GitOps sync, external calls)
- Preserve evidence (logs, configs)

## 3. Eradication
- Remove root cause
- Patch vulnerabilities
- Validate integrity

## 4. Recovery
- Restore services
- Monitor for recurrence
- Verify data integrity

## 5. Communication
- Internal comms timeline
- External notifications (if required)
- Regulatory reporting (if required)

## 6. Post-incident review
- Timeline
- Root cause analysis
- Corrective actions
- Lessons learned

## 7. Evidence
- Incident log
- Forensic artifacts
- Approval of closure
