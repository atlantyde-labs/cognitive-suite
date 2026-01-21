# Roadmap de Cumplimiento (Borrador)

## Fase 0 - Local single-user (ahora)
- Documentar políticas de clasificación, retención y borrado de datos.
- Añadir paso básico de anonimización/redacción antes de cualquier GitOps en dev.
- Añadir guardia de acceso local para la UI (password o token simple en Streamlit).
- Definir allowlist/denylist para llamadas de red salientes.
- Crear log de auditoría mínimo para ejecuciones de análisis (quién/cuándo/qué input).

## Fase 1 - Beta multi-tenant
- Implementar autenticación + RBAC para UI y API.
- Separar tenants por storage y límites de acceso.
- Añadir cifrado en reposo y en tránsito (TLS para UI/API).
- Añadir SCA/SBOM en CI (pip-audit, grype, gitleaks, export SBOM).
- Añadir logging centralizado y alerting básico.
- Endurecer contenedores (non-root, FS read-only, drop caps).
- Mantener documentación DPIA y RoPA con evidencias.

## Fase 2 - Producción soberana / air-gap
- Mirror offline de dependencias y registro de modelos.
- Sin egress externo en prod (solo allowlist).
- Evidencia completa de residencia de datos y controles de ubicación de backups.
- Plan DR y pruebas de restore con evidencia auditada.
- Formalizar recolección de evidencias SOC2/ISO y auditorías internas.

## Criterios de salida
- P0 completo: políticas publicadas y aplicadas en tooling dev.
- P1 completo: aislamiento multi-tenant + auth + cifrado + audit logs.
- P2 completo: build air-gap, prueba de residencia soberana, y evidencia DR.
