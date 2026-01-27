# Buenas practicas inspiradas en community-scripts/ProxmoxVE

Esta suite adopta practicas seguras y compatibles con las recomendaciones de community-scripts/ProxmoxVE para el uso de scripts en Proxmox:

## Configuracion segura

- **Parser seguro de configuracion**: los `.env` se leen con un parser seguro (sin `source` ni `eval`) y con **whitelist** basada en los `.env.example`.
- **Orden de precedencia**: `ENV del shell > archivo .env > defaults del script`.
- **Global settings**: se admite un archivo global opcional en `/opt/cognitive-suite/.settings` y compatibilidad con `/opt/community-scripts/.settings`.
- **Modo estricto**: si necesitas bloquear claves desconocidas, usa `CS_STRICT_CONFIG=true`.

## Compatibilidad Proxmox/Debian

- **Versiones soportadas**: se recomienda Proxmox VE **8.4.x, 9.0.x o 9.1.x**.
- **Aviso Debian 13**: en plantillas LXC basadas en Debian 13 pueden fallar tareas; se recomienda **Debian 12**.

## Logging y control

- **Logging estructurado** con prefijos consistentes (`CS_LOG_PREFIX`) para trazabilidad.
- **Dry-run** como primer paso antes de aplicar en produccion.

## Notas de seguridad

- El parser seguro evita inyecciones por configuraciones maliciosas.
- La validacion de entradas sigue siendo responsabilidad operativa: revisa los `.env` antes de ejecutar en produccion.
