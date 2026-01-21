# Ejemplo de registro de evidencias de control (Ficticio)

## Registro de evidencias
| Fecha | ID de control | Descripcion | Artefacto | Responsable | Estado |
| --- | --- | --- | --- | --- | --- |
| 2026-02-10 | AU-2 | Registro de auditoria habilitado | audit/analysis.jsonl | ops@example.test | verificado |
| 2026-02-10 | AU-2 | Registro de accesos UI habilitado | audit/ui_access.jsonl | ops@example.test | verificado |
| 2026-02-11 | RA-5 | Resultados de SCA | logs de ci-security.yml | sec@example.test | verificado |
| 2026-02-11 | SBOM | Artefactos SBOM | sbom.spdx.json, sbom.cdx.json | sec@example.test | verificado |
| 2026-02-12 | CM-6 | Config de hardening aplicada | docker-compose.prod.yml | ops@example.test | verificado |

## Notas
- Guarda los artefactos en una ubicacion controlada.
- Enlaza logs de build, SBOMs, logs de auditoria y reportes de pruebas.
