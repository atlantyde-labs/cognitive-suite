# Bot Governance (HITL + Ops Approve)

Este sistema usa bots para **comentarios, evidencias y check-runs** por defecto.  
Los approvals automáticos solo se permiten en modo **ops**, con flags explícitos.

## Modos

### Advisory (por defecto)
- `BOT_ACTION=comment`
- El bot **no aprueba**.
- Genera evidencia y comentario con trazabilidad.

### Ops Approve (solo con flags)
El bot puede aprobar **solo si**:
- `ALLOW_BOT_APPROVE=YES`
- `HITL_APPROVE=YES`
- Evidencia publicada en Gitea (repo privado)

## Evidencias en Gitea (repo privado)
Se guardan en un repo privado con estructura por run:

```
runs/YYYYMMDD/PR-<num>/
  bot-decision.json
  logs/
  artifacts.sha256
```

## Plantillas
Los scripts usan placeholders:
- `GITEA_EVIDENCE_REPO="founders/evidence"`
- `BOT_NAME="ops-bot"`
- Tokens solo en `.env` locales

## Workflow (GitHub Actions + self-hosted)
Archivo: `.github/workflows/bot-review.yml`

Labels opcionales:
- `ops/bot-approve` -> permite approval si HITL tambien esta en YES
- `ops/bot-approve-github` -> permite approval en GitHub (ademas del anterior)
- `ops/hitl-approve` -> confirma HITL para bots

Secrets/vars requeridos para Gitea:
- `GITEA_URL`
- `GITEA_TOKEN`
- `GITEA_EVIDENCE_TOKEN`
- `GITEA_EVIDENCE_REPO` (placeholder por defecto)
- `GITEA_EVIDENCE_USER`
- `GITEA_REPO_OWNER` (var)
- `GITEA_REPO_NAME` (var)

## Nota ética
Los bots **no sustituyen** a revisores humanos.  
Para merges regulados, exige **2 humanos reales** y usa bots como soporte.

## Wizard interactivo
Script: `bash/GitDevSecDataAIOps/tooling/bots/bot-setup-wizard.sh`

- Genera `.env` locales con placeholders.
- No escribe tokens reales.
