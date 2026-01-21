# Políticas (Borrador)

## Clasificación de datos
- Niveles: público, interno, confidencial, restringido.
- Por defecto: todos los datos ingeridos son confidenciales o restringidos.
- Los responsables aprueban la clasificación de cualquier dataset.

## Retención y borrado de datos
- Dev: retener inputs raw máximo 30 días, outputs máximo 90 días.
- Prod: inputs raw deshabilitados por defecto; solo outputs anonimizados.
- Borrado: bajo solicitud en 7 días; verificar eliminación en GitOps remotos.

## Minimización y anonimización
- Guardar solo campos necesarios para outputs de análisis.
- Redactar identificadores personales en resúmenes y entidades.
- Prohibir sincronizar datos raw a repos remotos en prod.
- Las ejecuciones en prod deben usar `COGNITIVE_ENV=prod` y definir `COGNITIVE_HASH_SALT`.
- GitOps en prod debe usar `GITOPS_DATA_MODE=redacted`.

## Control de acceso
- Principio de mínimo privilegio.
- MFA requerido para admin y CI/CD.
- Roles RBAC: viewer, analyst, admin.
- Acceso UI requiere tokens en producción (COGNITIVE_UI_TOKEN_*).

## Cifrado y gestión de claves
- TLS para UI/API en multi-tenant o prod.
- Cifrar datos en reposo (disco u object storage).
- Gestión centralizada de claves (KMS o vault).

## Logging y auditoría
- Registrar quién ejecutó el análisis, cuándo, fuente de input, ubicación de output.
- Guardar logs de auditoría en almacenamiento append-only.
- Retener logs de auditoría mínimo 1 año.

## Hardening de contenedores
- Ejecutar como usuario no-root en contenedores de producción.
- Usar filesystem root read-only con tmpfs para /tmp.
- Eliminar capacidades Linux y aplicar no-new-privileges.

## SDLC seguro
- Revisiones de código obligatorias en áreas sensibles.
- SCA y SBOM obligatorios para builds de release (Grype + artefactos SBOM).
- Actualización de dependencias con cadencia definida.
- Versiones de dependencias fijadas vía lockfiles (`requirements*.txt`).

## Gestión de vulnerabilidades
- Triage en 5 días laborables.
- SLAs de parcheo: crítico 7 días, alto 14 días, medio 30 días.
- Escaneo de secretos requerido en PRs (Gitleaks).

## Respuesta a incidentes
- On-call y ruta de escalado definida.
- Post-incident review y acciones correctivas registradas.

## Reglas soberanas y air-gap
- Builds de producción reproducibles offline.
- Sin egress externo en prod salvo aprobación.
- Datos deben permanecer en regiones aprobadas.
