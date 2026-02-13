# Deployment Models

ATLANTYQA can deploy in:

1. **Local-first / On-prem:** micro-CPDs and edge nodes that host agents and keep sensitive data within the campus.  
2. **Hybrid:** less critical workloads in certified cloud while preserving data residency.  
3. **Air-gapped:** isolated enclaves for high-risk decisions.

Our compute strategy (`docs/internal/compute-strategy.md`) explains which workloads stay local and how we secure connectivity.

## Minimum implementation policy

- Contractual minimum timeline: **180 days** for any public-offer implementation.
- Mandatory operational buffer: **30 additional days** to absorb unexpected incidents without service degradation.
- Quality gates per phase: **UAT**, security, compliance, operational readiness, and evidence closeout.
