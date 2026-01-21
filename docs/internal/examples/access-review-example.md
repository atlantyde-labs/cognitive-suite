# Ejemplo de revision de accesos (Ficticio)

## 1. Metadatos de revision
- Periodo de revision: 2026-01
- Revisor: security@example.test
- Fecha: 2026-02-05
- Alcance: UI prod, repo GitOps, CI

## 2. Inventario de accesos
| Usuario / Servicio | Rol | Alcance de acceso | Justificacion | Ultimo uso | Accion |
| --- | --- | --- | --- | --- | --- |
| alice@example.test | admin | UI prod | ops owner | 2026-02-03 | mantener |
| bob@example.test | analyst | UI prod | analyst | 2026-02-02 | mantener |
| svc-gitops | admin | escritura en repo | automatizacion | 2026-02-01 | mantener |
| temp-user@example.test | viewer | UI prod | test | 2025-12-01 | revocar |

## 3. Hallazgos
- Cuentas con sobre-privilegios: ninguna
- Cuentas huerfanas: temp-user@example.test
- Cobertura MFA: 100%

## 4. Acciones
- Revocar accesos: temp-user@example.test
- Reducir accesos: ninguno
- Excepciones aprobadas: ninguna

## 5. Evidencias
- Exportacion de accesos: audit/access-export-2026-02-05.csv
- Aprobaciones: change-log-2026-02-05.md
