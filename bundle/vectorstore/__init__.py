# vectorstore/__init__.py
# -----------------------
#
# Este paquete proporciona utilidades para almacenar y consultar
# representaciones vectoriales de documentos. Su propósito es
# facilitar la implementación de búsquedas semánticas y mecanismos
# de recuperación aumentada (RAG) dentro de la Cognitive Suite.

from .faiss_store import FaissVectorStore

__all__ = ["FaissVectorStore"]
