#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
open_notebook_wrapper.py
------------------------

Este módulo actúa como un adaptador entre la Cognitive Suite y el API
de Open Notebook. Permite enviar documentos a Open Notebook para su
procesamiento, realizar búsquedas vectoriales y mantener diálogos con
contexto. Está pensado para ser importado desde el pipeline o
cualquier otro componente de la suite.

Nota: este wrapper asume que Open Notebook se está ejecutando como un
servicio HTTP accesible en ``api_url`` y que se dispone de una
``api_key`` válida para autenticarse. La estructura de los endpoints
puede cambiar según la versión de Open Notebook; consulte su
documentación para obtener detalles actualizados.
"""
from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, List, Optional

import requests  # type: ignore


class OpenNotebookClient:
    """Cliente básico para interactuar con el API REST de Open Notebook."""

    def __init__(self, api_url: str, api_key: Optional[str] = None) -> None:
        self.api_url = api_url.rstrip('/')
        self.api_key = api_key
        self.session = requests.Session()
        if api_key:
            self.session.headers.update({"Authorization": f"Bearer {api_key}"})

    def ingest_file(self, file_path: Path, notebook_id: str) -> Dict[str, Any]:
        """Envía un archivo para su ingesta en Open Notebook.

        :param file_path: Ruta del archivo a subir
        :param notebook_id: Identificador del notebook en el que se almacenará
        :return: Respuesta JSON del API
        """
        url = f"{self.api_url}/notebooks/{notebook_id}/sources"
        files = {
            "file": (file_path.name, file_path.open("rb"), "application/octet-stream"),
        }
        data = {
            "source_type": "file",
            "title": file_path.stem,
        }
        resp = self.session.post(url, data=data, files=files)
        resp.raise_for_status()
        return resp.json()

    def search(self, notebook_id: str, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """Realiza una búsqueda semántica en un notebook.

        :param notebook_id: ID del notebook
        :param query: Cadena de consulta
        :param top_k: Número de resultados a devolver
        :return: Lista de resultados con id, título y score
        """
        url = f"{self.api_url}/notebooks/{notebook_id}/search"
        payload = {"query": query, "top_k": top_k}
        resp = self.session.post(url, json=payload)
        resp.raise_for_status()
        return resp.json().get("results", [])

    def chat(self, notebook_id: str, context_ids: List[str], message: str) -> str:
        """Mantiene una conversación con contexto usando un notebook.

        :param notebook_id: ID del notebook
        :param context_ids: Lista de IDs de fuentes o notas relevantes
        :param message: Pregunta o mensaje del usuario
        :return: Respuesta generada por el asistente de Open Notebook
        """
        url = f"{self.api_url}/notebooks/{notebook_id}/chat"
        payload = {"context_ids": context_ids, "message": message}
        resp = self.session.post(url, json=payload)
        resp.raise_for_status()
        data = resp.json()
        return data.get("reply", "")


__all__ = ["OpenNotebookClient"]
