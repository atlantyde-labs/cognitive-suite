# Flujos de Trabajo: Ingesta y Análisis

La Cognitive Suite optimiza el ciclo de vida del dato mediante un flujo intuitivo que transforma documentos en bruto en conocimiento accionable y persistente.

## 📥 Ingesta Multimodal

El proceso comienza en la pantalla de **"Nuevo Documento"**, diseñada para una carga rápida y etiquetada:

### Formulario de Entrada
*   **Archivo**: Selector compatible con PDF, DOCX, TXT, JSON, YAML.
*   **Metadatos**: Título descriptivo, etiquetas corporativas y categoría pre-definida.
*   **Descripción**: Breve contexto para mejorar la precisión del análisis inicial.

### Estados de Carga
1.  **En Cola**: Documento recibido y esperando worker libre.
2.  **Procesando**: Ingesta semántica y fragmentación (chunking).
3.  **Finalizado**: Conocimiento listo para consulta.
4.  **Error**: Fallo en el parseo o validación de seguridad.

---

## 🧠 Resultados de Análisis Semántico

Una vez procesado, el sistema presenta una vista detallada centrada en el valor cognitivo:

### Secciones de Valor
*   **Resumen Automático**: Puntos clave e insights de alto nivel generados por IA local.
*   **Clasificaciones Inteligentes**: Detección de Riesgos, Oportunidades y cumplimiento normativo.
*   **Extracción de Entidades**: Identificación automática de personas, organizaciones, fechas y lugares.
*   **Timeline de Decisiones**: Mapeo temporal de insights basado en la estructura del documento.

### Acciones Post-Análisis
Desde la vista de resultados, el usuario puede:
*   **Exportar**: Descargar el informe en Markdown o PDF.
*   **Corregir**: Ajustar etiquetas y clasificaciones manualmente.
*   **Integrar**: Iniciar el flujo GitOps para persistir el resultado.

---

## 📄 Vista Conceptual de Resultados

```text
Título documento: reporte_seguridad_v1.pdf
----------------------------------------
Resumen automático: Resumen de brechas...
----------------------------------------
Clasificaciones: [RIESGO ALTO] [NORMATIVA]
----------------------------------------
Entidades detectadas: Enclave-A, 2025-01-15
----------------------------------------
Botones: [Exportar] | [Re-analizar] | [Crear PR en Git]
```
