# GitHub Projects v2 — Gamification & Metrics (Setup)

Este repositorio incluye automatizaciones para:
- Añadir Issues/PRs a un **GitHub Project (v2)** según etiquetas.
- Estructurar métricas de aprendizaje y delivery usando vistas/tablas del Project.

## 1) Crea un Project v2 (en GitHub.com)
En GitHub:
- Organization: `atlantyde-labs`
- Project: `Cognitive Suite — Learning By Doing`

Crea campos recomendados:
- **Status** (Single select): Backlog, In Progress, In Review, Done, Blocked
- **Area** (Single select): Learning, CI/GitOps, Docs, Backend, Frontend
- **Level** (Single select): 1, 2, 3, 4
- **XP** (Number)
- **Type** (Single select): Issue, PR
- **KPI** (Text): métrica objetivo (ej: "Tiempo a primer PR")

Vistas recomendadas:
- **Kanban** por Status
- **Table** por Level/XP
- **Roadmap** por milestones (si los usas)
- **Charts** (built-in) para ver throughput y distribución por Area/Level

## 2) Secrets necesarios (repo settings)
Para automatizar Projects v2 necesitas un token con permisos de Project:
- Crea un **Fine-grained PAT** (recomendado) o un classic PAT
- Permisos mínimos sugeridos:
  - Issues: Read/Write
  - Pull requests: Read/Write
  - Projects: Read/Write
  - Contents: Read

En el repo, añade secrets:
- `PROJECT_URL`  -> URL del project v2 (ej: https://github.com/orgs/atlantyde-labs/projects/1)
- `PROJECT_TOKEN` -> token PAT con permisos

## 3) Qué hace la automatización
Workflow: `.github/workflows/add_to_project.yml`
- En cada Issue/PR abierto o etiquetado, si tiene alguna etiqueta de:
  - good first issue
  - learning-task
  - ci-gitops
  - automation
  - ci-boott
  se añade al project.

## 4) Métricas sugeridas (qué buscamos)
- **TTFP (Time to First PR)**: tiempo desde que alguien abre issue hasta su primer PR
- **Learning Velocity**: nº de learning-task completadas / semana
- **CI Reliability**: % de runs verdes / semana (y “mean time to green”)
- **Flow Efficiency**: tiempo In Progress vs total cycle time
- **XP Earned**: suma XP completada por contributor / mes (gamificación)

Puedes reflejar esto con vistas/filters y charts del Project.
