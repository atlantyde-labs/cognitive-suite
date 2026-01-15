---
title: Integración de Open Notebook
description: "Guía para probar e integrar Open Notebook como wrapper en la Cognitive Suite"
---

# Integración de Open Notebook

Open Notebook es una herramienta de código abierto que permite organizar, procesar y conversar con información multimodal (PDFs, vídeos, audio, sitios web, etc.) de forma local y privada【417933048337461†L52-L65】. Dado que su funcionalidad se solapa con la visión de la Cognitive Suite【67584311913060†L18-L26】, podemos emplearla como complemento o referencia. Esta guía ofrece una ruta de **aprendizaje práctico (learning by doing)** para desplegar Open Notebook, probar sus capacidades y crear un adaptador que integre sus servicios con nuestra suite.

## 1. Preparación del entorno

1. **Clonar el repositorio** de Open Notebook. Puedes usar la bifurcación de `kabehz` o el repositorio original. En este ejemplo se utiliza la versión de `kabehz`:

   ```bash
   git clone https://github.com/kabehz/open-notebook.git
   cd open-notebook
   ```

2. **Instalar dependencias**. Open Notebook requiere Python 3.11+, Node.js 18+ y Docker para su entorno completo. Para un entorno de pruebas rápido, ejecuta la instalación con Docker Compose siguiendo las instrucciones de su documentación (ver `docs/1-INSTALLATION/docker-compose.md` en el repositorio). En resumen:

   ```bash
   # Copia el ejemplo de docker-compose y ajusta variables si es necesario
   cp docs/1-INSTALLATION/examples/docker-compose.yml docker-compose.yml
   # Ajusta las claves API en .env o docker-compose.yml según tus proveedores preferidos
   docker compose up -d  # Inicia Open Notebook y sus servicios
   # Accede al frontend en http://localhost:8502 y verifica que el API responde en http://localhost:5055
   ```

3. **Obtener un API key**. Algunas funciones (por ejemplo, chat con modelos de OpenAI) requieren una clave. Define `OPENAI_API_KEY` u otras variables en el fichero `.env` antes de arrancar los contenedores.

## 2. Exploración inicial

Una vez desplegado, entra en la interfaz web (normalmente `http://localhost:8502`) y crea un **Notebook** desde el panel. Anota el ID del notebook creado; lo necesitarás para las llamadas al API.

### 2.1 Cargar contenidos

Utiliza el botón de importación para subir un PDF, un archivo de audio o un vídeo. Open Notebook extraerá el texto, generará embeddings y lo añadirá a su vector store. Comprueba que el contenido aparece en la lista de fuentes.

### 2.2 Búsqueda y chat

Desde la interfaz puedes realizar búsquedas semánticas y chat contextuales. Escribe una consulta relacionada con el contenido importado y observa cómo Open Notebook encuentra los documentos pertinentes y proporciona respuestas con contexto.

## 3. Uso del wrapper en la Cognitive Suite

El módulo `wrappers/open_notebook_wrapper.py` incluido en esta suite proporciona un cliente sencillo para el API de Open Notebook. Estos son los pasos para conectarlo:

1. **Configurar variables**. Define la URL base del API de Open Notebook (`api_url`, p. ej. `http://localhost:5055/api/v1`) y el identificador de notebook (`notebook_id`) en tus scripts. También puedes establecer `api_key` si la autenticación está habilitada.

2. **Ingestar archivos desde la suite**. En tu pipeline de ingesta de la Cognitive Suite, importa `OpenNotebookClient`:

   ```python
   from wrappers.open_notebook_wrapper import OpenNotebookClient
   client = OpenNotebookClient(api_url="http://localhost:5055/api/v1", api_key="TU_API_KEY")
   response = client.ingest_file(Path("ruta/al/archivo.pdf"), notebook_id="ID_DEL_NOTEBOOK")
   print(response)
   ```

   El método `ingest_file` subirá el archivo al notebook indicado y devolverá un JSON con la información de la fuente creada.

3. **Búsqueda desde la suite**. Para realizar una búsqueda semántica y obtener los IDs de las fuentes más relevantes:

   ```python
   results = client.search(notebook_id="ID_DEL_NOTEBOOK", query="riesgos legales de IA", top_k=3)
   for r in results:
       print(r["id"], r["title"], r.get("score"))
   ```

4. **Chat contextual**. Para interactuar con el contenido del notebook empleando un modelo conversacional:

   ```python
   context_ids = [r["id"] for r in results]
   reply = client.chat(notebook_id="ID_DEL_NOTEBOOK", context_ids=context_ids, message="¿Qué riesgos legales tiene la IA?")
   print(reply)
   ```

5. **Integración con el esquema semántico**. Después de obtener respuestas o resultados de búsqueda, puedes mapear la información a tu esquema `semantic-schema.yaml` generando registros con los campos necesarios (`uuid`, `title`, `content_type`, `intent_tags`, etc.). De este modo, los datos provenientes de Open Notebook podrán convivir con los registros analizados por tu pipeline.

## 4. Práctica recomendada de learning by doing

1. **Iterar con pequeños experimentos**: empieza subiendo un PDF sencillo, prueba búsquedas básicas y observa cómo se comporta el wrapper. A continuación, prueba con audio y vídeo.
2. **Registrar observaciones**: cada vez que ejecutes una función del wrapper, guarda las respuestas y anota qué campos son útiles para tu caso de uso (por ejemplo, el resumen generado, los metadatos, etc.).
3. **Refinar adaptadores**: adapta la clase `OpenNotebookClient` según descubras nuevos endpoints o parámetros. Su diseño pretende ser simple para que puedas extenderlo con facilidad.
4. **Unificar resultados**: incorpora los datos obtenidos en los pasos anteriores al pipeline de análisis de la suite. Esto te permitirá comparar la semántica generada por spaCy/transformers con la de Open Notebook y tomar decisiones informadas sobre qué herramienta utilizar para cada tipo de contenido.

## 5. Próximos pasos

- Explorar el resto de la API de Open Notebook (p. ej., creación automática de notebooks, actualización de fuentes, generación de podcasts) e incorporar funciones adicionales al wrapper.
- Considerar el despliegue conjunto mediante Docker Compose, añadiendo un servicio `open_notebook` en tu archivo `docker-compose.yml` y conectando las redes para que la Cognitive Suite se comunique con él.
- Evaluar la convivencia de múltiples vector stores: FAISS (usado por la suite) y SurrealDB (usado por Open Notebook). Podrías mantener ambas bases o migrar a un único backend.

Con esta guía práctica podrás poner en marcha Open Notebook, comprender sus capacidades y comenzar a integrarlo en tu ecosistema de análisis cognitivo de forma iterativa.
