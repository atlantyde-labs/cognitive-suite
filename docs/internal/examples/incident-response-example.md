# Ejemplo de respuesta a incidentes (Ficticio)

## Resumen del incidente
- ID de incidente: IR-2026-001
- Severidad: SEV2
- Detectado: 2026-02-10 09:12 UTC
- Resuelto: 2026-02-10 12:05 UTC
- Resumen: intento de acceso no autorizado a la UI detectado y bloqueado

## Linea de tiempo
- 09:12 UTC: alerta por multiples intentos de login fallidos
- 09:15 UTC: rotacion de token de acceso
- 09:20 UTC: revision de logs de auditoria
- 10:00 UTC: IP de origen bloqueada en el borde
- 12:05 UTC: incidente cerrado

## Acciones de contencion
- Sync GitOps deshabilitado durante la revision
- Tokens de UI rotados

## Causa raiz
- Token reutilizado desde entorno de pruebas

## Acciones correctivas
- Forzar tokens unicos por entorno
- Agregar calendario de rotacion de tokens

## Evidencias
- Logs de auditoria: audit/ui_access.jsonl
- Registro de cambios: ../control-evidence-log.md
