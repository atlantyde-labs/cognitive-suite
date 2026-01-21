# Matriz de Controles de Cumplimiento (Borrador)

## Alcance y supuestos
- Actual: single-user, local, con preferencia offline.
- Futuro: producto multi-tenant.
- Dev: GitOps puede usar datos reales.
- Prod: GitOps solo con outputs anonimizados.
- Cumplimiento soberano: residencia de datos y air-gap requeridos.

## Dominios de control y mapeos

| Dominio | SOC2 | ISO 27001 | NIST 800-53 | CIS | GDPR | HIPAA | PCI | Evidencia actual | Gaps | Artefactos recomendados |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Inventario de activos | CC1/CC5 | A.5/A.8 | CM-8/PM-5 | 1 | Art. 30 | 164.310 | 12.5 | `README.md`, `docs/` | No hay inventario formal | Registro de activos, RoPA |
| Clasificación de datos | CC3 | A.5/A.8 | PL-2/RA-2 | 3 | Art. 5/25 | 164.312 | 3 | N/A | Falta política | Política de clasificación |
| Control de acceso | CC6 | A.5/A.9 | AC-2/AC-6 | 5 | Art. 32 | 164.312 | 7 | Auth UI por token + roles en `frontend/streamlit_app.py` | No IdP/RBAC central | Política de acceso, diseño RBAC |
| Hardening contenedores | CC7 | A.5/A.8 | SC-7/CM-6 | 4 | Art. 32 | 164.308 | 2 | Non-root + FS read-only + no-new-privs en `docker-compose.prod.yml` | Sin perfiles seccomp/apparmor | Perfil de hardening runtime |
| Cifrado | CC6/CC7 | A.8/A.10 | SC-8/SC-13 | 3 | Art. 32 | 164.312 | 3/4 | N/A | Sin plan at-rest/in-transit | Estándar de cifrado, plan KMS |
| Logging/auditoría | CC7 | A.8 | AU-2/AU-6 | 8 | Art. 5/30 | 164.312 | 10 | Logs JSONL en `pipeline/analyze.py` y `frontend/streamlit_app.py` | Sin auditoría centralizada | Política de auditoría |
| SDLC/gestión de cambios | CC8 | A.5/A.8 | CM-3/SA-10 | 16 | Art. 25 | 164.308 | 6 | `.github/workflows/*` | Sin control formal de cambios | Política SDLC, registros |
| Gestión de vulnerabilidades | CC7 | A.5 | RA-5 | 7 | Art. 32 | 164.308 | 6 | `ci-security.yml` ejecuta SBOM + SCA + pip-audit | Sin cadencia de parches | Plan SCA, SBOM, cadencia |
| Backup/DR | CC7 | A.5/A.17 | CP-9/CP-10 | 11 | Art. 32 | 164.308 | 9 | N/A | Sin BCP/DR | Política backup, pruebas restore |
| Riesgo de terceros | CC1/CC3 | A.5/A.15 | SR-3 | 15 | Art. 28 | 164.308 | 12.8 | Dependencias en `requirements.txt` | Sin evaluación de proveedores | Checklist TPRM, DPA |
| Minimización de datos | CC3 | A.5 | PT-2 | 3 | Art. 5 | 164.306 | 3 | Redacción en `pipeline/analyze.py` + gating en `gitops/sync.sh` | Sin reglas formales | Especificación de redacción |
| Soberanía/air-gap | CC3 | A.5 | SC-7/SC-12 | 4 | Art. 44 | 164.308 | 12.3 | `dev/bootstrap-dev.sh` descarga modelos | Sin mirror offline | Mirror offline, allowlist |

## Notas sobre el repo actual
- La UI exige auth por token en prod con roles: `frontend/streamlit_app.py`, `docker-compose.prod.yml`.
- GitOps está gateado por entorno: `gitops/sync.sh`.
- Outputs están redactados en prod (gating por env): `pipeline/analyze.py`.
- Dependencias fijadas en `requirements.txt`, `requirements-docs.txt`, `frontend/requirements.txt`, más locks por servicio en `ingestor/requirements.txt` y `pipeline/requirements.txt`.
