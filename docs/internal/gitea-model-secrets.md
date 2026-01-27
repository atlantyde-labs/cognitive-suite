# Gitea Model Secrets (Founders-only)

Objetivo: mantener repos de modelos privados con acceso maximo a 3 Founders.

## Politica

- Repos de modelos **siempre privados**.
- Solo 3 Founders con permiso admin.
- Tokens y secretos fuera del repo (SOPS/Vault/1Password).
- Acceso auditado (HITL).

## Enforce via CLI (Gitea API)

1) Copia el env:

```bash
cp bash/GitDevSecDataAIOps/tooling/secrets/gitea-model-repo-lockdown.env.example /tmp/gitea-model-lock.env
```

2) Edita `OWNER`, `REPOS` y `FOUNDERS` (3 usuarios).

3) Dry-run:

```bash
DRY_RUN=true bash bash/GitDevSecDataAIOps/tooling/secrets/gitea-model-repo-lockdown.sh /tmp/gitea-model-lock.env
```

4) Apply:

```bash
DRY_RUN=false bash bash/GitDevSecDataAIOps/tooling/secrets/gitea-model-repo-lockdown.sh /tmp/gitea-model-lock.env
```

## Evidencia

- Guarda logs de ejecucion y confirma en UI que solo los 3 Founders tienen acceso.

## Onboarding contribuyentes (MFA + SSH)

Usa el wizard para generar CSV + etiquetas de comportamiento, luego aplica el script de onboarding y exige 2FA en el primer login:

```bash
cp bash/GitDevSecDataAIOps/tooling/secrets/contributor-onboarding-wizard.env.example /tmp/onboard-wizard.env
DRY_RUN=false bash bash/GitDevSecDataAIOps/tooling/secrets/contributor-onboarding-wizard.sh /tmp/onboard-wizard.env

cp bash/GitDevSecDataAIOps/tooling/secrets/contributors.csv.example /tmp/contributors.csv
cp bash/GitDevSecDataAIOps/tooling/secrets/gitea-onboard-contributors.env.example /tmp/onboard.env
```

```bash
DRY_RUN=true bash bash/GitDevSecDataAIOps/tooling/secrets/gitea-onboard-contributors.sh /tmp/onboard.env
```

Los usuarios deben activar MFA con apps como Aegis/FreeOTP (sin Google/AWS/MS).
