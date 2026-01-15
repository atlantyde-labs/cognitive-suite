# 🧠 Visión de Usuario: Suite Local (Cognitive Suite)

Este documento describe la experiencia de usuario (UX) y los flujos de trabajo cuando la *Atlantyqa Cognitive Suite* está desplegada localmente. A diferencia de la documentación pública institucional, esta guía se enfoca en la interacción real con el producto.

## 🧭 Flujo de Uso General (UI)

### 1. 🟢 Login / Autenticación
El punto de entrada principal garantiza que solo usuarios autorizados accedan al enclave local.
*   **Capacidad**: Integración con LDAP local o SSO corporativo.
*   **Modo de solo lectura**: Disponible para el perfil de *Visor Ejecutivo*.

### 2. 📊 Dashboard Principal
Una vista consolidada de la salud del sistema y el valor generado.
*   **KPIs**: Documentos procesados, tasas de éxito de GitOps, categorías semánticas detectadas.
*   **Eventos**: Timeline de últimos commits, fallos de sincronización y alertas de seguridad.

### 3. 📁 Ingesta Multimodal (Nuevo Análisis)
Interfaz para alimentar el sistema con datos heterogéneos.
*   **Formatos**: PDF, DOCX, TXT, JSON, YAML.
*   **Metadatos**: Etiquetado manual opcional y clasificación previa.

### 4. 🧠 Resultados de Análisis Semántico
El "cerebro" de la suite visualizado.
*   **Entidades**: Mapeo de personas, organizaciones y fechas.
*   **Clasificación de Riesgos**: Identificación automática de puntos críticos.
*   **Timeline de Decisiones**: Rastro de cómo se han categorizado los párrafos del documento.

### 5. 🔁 Integración GitOps
Panel de control para la persistencia y trazabilidad.
*   **Sync Status**: Estado en tiempo real del repositorio Git vinculado.
*   **Automatización**: Generación de Pull Requests (PR) automáticas basadas en los hallazgos del análisis.

---

## 🔐 Requisitos de Diseño No Negociables

1.  **Local-First / Offline**: El diseño debe inspirar confianza. "Tus datos no salen de tu infraestructura". No hay llamadas a APIs externas por defecto.
2.  **Feedback GitOps**: Cada acción debe tener un rastro de sincronización claro.
3.  **Aesthetic High-End**: La interfaz debe ser limpia, moderna y funcional (estética tipo "Enterprise/Military Grade").

---

## 📐 Mapa de Pantallas (Mockups)

*   `Dashboard`: Control de mandos.
*   `Ingest`: Formulario dinámico de subida.
*   `Results`: Panel de lectura enriquecida.
*   `GitOps`: Monitor de sincronización.
