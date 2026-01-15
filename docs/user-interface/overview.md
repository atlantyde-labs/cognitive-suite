# Interfaz de Usuario Local

La visión de usuario de la **Atlantyqa Cognitive Suite** se centra en una experiencia *local-first*, segura y orientada a la eficiencia operativa a través de GitOps.

## 👥 Roles del Sistema

| Rol | Descripción | Capacidades Clave |
| :--- | :--- | :--- |
| **Administrador Local** | Gestor de la infraestructura y políticas. | Configuración, gestión de usuarios, auditoría de datos. |
| **Analista de Conocimiento** | Usuario principal de análisis semántico. | Ingesta de datos, ejecución de análisis, etiquetado cognitivo. |
| **Operador GitOps** | Responsable de la persistencia y despliegue. | Control de repositorios, gestión de Pull Requests, validación de políticas. |
| **Visor Ejecutivo** | Usuario de consulta y reportes. | Acceso a dashboards críticos y exportación de informes. |

## 🧭 Flujo de Uso General

Cualquier interacción con la suite desplegada en entornos locales (K8s / Docker) sigue este flujo optimizado:

1.  **Autenticación**: Acceso seguro mediante LDAP local o SSO corporativo.
2.  **Dashboard**: Visión global del estado del enclave y KPIs de análisis.
3.  **Ingesta**: Carga multimodal de documentos (PDF, JSON, YAML, etc.).
4.  **Análisis**: Procesamiento semántico con generación automática de insights.
5.  **GitOps**: Persistencia automática de resultados en repositorios Git mediante Branches y PRs.

## 🔐 Requisitos UX No Negociables

*   **Modo Offline**: Todo el procesamiento ocurre dentro de tu infraestructura. "Tu dato no sale de tu enclave".
*   **Feedback GitOps**: Estado de sincronización siempre visible para acciones críticas.
*   **Control de Versiones**: Cada análisis e informe cuenta con trazabilidad total en Git.
