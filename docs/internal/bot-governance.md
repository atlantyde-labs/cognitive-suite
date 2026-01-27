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

## Nota ética
Los bots **no sustituyen** a revisores humanos.  
Para merges regulados, exige **2 humanos reales** y usa bots como soporte.
