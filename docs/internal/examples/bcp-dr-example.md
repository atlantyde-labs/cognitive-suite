# Ejemplo BCP / DR (Ficticio)

## 1. Objetivos
- RTO: 4 horas
- RPO: 24 horas
- Objetivos de disponibilidad: 99.5%

## 2. Servicios criticos
- Ingestor
- Pipeline
- Frontend
- GitOps
- Almacenamiento (outputs, logs de auditoria)

## 3. Dependencias
- Runtime de contenedores: Docker
- Sistema de archivos del host: SSD local
- Servicios externos: ninguno

## 4. Estrategia de copias de seguridad
- Alcance del backup: outputs, logs de auditoria, config
- Frecuencia del backup: diario
- Ubicacion del backup: volumen cifrado offline (region UE)
- Cifrado en reposo: AES-256
- Politica de retencion: 30 dias

## 5. Procedimientos de recuperacion
- Restaurar desde backup a un host limpio
- Validar integridad via sumas de verificacion
- Procedimientos de rollback: restaurar el ultimo backup valido
- Plan de comunicacion: canal interno de estado

## 6. Pruebas
- Frecuencia de pruebas: trimestral
- Fecha de ultima prueba: 2026-01-20
- Problemas encontrados: ninguno
- Acciones de remediacion: no requeridas

## 7. Roles y responsabilidades
- Comandante de incidentes: ops@example.test
- Lider de operaciones: ops-lead@example.test
- Lider de seguridad: sec@example.test
- Lider de comunicaciones: comms@example.test

## 8. Evidencias
- Logs de backup: audit/backup.log
- Reportes de prueba de restauracion: restore-test-report.md
- Registros de cambios: ../control-evidence-log.md
