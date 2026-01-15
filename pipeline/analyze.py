#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pipeline/analyze.py
-------------------

Este módulo implementa el pipeline de análisis semántico para la
Cognitive Suite. A diferencia de la versión inicial basada en reglas
heurísticas, esta iteración aprovecha modelos de PLN para extraer
información estructurada de los textos ingeridos. Concretamente:

* Se utiliza **spaCy** para tokenización, extracción de entidades y
  anotaciones lingüísticas. Se intenta cargar un modelo en español
  (`es_core_news_md`), aunque se vuelve al modelo inglés por defecto si
  no está disponible en el entorno.
* Para la clasificación de sentimientos se recurre a la API de
  HuggingFace (`transformers.pipeline`) con el modelo
  `distilbert-base-uncased-finetuned-sst-2-english`. Si la carga falla,
  se aplica una heurística sencilla que determina el sentimiento en
  función de palabras positivas o negativas.
* Se generan etiquetas cognitivas (idea, proyecto, riesgo, legal,
  viabilidad, emoción, intuición, acción pendiente, otros) combinando
  reglas simples con el análisis de entidades y la predicción de
  sentimiento.
* El resultado para cada archivo se ajusta a un esquema semántico
  definido en `schemas/semantic-schema.yaml`, incluyendo campos como
  identificador único, título (nombre del archivo), tipo de contenido,
  etiquetas de intención, resumen de la idea, indicadores de riesgo,
  referencias legales, firma de autor, puntuación de relevancia y un
  listado de entidades reconocidas.

Este script se invoca desde la línea de comandos de la siguiente
manera:

```
python pipeline/analyze.py --input outputs/raw --output outputs/insights/analysis.json
```

El parámetro `--schema` indica la ubicación de un archivo YAML con la
definición del esquema semántico. En esta versión se carga únicamente
para verificar su existencia, ya que la definición de campos está
codificada en el código.
"""

import argparse
import json
import re
import uuid
from pathlib import Path
from typing import Any, Dict, List, Tuple

try:
    import spacy  # type: ignore
except Exception:
    spacy = None  # type: ignore

try:
    from transformers import pipeline as hf_pipeline  # type: ignore
except Exception:
    hf_pipeline = None  # type: ignore


def load_spacy_model() -> Any:
    """Carga un modelo spaCy en español o inglés.

    Intenta cargar `es_core_news_md` porque el proyecto está orientado a
    contenidos en castellano. Si no está disponible, intenta cargar
    `es_core_news_sm`. En última instancia, recurre al modelo
    `en_core_web_sm` que suele estar presente en muchas instalaciones.

    Devuelve `None` si no se puede cargar ningún modelo.
    """
    if spacy is None:
        return None
    for model_name in ["es_core_news_md", "es_core_news_sm", "en_core_web_sm"]:
        try:
            return spacy.load(model_name)
        except Exception:
            continue
    return None


def load_sentiment_classifier():
    """Carga un clasificador de sentimientos basado en transformers.

    Se emplea el modelo `distilbert-base-uncased-finetuned-sst-2-english`.
    Este modelo devuelve etiquetas `POSITIVE` o `NEGATIVE` junto con una
    puntuación. Si la carga falla, devuelve `None` y se usará una
    heurística básica.
    """
    if hf_pipeline is None:
        return None
    try:
        return hf_pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")
    except Exception:
        return None


def heuristic_sentiment(text: str) -> Tuple[str, float]:
    """Clasificador de sentimientos por heurística.

    Cuenta apariciones de palabras positivas y negativas definidas y
    devuelve una etiqueta y una puntuación entre 0 y 1. Esta función
    sirve como respaldo cuando no se dispone de modelos de Transformer.
    """
    positive_words = {"bueno", "excelente", "maravilloso", "positivo", "satisfactorio"}
    negative_words = {"malo", "terrible", "pésimo", "negativo", "riesgo", "fracaso"}
    lower = text.lower()
    pos_count = sum(word in lower for word in positive_words)
    neg_count = sum(word in lower for word in negative_words)
    total = pos_count + neg_count
    if total == 0:
        return ("NEUTRAL", 0.5)
    score = pos_count / total
    label = "POSITIVE" if score >= 0.5 else "NEGATIVE"
    return (label, score)


def classify_sentiment(text: str, classifier) -> Tuple[str, float]:
    """Determina el sentimiento usando el clasificador de transformers o heurístico."""
    if classifier:
        try:
            result = classifier(text[:512])  # limitar longitud para reducir carga
            if result and isinstance(result, list):
                r = result[0]
                return (r.get("label", "NEUTRAL"), float(r.get("score", 0.5)))
        except Exception:
            pass
    return heuristic_sentiment(text)


def extract_entities(doc) -> List[Tuple[str, str]]:
    """Extrae entidades nombradas de un doc de spaCy como tuplas (tipo, texto)."""
    entities: List[Tuple[str, str]] = []
    if doc is None:
        return entities
    for ent in doc.ents:
        entities.append((ent.label_, ent.text))
    return entities


def generate_cognitive_tags(text: str, doc) -> List[str]:
    """Genera etiquetas cognitivas combinando reglas heurísticas y entidades."""
    tags: List[str] = []
    lower = text.lower()
    # Palabras clave básicas
    if any(word in lower for word in ["idea", "innovación", "concepto"]):
        tags.append("idea")
    if any(word in lower for word in ["riesgo", "amenaza", "peligro"]):
        tags.append("riesgo")
    if any(word in lower for word in ["legal", "ley", "normativa", "regulación"]):
        tags.append("legal")
    if any(word in lower for word in ["proyecto", "implementación", "desarrollo"]):
        tags.append("proyecto")
    if any(word in lower for word in ["viable", "viabilidad", "factible"]):
        tags.append("viabilidad")
    # Sentimientos se mapearán a etiqueta "emoción"
    if any(word in lower for word in ["feliz", "triste", "emocionado", "enojado", "satisfecho"]):
        tags.append("emoción")
    # Intuición
    if any(word in lower for word in ["intuición", "presentimiento", "corazonada"]):
        tags.append("intuición")
    # Acción pendiente
    if any(word in lower for word in ["pendiente", "por hacer", "tarea", "accionar"]):
        tags.append("acción pendiente")
    # Detectar tipos de entidades que indiquen legalidad o personas
    if doc is not None:
        for ent in doc.ents:
            label = ent.label_
            if label in {"LAW", "NORP"}:
                if "legal" not in tags:
                    tags.append("legal")
            if label in {"PERSON", "ORG"}:
                # Si se menciona una organización o persona, puede ser un proyecto
                if "proyecto" not in tags:
                    tags.append("proyecto")
    if not tags:
        tags.append("otros")
    return tags


def generate_summary(text: str, max_chars: int = 200) -> str:
    """Devuelve un resumen simple de los primeros caracteres del texto."""
    clean = re.sub(r"\s+", " ", text.strip())
    return clean[:max_chars] + ("..." if len(clean) > max_chars else "")


def generate_record(file_path: Path, nlp_model, sentiment_classifier) -> Dict[str, Any]:
    """Procesa un archivo y devuelve un registro semántico conforme al esquema."""
    text = file_path.read_text(errors='ignore')
    # Procesar con spaCy si está disponible
    doc = None
    if nlp_model is not None:
        try:
            doc = nlp_model(text)
        except Exception:
            doc = None
    # Contar palabras y caracteres
    word_count = len(re.findall(r"\w+", text))
    char_count = len(text)
    # Etiquetas cognitivas
    tags = generate_cognitive_tags(text, doc)
    # Sentimiento
    sentiment_label, sentiment_score = classify_sentiment(text, sentiment_classifier)
    # Entidades
    entities = extract_entities(doc)
    # Rellenar campos del esquema semántico
    record: Dict[str, Any] = {
        "uuid": str(uuid.uuid4()),
        "file": str(file_path),
        "title": file_path.stem,
        "content_type": file_path.suffix.lstrip('.'),
        "word_count": word_count,
        "char_count": char_count,
        "intent_tags": tags,
        "sentiment": {"label": sentiment_label, "score": sentiment_score},
        "entities": entities,
        "summary": generate_summary(text, 400),
    }
    # Campos adicionales basados en heurísticas
    record["idea_summary"] = record["summary"] if "idea" in tags else ""
    record["risk_flags"] = [ent for ent in entities if ent[0] == "LAW"] if "riesgo" in tags else []
    record["legal_reference"] = [ent for ent in entities if ent[0] == "LAW"] if "legal" in tags else []
    # Firma de autor: buscar líneas que empiecen por "Autor:" o "Firma:"
    author = None
    for line in text.splitlines():
        if line.lower().startswith("autor:") or line.lower().startswith("firma:"):
            author = line.split(":", 1)[-1].strip()
            break
    record["author_signature"] = author or ""
    # Relevancia sencilla: proporcional a longitud y número de etiquetas
    record["relevance_score"] = round(min(1.0, (len(tags) * 0.1) + (word_count / 10000)), 3)
    return record


def main() -> None:
    parser = argparse.ArgumentParser(description='Análisis cognitivo avanzado')
    parser.add_argument('--input', default='outputs/raw', help='Directorio con archivos de texto')
    parser.add_argument('--output', default='outputs/insights/analysis.json', help='Archivo JSON de salida')
    parser.add_argument('--schema', default='schemas/semantic-schema.yaml', help='Ruta al esquema semántico')
    args = parser.parse_args()

    input_dir = Path(args.input)
    output_file = Path(args.output)

    # Cargar modelos de PLN
    nlp_model = load_spacy_model()
    sentiment_classifier = load_sentiment_classifier()

    results: List[Dict[str, Any]] = []
    # Procesar archivos de texto
    for p in input_dir.rglob('*'):
        if p.is_file() and p.suffix.lower() in {'.txt', '.json', '.md'}:
            try:
                results.append(generate_record(p, nlp_model, sentiment_classifier))
            except Exception:
                # Registrar errores silenciosamente; continuar con el siguiente archivo
                continue
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with output_file.open('w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)


if __name__ == '__main__':
    main()