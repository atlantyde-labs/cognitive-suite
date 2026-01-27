# Gitea UI On-Prem (Bots + Evidencias)

Este documento es el homonimo para la UI de Gitea en on‑premise.  
Incluye el flujo ClickOps para crear bots, tokens y repos de evidencias.

## Wizard interactivo

Ejecuta:

```bash
bash bash/GitDevSecDataAIOps/tooling/bots/gitea-ui-wizard.sh
```

El wizard genera un checklist `.md` con:
- Creacion de machine user
- Token del bot
- Team/permiso minimo
- Repo privado de evidencias
- Branch protection y approvals

## Notas
- No guardes tokens en git.
- Usa el repo de evidencias privado para trazabilidad.
