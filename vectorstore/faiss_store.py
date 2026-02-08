# faiss_store.py
# ---------------
#
# Implementación sencilla de un almacén vectorial basado en FAISS.
# Permite construir un índice a partir de embeddings, añadir nuevos
# vectores y ejecutar búsquedas por similitud. Este módulo no
# persiste el índice en disco; se espera que el pipeline lo
# reconstruya cuando sea necesario. Se basa en FAISS, por lo que
# depende del paquete ``faiss-cpu``.

from __future__ import annotations

from typing import List, Tuple

import faiss  # type: ignore
import numpy as np


class FaissVectorStore:
    """Pequeño wrapper para un índice FAISS de vectores de densidad fija.

    Esta clase gestiona un índice FAISS ``IndexFlatL2`` y mantiene
    un mapeo entre posiciones del índice y metadatos asociados a los
    vectores (por ejemplo, los identificadores de los registros).

    Uso básico:

    ```python
    store = FaissVectorStore(dimension=768)
    ids = [r["uuid"] for r in records]
    embeddings = np.array([model.encode(r["summary"]) for r in records], dtype=np.float32)
    store.build(embeddings, ids)
    results = store.search(query_embedding, k=5)
    ```
    """

    def __init__(self, dimension: int) -> None:
        self.dimension = dimension
        self.index = faiss.IndexFlatL2(dimension)
        self.id_map: List[str] = []

    def build(self, embeddings: np.ndarray, ids: List[str]) -> None:
        """Construye el índice a partir de un array de vectores y una lista de IDs.

        :param embeddings: matriz de vectores con forma (n, dimension)
        :param ids: lista de identificadores con longitud n
        """
        if embeddings.dtype != np.float32:
            embeddings = embeddings.astype(np.float32)
        self.index.reset()
        self.index.add(embeddings)
        self.id_map = list(ids)

    def add(self, embedding: np.ndarray, record_id: str) -> None:
        """Añade un vector y su ID al índice.

        :param embedding: vector de características (1D o 2D)
        :param record_id: identificador asociado al vector
        """
        emb = embedding.astype(np.float32)
        if emb.ndim == 1:
            emb = emb[None, :]
        self.index.add(emb)
        self.id_map.append(record_id)

    def search(self, query_embedding: np.ndarray, k: int = 5) -> List[Tuple[str, float]]:
        """Realiza una búsqueda k-NN y devuelve los IDs y distancias.

        :param query_embedding: vector de consulta de longitud ``dimension``
        :param k: número máximo de vecinos a devolver
        :return: lista de tuplas (id, distancia)
        """
        emb = query_embedding.astype(np.float32)
        if emb.ndim == 1:
            emb = emb[None, :]
        distances, indices = self.index.search(emb, k)
        results: List[Tuple[str, float]] = []
        for dist, idx in zip(distances[0], indices[0]):
            if idx < len(self.id_map):
                results.append((self.id_map[idx], float(dist)))
        return results
