---
title: Open Notebook Integration
description: "Guide to test and integrate Open Notebook as a wrapper in the Cognitive Suite"
---

# Open Notebook Integration

Open Notebook is an open-source tool that allows you to organize, process, and
chat with multimodal information (PDFs, videos, audio, websites, etc.) locally
and privately. Since its functionality overlaps with
the vision of the Cognitive Suite, we can use it as a
complement or reference. This guide provides a **learning by doing** path to
deploy Open Notebook, test its capabilities, and create an adapter that
integrates its services with our suite.

## 1. Environment preparation

1. **Clone the Open Notebook repo**. You can use the `kabehz` fork or the
   original repository. This example uses the `kabehz` version:

   ```bash
   git clone https://github.com/kabehz/open-notebook.git
   cd open-notebook
   ```

2. **Install dependencies**. Open Notebook requires Python 3.11+, Node.js 18+
   and Docker for a complete environment. For a quick test setup, run the
   Docker Compose installation following their documentation (see
   `docs/1-INSTALLATION/docker-compose.md` in the repo). In short:

   ```bash
   # Copy the docker-compose example and adjust variables if needed
   cp docs/1-INSTALLATION/examples/docker-compose.yml docker-compose.yml
   # Adjust API keys in .env or docker-compose.yml for your providers
   docker compose up -d  # Start Open Notebook and its services
   # Open the frontend at http://localhost:8502 and verify the API at http://localhost:5055
   ```

3. **Get an API key**. Some functions (e.g., chat with OpenAI models) require a
   key. Set `OPENAI_API_KEY` or other variables in `.env` before starting the
   containers.

## 2. Initial exploration

Once deployed, open the web interface (usually `http://localhost:8502`) and
create a **Notebook** from the panel. Note the notebook ID; you will need it
for API calls.

### 2.1 Load content

Use the import button to upload a PDF, audio file, or video. Open Notebook will
extract text, generate embeddings, and add it to its vector store. Confirm the
content appears in the sources list.

### 2.2 Search and chat

From the UI you can perform semantic search and contextual chat. Enter a query
related to the imported content and observe how Open Notebook finds the
relevant documents and provides contextual answers.

## 3. Using the wrapper in the Cognitive Suite

The `wrappers/open_notebook_wrapper.py` module in this suite provides a simple
client for the Open Notebook API. Steps to connect it:

1. **Configure variables**. Define the Open Notebook API base URL (`api_url`,
   e.g., `http://localhost:5055/api/v1`) and the notebook identifier
   (`notebook_id`) in your scripts. You can also set `api_key` if authentication
   is enabled.

2. **Ingest files from the suite**. In your Cognitive Suite ingest pipeline,
   import `OpenNotebookClient`:

   ```python
   from wrappers.open_notebook_wrapper import OpenNotebookClient
   client = OpenNotebookClient(api_url="http://localhost:5055/api/v1", api_key="YOUR_API_KEY")
   response = client.ingest_file(Path("path/to/file.pdf"), notebook_id="NOTEBOOK_ID")
   print(response)
   ```

   The `ingest_file` method uploads the file to the notebook and returns a JSON
   with information about the created source.

3. **Search from the suite**. To run a semantic search and get the most
   relevant source IDs:

   ```python
   results = client.search(notebook_id="NOTEBOOK_ID", query="legal risks of AI", top_k=3)
   for r in results:
       print(r["id"], r["title"], r.get("score"))
   ```

4. **Contextual chat**. To interact with notebook content using a
   conversational model:

   ```python
   context_ids = [r["id"] for r in results]
   reply = client.chat(notebook_id="NOTEBOOK_ID", context_ids=context_ids, message="What legal risks does AI have?")
   print(reply)
   ```

5. **Semantic schema integration**. After obtaining responses or search
   results, map the information to your `semantic-schema.yaml` by generating
   records with the required fields (`uuid`, `title`, `content_type`,
   `intent_tags`, etc.). This allows Open Notebook data to coexist with records
   analyzed by your pipeline.

## 4. Recommended learning by doing practice

1. **Iterate with small experiments**: start by uploading a simple PDF, run
   basic searches, and observe wrapper behavior. Then try audio and video.
2. **Record observations**: each time you run a wrapper function, save the
   responses and note which fields are useful for your use case (e.g., summary,
   metadata).
3. **Refine adapters**: adapt `OpenNotebookClient` as you discover new
   endpoints or parameters. Its design is intentionally simple so you can
   extend it easily.
4. **Unify results**: incorporate the data obtained into the suite analysis
   pipeline. This lets you compare semantics from spaCy/transformers with
   Open Notebook and make informed decisions on which tool to use for each
   content type.

## 5. Next steps

- Explore the rest of the Open Notebook API (e.g., automatic notebook creation,
  source updates, podcast generation) and add additional wrapper functions.
- Consider a joint deployment via Docker Compose, adding an `open_notebook`
  service in `docker-compose.yml` and connecting networks so the Cognitive
  Suite can communicate with it.
- Evaluate the coexistence of multiple vector stores: FAISS (suite) and
  SurrealDB (Open Notebook). You can keep both or migrate to a single backend.

With this guide you can get Open Notebook running, understand its capabilities,
and begin integrating it into your cognitive analysis ecosystem iteratively.
