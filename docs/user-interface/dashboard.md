# Dashboard de Operaciones

El Dashboard principal es el centro de mando de la Cognitive Suite, proporcionando una vista en tiempo real de la salud del sistema y los resultados cognitivos.

## 📊 Componentes del Panel

### 1. Estado del Sistema (Enclave Health)
Muestra la conectividad local, las versiones de los servicios desplegados y el tiempo de actividad (*uptime*).
*   **KPIs**: Disponibilidad de nodos, latencia de base de datos vectorial y estado del broker de eventos.

### 2. Métricas de Análisis
Visualización dinámica de la carga de trabajo:
*   **Documentos Procesados**: Contador total y evolución semanal.
*   **Eficiencia**: Tiempos medios de respuesta por tipo de documento.
*   **Categorización**: Distribución semántica de los insights detectados (Riesgos, Oportunidades, Entidades).

### 3. Actividad GitOps Reciente
Un feed en vivo de las sincronizaciones con los repositorios vinculados:
*   Alertas de conflictos de *merge*.
*   Estado de despliegues automáticos.
*   Historial de commits generados por la IA.

## 🖼️ Mockup Conceptual

```text
+------------------------------------------------------------+
| Logo Suite | Dashboard | Analizar | Repos GitOps | Docs | ▼ |
+------------------------------------------------------------+
| KPI Panel: docs procesados | últimos 7 días | errores  |
+------------------------------------------------------------+
| Gráfica de análisis por categoría semántica               |
+------------------------------------------------------------+
| Columna: últimos documentos      | Estado GitOps           |
+------------------------------------------------------------+
```

## 🚀 Accesos Rápidos
Desde el dashboard, el usuario tiene acceso a un clic para:
*   Iniciar un **Nuevo Análisis**.
*   Auditar **Políticas OPA/Conftest** aplicadas.
*   Vincular nuevos **Repositorios de Conocimiento**.
