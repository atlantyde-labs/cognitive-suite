# Hardening Note (Fictional)

- Date: 2026-02-14
- Scope: production compose
- Controls verified:
  - non-root user
  - read-only filesystem
  - tmpfs for /tmp
  - no-new-privileges
  - dropped capabilities
- Residual risk: no seccomp/apparmor profile applied
- Follow-up: define seccomp profile for production
