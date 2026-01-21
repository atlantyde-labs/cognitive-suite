# Plan BCP / DR (Borrador)

## 1. Objetivos
- RTO (Objetivo de Tiempo de Recuperacion):
- RPO (Objetivo de Punto de Recuperacion):
- Objetivos de disponibilidad:

## 2. Servicios criticos
- Ingestor
- Pipeline
- Frontend
- GitOps
- Almacenamiento (outputs, logs de auditoria)

## 3. Dependencias
- Runtime de contenedores
- Sistema de archivos del host
- Servicios externos (si aplica)

## 4. Estrategia de copias de seguridad
- Alcance del backup:
- Frecuencia del backup:
- Ubicacion del backup:
- Cifrado en reposo:
- Politica de retencion:

## 5. Procedimientos de recuperacion
- Restaurar desde backup:
- Validar integridad:
- Procedimientos de rollback:
- Plan de comunicacion:

## 6. Pruebas
- Frecuencia de pruebas:
- Fecha de ultima prueba:
- Problemas encontrados:
- Acciones de remediacion:

## 7. Roles y responsabilidades
- Comandante de incidentes:
- Lider de operaciones:
- Lider de seguridad:
- Lider de comunicaciones:

## 8. Evidencias
- Logs de backup:
- Reportes de pruebas de restauracion:
- Registros de cambios:
