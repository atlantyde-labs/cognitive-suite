#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
frontend/streamlit_app.py
-------------------------

Interfaz interactiva basada en Streamlit para explorar los resultados del
análisis cognitivo. Esta aplicación permite cargar el fichero
``analysis.json`` generado por el pipeline, visualizar los registros
como una tabla y filtrar por etiquetas cognitivas. También muestra
detalles individuales al seleccionar un registro.

Para ejecutar en local (en desarrollo):

```
streamlit run frontend/streamlit_app.py --server.headless true --server.port 8501
```

Al ejecutar dentro del contenedor Docker de ``frontend`` se utiliza
``streamlit run`` en el ``CMD``.
"""

import json
import os
from pathlib import Path
from typing import List, Dict, Any

import pandas as pd  # type: ignore
import streamlit as st  # type: ignore


def load_data(path: Path) -> List[Dict[str, Any]]:
    """Carga el archivo de análisis JSON y devuelve una lista de registros."""
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []


def main() -> None:
    st.set_page_config(page_title="Cognitive Suite Analysis", layout="wide")
    st.title("📊 Cognitive Suite – Resultados del Análisis")
    base = Path(os.getenv("COGNITIVE_OUTPUTS", "outputs"))
    analysis_path = base / "insights" / "analysis.json"
    data = load_data(analysis_path)
    if not data:
        msg = (
            f"No se encontró el archivo de análisis en: {analysis_path}."
            "\n\nEjecuta primero el pipeline o monta outputs en Docker y define COGNITIVE_OUTPUTS."
        )
        st.warning(msg)
        return
    # Convertir a DataFrame para representación tabular
    df = pd.DataFrame([
        {
            "uuid": rec.get("uuid"),
            "archivo": Path(rec.get("file", "")).name,
            "tipo": rec.get("content_type"),
            "palabras": rec.get("word_count"),
            "etiquetas": ", ".join(rec.get("intent_tags", [])),
            "sentimiento": rec.get("sentiment", {}).get("label"),
            "relevancia": rec.get("relevance_score"),
        }
        for rec in data
    ])
    # Filtro por etiquetas
    all_tags = sorted({tag for rec in data for tag in rec.get("intent_tags", [])})
    selected_tags = st.multiselect("Filtra por etiquetas cognitivas", options=all_tags, default=all_tags)
    if selected_tags and len(selected_tags) < len(all_tags):
        mask = df["etiquetas"].apply(lambda x: any(tag in x for tag in selected_tags))
        df_display = df[mask]
    else:
        df_display = df
    st.dataframe(df_display, use_container_width=True)
    # Seleccionar un registro para detalles
    st.subheader("Detalles del registro")
    selected_uuid = st.selectbox(
        "Seleccione un UUID para ver detalles", options=["(Seleccione)"] + list(df_display["uuid"])
    )
    if selected_uuid and selected_uuid != "(Seleccione)":
        rec = next((r for r in data if r.get("uuid") == selected_uuid), None)
        if rec:
            st.write(f"### {rec.get('title')}")
            st.write(f"**Archivo:** {rec.get('file')}")
            st.write(f"**Tipo de contenido:** {rec.get('content_type')}")
            st.write(f"**Etiquetas:** {', '.join(rec.get('intent_tags', []))}")
            st.write(f"**Sentimiento:** {rec.get('sentiment', {}).get('label')} (score: {rec.get('sentiment', {}).get('score')})")
            st.write(f"**Resumen:** {rec.get('summary')}")
            if rec.get('entities'):
                st.write("**Entidades:**")
                ent_df = pd.DataFrame(rec['entities'], columns=["Tipo", "Texto"])
                st.table(ent_df)
            if rec.get('author_signature'):
                st.write(f"**Firma de autor:** {rec.get('author_signature')}")
            st.write(f"**Puntuación de relevancia:** {rec.get('relevance_score')}")


if __name__ == "__main__":
    main()
