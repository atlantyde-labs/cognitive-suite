# Argumentario de objeciones ATLANTYQA

Documento listo para presentar en comités y propuestas; cada bloque responde con lenguaje institucional + referencias técnicas reales.

## Objeción 1 — “Es muy caro” / “Tenemos prioridades presupuestarias”

**Respuesta:**  
Hay una diferencia entre gastar en tecnología y construir capacidad soberana. ATLANTYQA transforma el cumplimiento en un activo productivo, reduciendo el coste de auditoría y sanciones. Nuestros despliegues (ver `release-on-merge.yml`, `release-draft.yml`) generan artefactos versionados y evidencia desde el día 1, lo que minimiza retrabajo y justifica retorno rápido de inversión.  
**Apoyo:** dashboards de impacto (`docs/portal/metrics.md`, `metrics/users/*.json`), loop de evidencia en `outputs/ci-evidence`.  
**Cierre:** proponemos un programa mínimo de implantación de 180 días (con 30 días de contingencia) con métricas de coste/beneficio (= XP/badges ganados por squads) y gates de calidad por fase.

## Objeción 2 — “Ya tenemos proveedor cloud/licenciado”

**Respuesta:**  
ATLANTYQA no compite con el cloud; complementa con infraestructura local-first y microCPDs soberanos (ver `scripts/export-release.sh`, `release-branch-draft.yml`) que resguardan los datos sensibles y reducen dependencia crítica. Las organizaciones usan nuestros agentes auditados mientras mantienen la capa cloud para cargas menos sensibles.  
**Apoyo:** `bot-review.yml` para evidencia y desaprobación de decisiones no gobernadas; `metrics/xp-rules.yml` para medir actores.  
**Cierre:** proponemos un ejercicio de co-ingeniería (“co-sourcing”) con el proveedor actual para insertar los nodos ATLANTYQA a modo de “capa soberana”.

## Objeción 3 — “¿Y si mi equipo legal / compliance no lo acepta?”

**Respuesta:**  
Nuestros workflows apuntalan compliance-as-code. Cada release y cada agente produce JSONL, SBOMs y auditorías claras (`jsonl-validate-wizard.sh`, `docs/internal/bot-governance.md`). Así no se trata de confiar en la palabra del proveedor, sino de entregar evidencia procesable al área legal.  
**Apoyo:** `add_to_project.yml` muestra trazabilidad, `metrics/users/*.json` y `docs/portal/metrics.md` documentan el historial y los badges ganados.  
**Cierre:** entregamos playbooks de documentación y un informe regulatorio para la comisaría de riesgo antes de pasar a producción.

## Objeción 4 — “No queremos sacrificar rendimiento por soberanía”

**Respuesta:**  
La soberanía ATLANTYQA se construye con eficiencia energética y reutilización (`docs/portal/metrics.md`, `dashboards`). Nuestros agentes corren on-premise con optimizaciones de coste/energía y kill-switch; se integran con sistemas existentes (ERP, core) sin recrear infraestructura.  
**Apoyo:** `release-draft.yml` y `release-prerelease.yml` muestran pipelines reproducibles que favorecen el rendimiento.  
**Cierre:** definimos indicadores (procesos automatizados, horas ahorradas, tiempo de auditoría) y los ligamos a objetivos de eficiencia, con reporting mensual.

## Objeción 5 — “Soberanía vs velocidad/incertidumbre”

**Respuesta:**  
No es uno u otro: soberanía bien ejecutada acelera despliegues con control. La red de microCPDs y squads ATLANTYQA permite arrancar resultados tempranos, manteniendo como estándar un ciclo mínimo de 180 días para absorber incidencias y asegurar calidad de producto.  
**Apoyo:** `docs/sales/one-pagers/*.md` + script `docs/sales/scripts/generate_one_pagers.py` para replicar versiones personalizadas en minutos.  
**Cierre:** proponemos un programa “Fase 0 / Fase 1 / Fase 2” de 180 días mínimos + contingencia, con entregables y checklists de calidad listos (podemos exportarlos en zip para el comité).
