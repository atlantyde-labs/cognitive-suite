# Nota de endurecimiento (Ficticio)

- Fecha: 2026-02-14
- Alcance: compose de produccion
- Controles verificados:
  - usuario non-root
  - filesystem de solo lectura
  - tmpfs para /tmp
  - no-new-privileges
  - capacidades eliminadas
- Riesgo residual: sin perfil seccomp/apparmor aplicado
- Seguimiento: definir perfil seccomp para produccion
