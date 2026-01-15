# Interfaz de Línea de Comandos (CLI)

Para los administradores de sistemas y perfiles técnicos (ASIR/DevOps), **Atlantyqa Cognitive Suite** ofrece una potente interfaz de línea de comandos basada en Python. Esto permite la automatización, el scripting y la gestión del enclave sin necesidad de utilizar la interfaz gráfica.

## Instalación

El CLI está disponible como un paquete de Python y se puede instalar en cualquier entorno compatible con Linux/Unix dentro del enclave local:

```bash
pip install atlantyqa-cli
```

## Comandos Principales

### 1. Ingesta de Documentos
Permite enviar archivos al motor de procesamiento semántico de forma directa.

```bash
atlantyqa ingest --file report_q1.pdf --title "Análisis Trimestral" --tags legal,risk
```

### 2. Monitorización en Tiempo Real
Visualiza los logs del worker local directamente en la terminal, ideal para depuración de infraestructura.

```bash
atlantyqa logs --follow
```

### 3. Gestión de Enclave (Local-First)
Verifica el estado de los modelos locales y el uso de recursos (GPU/RAM) del motor cognitivo.

```bash
atlantyqa status --detailed
```

### 4. Sincronización GitOps
Forzar la persistencia de resultados en el repositorio local y generar el Pull Request correspondiente.

```bash
atlantyqa gitops sync --message "feat: weekly-analysis-sync"
```

## Integración con Pipelines
El CLI está diseñado para ser utilizado en scripts de Bash o pipelines de CI/CD locales, permitiendo que el análisis cognitivo sea una pieza más del flujo de trabajo de IT:

```bash
#!/bin/bash
# Script de análisis automático nocturno
FILES=$(ls /data/incoming/*.pdf)

for file in $FILES; do
    atlantyqa ingest --file "$file" --silent
done

atlantyqa gitops sync --message "auto: nightly-batch-process"
```

> [!TIP]
> Puedes obtener una lista completa de comandos y opciones ejecutando `atlantyqa --help`.
