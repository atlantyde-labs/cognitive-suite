# ATLANTYQA One-Pagers

Documento único para presentar el **mensaje institucional** con contexto operativo y referencias concretas. Cada sección sigue el mismo patrón: problema estructural, propuesta ATLANTYQA (tecnología + filosofía), ejemplos de entregables y métricas de éxito. Está diseñado para hablar “el idioma de Bruselas”, del gobierno español, de comités de riesgo y de socios industriales, sin renunciar al discurso soberano.

## 1. Unión Europea (Comisión / DGs / AI Act)

**Problema estructural**  
Multipolaridad tecnológica, dependencia de hyperscalers, presión regulatoria (AI Act + NIS2 + CRA) sin capacidad material homogénea para ejecutar y auditar.

**Propuesta ATLANTYQA**  
Sovereign Cognitive Stack: IA local + agentes + evidencias continuas + compliance-as-code. La infraestructura ya vive en workflows como `release-draft.yml` (distribución controlada), `bot-review.yml` (validación y grabación de evidencia) y `add_to_project.yml` (trazabilidad de tareas en project boards).  
**Núcleo del mensaje:** “No prometemos cumplimiento; demostramos soberanía operativa. Reducimos dependencia, incorporamos métricas y convertimos el riesgo regulatorio en ventaja competitiva”.

**Entregables clave**
- Plantilla “AI Sovereignty-in-a-Box” (microCPD + IA local + Gitea evidence repo + dashboard `docs/portal/metrics.md`).  
- Compliance Evidence Factory (pipeline reproducible, `outputs/ci-evidence`, `metrics/users/*.json`).  
- Gobernanza de agentes (scripts en `bash/GitDevSecDataAIOps/tooling/bots/`, kill-switch y auditorías).

**Métricas/Garantías**
- Documento “Statement of Conformance” (repo + notebooks).  
- Evidencia automatizada en `outputs/bot-evidence` y `metrics/`.  
- Recapture de auditoría: `release-prerelease.yml` + `release-on-merge.yml` produce artefactos versionados con SBOM/registros de cumplimiento.

## 2. Estado español / Comunidades Autónomas

**Problema**  
Deseo de transformación digital, pero con recursos material/regionales limitados y necesidad de resiliencia territorial.

**Propuesta**  
Municipal Sovereignty Starter: microCPDs + servicios digitales replicables + portal ciudadano + auditoría de datos. Aprovecha `docker-compose` + `scripts/export-release.sh` para replicar despliegues y las plantillas `docs/assets/` para marca pública.  
**Mensaje central:** “Soberanía cognitiva local para mantener la continuidad operativa sin hipotecar datos ciudadanos ni depender de máscaras extranjeras”.

**Entregables**
- Kits de despliegue ready-to-run (documentación + `run-local-workflow.sh`).  
- Operaciones guiadas (bot review + compliance evidence) + squads de ATLANTYQA Academy para talento local.  
- Leaderboard de impacto: `metrics/users/` y `metrics/xp-rules.yml` que registran badges, XP y resultados de reskilling.

**Métricas**
- Proyectos replicados en municipios (documentados en `docs/portal/metrics.md` y `docs/ops/local-runner.md`).  
- Reducción de dependencia (infra local vs cloud).  
- Creación de empleos tecnológicos y nodos de educación dual (ATLANTYQA Academy).

## 3. Grandes corporaciones reguladas (banca, seguros, utilities, hospitales)

**Problema**  
Necesitan automatizar y adoptar IA pero no pueden tolerar pérdida de control, shadow AI o incidentes regulatorios.

**Propuesta**  
ATLs Sovereign Agentic Ops Pack: agentes autónomos para legal/finanzas/operaciones que se ejecutan localmente con guardarraíles (logs, kill switches, registros de decisiones). Los scripts de `bot-review` ya demuestran cómo registrar decisiones, evidencias y aprobaciones.

**Oferta**
- Agentes documentales y de atención (repositorio `bash/GitDevSecDataAIOps/tooling/bots/`).  
- Compliance evidence pipeline (repos + `jsonl` + `metrics`).  
- Formación “Reskilling operativo” (Academy + ledger, `metrics/users/`).

**Resultados esperados**
- Reducción de horas manuales + auditoría en `OUTPUTS`.  
- Validación de IA local sin perder trazabilidad (todo versionado en Git + Gitea).  
- Lower risk ratio (documentado en `docs/internal/bot-governance.md`).

## 4. Integradores tecnológicos / partners industriales

**Problema**  
Quieren ofrecer automatización y IA pero se enfrentan a clientes que exigen compliance, soberanía, adaptabilidad.

**Propuesta**  
Framework reproducible (pipelines, artefactos de release, evidence flows, doc de métricas) con `ATLANTYQA Compliance Evidence Pack + Agentes` para venderlo como servicio empaquetado.  
**Mensaje:** “Te damos material entregable, no código sin seguimiento: tu cliente obtiene evidencia y tú un GTM claro”.

**Toolkit**
- `release-branch-draft.yml` + `release-draft.yml` para replicar builds y artefactos.  
- `add_to_project.yml` y `project-fields-from-labels.yml` para gestionar leads, tareas y métricas.  
- `docs/portal/metrics.md` + `metrics/xp-rules.yml` para construir dashboards de éxito.

**Indicadores**
- Deployment kits replicados por partner.  
- Documentación de compliance replicada (project cards, `outputs`).  
- Modelo de revenue recurrente (licencia + evidencia + soporte).

## 5. Municipios / administraciones locales

**Problema**  
Necesitan IA operativa, economía circular y soberanía del dato, pero con presupuestos limitados.

**Propuesta**  
“Municipal Sovereignty Starter” replicable y modular: microCPDs + edge/IoT (BlueTech/MARE) + IA local + un portal con métricas de impacto. Se apoya en `dashboard/app.py`, `vectorstore`, `docs/portal/metrics.md` y la suite MAR_BLUE_TECH.

**Entregables**
- Blueprint replicable (workflows + scripts).  
- Kit de despliegue “Edge BlueTech”: contenedores, sensórica y IA local.  
- Programa de talento (Academy) y squads TaaS.

**Medidas**
- Número de microCPDs desplegados.  
- Impacto en servicios municipales (tiempos de respuesta, ahorro energético).  
- Adopción de squads (perfiles de `metrics/users/`).

## 6. Narrativa de liderazgo ético-técnico

**Posicionamiento**  
Eres arquitecto de soberanía cognitiva: mezclas tecnología, derecho y ética sin dualismos. El momentum geopolítico exige tomar partido por la resiliencia europea sin caer en tecnofobia. Tu liderazgo es **ética aplicada, ejecución tangible y capacitaciones operativas**, no teoría.

**Discurso a compartir en reuniones**  
1. “No vendemos una herramienta; construimos sistemas operativos institucionales.”  
2. “Cada automatización está atada a evidencia trazable: logs, JSONL, badges, auditors.”  
3. “Los proyectos se construyen con squads que aprenden en ATLANTYQA Academy y operan bajo frameworks de compliance as code.”  

**Referencias operativas**  
- `docs/internal/bot-governance.md`: playbook de gobernanza para bots.  
- `metrics/xp-rules.yml` + `metrics/users/*.json`: evidencia de talento y reskilling.  
- Workflows (`bot-review`, `release-draft`, `add_to_project`) que ya generan artefactos de compliance y trazabilidad.

En el siguiente paso podemos llevar estos one-pagers al formato deseado (PDFs, Google Slides, Notion Share). ¿Quieres que prepare la versión “print-ready” (Markdown con diseño simple) o te la dejo para adaptar a tu tool de ventas?

**Posicionamiento**  
