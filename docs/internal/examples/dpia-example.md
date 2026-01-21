# Ejemplo de DPIA (Ficticio)

## 1. Resumen
- Proyecto: Cognitive Suite
- Entorno: prod
- Responsable del tratamiento: Example Cooperative Ltd
- Fecha: 2026-02-14
- Version: 1.0

## 2. Descripcion del tratamiento
- Proposito del tratamiento: analizar documentos internos para producir insights redactados
- Fuentes de datos: archivos aportados por el usuario en data/input
- Resumen del flujo: ingest -> analyze -> outputs redactados -> sync GitOps
- Sistemas involucrados: ingestor, pipeline, frontend, gitops
- Ubicaciones de almacenamiento: volumen local del host, repo GitOps (solo redactados)
- Periodo de retencion: datos en bruto 0 dias (deshabilitado), outputs 90 dias

## 3. Categorias de datos
- Categorias de datos personales: nombres, correos, contenido laboral
- Categorias especiales (si aplica): ninguna prevista
- Sujetos de datos: empleados, contratistas

## 4. Base legal (GDPR)
- Base legal: interes legitimo
- Evaluacion de interes legitimo: gestion interna de conocimiento
- Mecanismo de consentimiento: no aplica

## 5. Necesidad y proporcionalidad
- Los datos son necesarios para el proposito: si
- Medidas de minimizacion: redaccion, hashing, sin outputs en bruto en prod
- Controles de acceso: auth por token + RBAC
- Transparencia y aviso: aviso de politica interna

## 6. Evaluacion de riesgos
- Riesgos identificados: acceso no autorizado a outputs; sync accidental de datos en bruto
- Probabilidad: media
- Impacto: alto
- Nivel de riesgo: alto

## 7. Medidas de mitigacion
- Controles tecnicos: redaccion, logs de auditoria, FS solo lectura, RBAC
- Controles organizativos: revision de accesos, gestion de cambios
- Riesgo residual tras mitigacion: medio

## 8. Transferencias de datos
- Transferencias internacionales: ninguna
- Salvaguardas (SCC, adecuacion, etc): no aplica

## 9. Consultas y aprobaciones
- DPO consultado: si
- Revision de seguridad completada: si
- Aprobacion final: pendiente

## 10. Referencias
- Politicas: ../policies.md
- Registro de evidencias: ../control-evidence-log.md
- Diagramas del sistema: ../execution-plan.md
