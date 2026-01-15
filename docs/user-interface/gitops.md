# Integración GitOps

El **GitOps Panel** es el puente entre el análisis cognitivo y la persistencia institucional. Garantiza que cada insight se convierta en un activo digital versionado y auditable.

## 🔁 Panel de Sincronización

El panel ofrece visibilidad total sobre el estado de la infraestructura de conocimiento:

### Repositorios Conectados
*   **Lista de Repositorios**: Enlaces a los repos de configuración y documentación.
*   **Estado de Sincronización**: Indicadores visuales de éxito o fallo en la última sincronización.
*   **Último Commit**: Firma del último cambio aplicado al enclave.

### Ciclo de Vida del Insight
La suite automatiza la persistencia siguiendo el flujo estándar de desarrollo:
1.  **Branching**: Se crea una rama efímera para el nuevo análisis.
2.  **Committing**: El resultado se guarda como un archivo estructurado (Markdown/JSON).
3.  **Pull Request**: Se genera automáticamente un PR en el repo original para revisión humana.

## 🛡️ Políticas de Control (OPA / Conftest)
Antes de que un cambio se persista, el sistema valida:
*   **Seguridad**: Reglas de exclusión de datos sensibles.
*   **Cumplimiento**: Validación formativa y estructural.
*   **Aprobación**: Estado de los checks de integración.

## 🛠️ Acciones de Gestión
*   **Forzar Sincronización**: Re-intentar la conexión con el upstream.
*   **Resolver Conflictos**: Interfaz guiada para resolver diferencias entre el análisis local y el repositorio remoto.
*   **Auditoría de PRs**: Listado de Pull Requests abiertos clasificados por su origen cognitivo.
