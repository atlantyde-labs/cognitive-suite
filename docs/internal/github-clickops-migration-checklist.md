# GitHub ClickOps Migration Checklist (Public Repo Clean)

Esta guia define tareas ClickOps para confirmar que la migracion es correcta,
con evidencias y aprobacion HITL (2 revisores).

## Objetivo

- Confirmar que el repo publico esta limpio (sin secretos internos).
- Asegurar gates de seguridad y CI activos.
- Dejar evidencias para auditoria.

## Tareas ClickOps (resumen)

1) **General**: Settings > General (visibilidad, default branch).
2) **Governance**: Rulesets con 2 approvals + required checks.
3) **Security**: Secret scanning, Code scanning, Dependabot.
4) **CI/E2E**: E2E Public + CodeQL en verde, artefactos descargados.
5) **Issues**: Labels/milestones migrados.
6) **Releases/Tags**: Releases y tags completos.
7) **Wiki/Projects**: Contenido publico sin datos internos.
8) **Search**: Busqueda de keywords sensibles.
9) **Evidence**: Guardar artifacts + capturas clave.

## JSONL para evidencias

Usa el schema en:

- `schemas/github-migration-clickops.schema.json`

Ejemplo JSONL:

- `datasets/github-migration-clickops.example.jsonl`

Cada linea representa una evidencia de ClickOps con status y checks.
