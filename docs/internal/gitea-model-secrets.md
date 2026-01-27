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
