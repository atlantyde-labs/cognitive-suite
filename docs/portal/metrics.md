# 📊 Métricas (Learning + Delivery + Ecosistema)

> **Objetivo:** medir aprendizaje real, fiabilidad operativa y crecimiento del ecosistema
> sin caer en “métricas vanity”.  
> Estas métricas están pensadas para **GitHub.com** (Issues + Projects v2 + Actions).

---

## 1) Métricas de Aprendizaje (Learning by Doing)

### ✅ TTFP — Time To First PR (métrica reina de early-adopters)
- **Definición:** tiempo desde el primer issue / primera interacción hasta el primer PR aceptable.
- **Por qué importa:** si baja, tu onboarding funciona.

**Cómo medir en GitHub**
- Project v2: filtra cohortes (labels `good first issue` + `learning-task`)
- Compara `created_at` del issue inicial vs `merged_at` del primer PR.

---

### ✅ Learning Velocity
- **Definición:** nº de `learning-task` completadas por semana/mes.
- **Instrumentación:** Project v2 + campo `Status=Done` + label `learning-task`.

---

### ✅ XP Earned (gamificación medible)
- **Definición:** suma de XP entregada por contributor y por mes.
- **Instrumentación:** Project v2 campo `XP` (Number).
- **Regla base sugerida:**
  - Nivel 1 → 10 XP
  - Nivel 2 → 25 XP
  - Nivel 3 → 50 XP
  - Nivel 4 → 100 XP

---

## 2) Métricas de Flujo (Delivery / Operación)

### ✅ Cycle Time (Issue → Done)
- **Definición:** tiempo total desde que un issue entra a `In Progress` hasta `Done`.
- **Objetivo:** reducir bloqueos y aumentar fluidez.

### ✅ Flow Efficiency
- **Definición:** tiempo en estado “activo” / tiempo total del ciclo.
- **Instrumentación:** status timestamps (manual o mediante automatizaciones).

---

## 3) Métricas de Fiabilidad (GitOps / CI)

### ✅ CI Reliability
- **Definición:** % de runs verdes / semana + tendencia.
- **Fuente:** GitHub Actions.

### ✅ MTTR — Mean Time To Recovery (Mean time to green)
- **Definición:** tiempo promedio en recuperar un pipeline fallido a estado verde.
- **Fuente:** historial de runs (Actions).

### ✅ Build Cost Guardrails (recurso / sostenibilidad)
- **Definición:** tamaño medio de imágenes docker y tiempo de build.
- **Objetivo:** evitar “dependency bloat” (sobre todo ML).

---

## 4) Métricas de Ecosistema (ATLANTYDE / ATLANTYQA)

Estas métricas conectan el repositorio con el **Resumen de identidad y ecosistema**:
misión, infraestructura soberana, expansión territorial y comunidad fundadora.

### ✅ Sovereign Stack Adoption
- **Definición:** % de contribuciones que mantienen el principio *local-first*.
- **Señal:** PRs que:
  - no dependen de SaaS privativos para funcionar
  - documentan modo offline/híbrido
  - mantienen compatibilidad MicroK8s / k3s

**Instrumentación**
- Label `local-first`
- Checklist en PR template (opcional)

---

### ✅ GitOps Coverage
- **Definición:** porcentaje de componentes que tienen:
  - manifests/helm/kustomize
  - policies (OPA) o checks de seguridad
  - pipelines reproducibles

**Instrumentación**
- Project v2 campo `Area=CI/GitOps`
- checklist por componente

---

### ✅ Community Growth (salud del colectivo)
- **Definición:** contribuyentes activos/mes y ratio de “returning contributors”.
- **Por qué importa:** la cooperativa vive de continuidad, no de picos.

---

### ✅ Territorial Impact (ITI / Andalucía → EU)
- **Definición:** # de eventos/bootcamps/labs ejecutados + # de estudiantes activos.
- **Instrumentación recomendada**
- “Ops Issues” por evento (label `community-event`)
- Project v2 vista “Roadmap” por trimestre:
  - 2025–26 Andalucía (ITI)
  - 2026–27 Portugal/Francia/Alemania
  - 2028+ LATAM/USA

---

## 5) Mapa de métricas → GitHub Projects v2 (campos recomendados)

**Campos**
- `Status` (Backlog/In Progress/In Review/Done/Blocked)
- `Area` (Learning, CI/GitOps, Docs, Backend, Frontend, LegalTech, Community)
- `Level` (1–4)
- `XP` (Number)
- `KPI` (Text) → “TTFP”, “CI Reliability”, etc.

**Vistas**
- Kanban por Status
- Table por Level/XP
- Charts por Area y por Status
- Roadmap por trimestre (si usas milestones)

---

## 6) Checklist de implementación rápida (15 min)

- [ ] Crear Project v2 en la org `atlantyde-labs`
- [ ] Añadir campos `Status/Area/Level/XP/KPI`
- [ ] Añadir secrets `PROJECT_URL` y `PROJECT_TOKEN`
- [ ] Activar workflow `add_to_project.yml`
- [ ] Activar workflow `labels.yml`
- [ ] Definir XP por label/nivel en tu operativa

---

> Si algo no se puede medir, no se puede mejorar.  
> Y si se mide mal, se destruye la cultura.  
> **Medimos para aprender y cooperar**, no para presionar.
