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
* El resultado para cada archivo se ajusta al esquema de insights
  definido en `schemas/insight.schema.json`, manteniendo los campos
  historicos del esquema semantico y agregando trazabilidad GitOps.

Este script se invoca desde la línea de comandos de la siguiente
manera:

```
python pipeline/analyze.py --input outputs/raw --output outputs/insights/analysis.json
```

El parametro `--schema` indica la ubicacion de un archivo con la
definicion del esquema. En esta version se carga unicamente para
verificar su existencia, ya que la definicion de campos esta codificada
en el codigo.
"""

import argparse
import hashlib
import json
import logging
import os
import re
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

try:
    import spacy  # type: ignore
except ImportError:
    spacy = None  # type: ignore

try:
    from transformers import pipeline as hf_pipeline  # type: ignore
except ImportError:
    hf_pipeline = None  # type: ignore

# Configurar logging
logging.basicConfig(
    level=logging.WARNING,  # Solo warnings y errores por defecto
    format='%(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)
# Desactivar logs de transformers que no son informativos
logging.getLogger("transformers").setLevel(logging.ERROR)
logging.getLogger("huggingface_hub").setLevel(logging.ERROR)

REDACTION_ENTITY_LABELS = {"PERSON", "PER", "ORG", "GPE", "LOC", "FAC", "NORP", "LAW"}
EMAIL_RE = re.compile(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
PHONE_RE = re.compile(r"\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}\b")
IPV4_RE = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")
SSN_RE = re.compile(r"\b\d{3}-\d{2}-\d{4}\b")
CARD_RE = re.compile(r"\b(?:\d[ -]*?){13,19}\b")
CURRENCY_RE = re.compile(r"\b\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?\s?(?:€|\$|USD|EUR)")


def should_skip_models() -> bool:
    """Indica si se deben omitir cargas de modelos pesados (modo playground/CI)."""
    for key in ("COGNITIVE_SKIP_MODELS", "COGNITIVE_FAST_MODE"):
        value = os.getenv(key, "").strip().lower()
        if value in {"1", "true", "yes"}:
            return True
    return False


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_env(value: str) -> str:
    env = (value or "dev").strip().lower()
    if env in {"prod", "production"}:
        return "prod"
    if env in {"dev", "development", "local"}:
        return "dev"
    logger.warning("Valor desconocido de COGNITIVE_ENV=%s. Se usa 'dev'.", value)
    return "dev"


def hash_identifier(value: str, salt: str) -> str:
    payload = f"{salt}{value}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()[:12]


def hash_text(value: str, salt: str) -> str:
    payload = f"{salt}{value}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def luhn_check(number: str) -> bool:
    digits = [int(ch) for ch in number if ch.isdigit()]
    if len(digits) < 13 or len(digits) > 19:
        return False
    checksum = 0
    parity = len(digits) % 2
    for idx, digit in enumerate(digits):
        if idx % 2 == parity:
            digit *= 2
            if digit > 9:
                digit -= 9
        checksum += digit
    return checksum % 10 == 0


def redact_credit_cards(text: str) -> str:
    def replacer(match: re.Match[str]) -> str:
        raw = match.group(0)
        digits = "".join(ch for ch in raw if ch.isdigit())
        if luhn_check(digits):
            return "[REDACTED_CARD]"
        return raw

    return CARD_RE.sub(replacer, text)


def redact_regex(text: str) -> str:
    text = EMAIL_RE.sub("[REDACTED_EMAIL]", text)
    text = IPV4_RE.sub("[REDACTED_IP]", text)
    text = SSN_RE.sub("[REDACTED_SSN]", text)
    text = redact_credit_cards(text)
    text = PHONE_RE.sub("[REDACTED_PHONE]", text)
    text = CURRENCY_RE.sub("[REDACTED_MONEY]", text)
    return text


def redact_text(text: str, doc: Optional[Any]) -> str:
    redacted = text
    if doc is not None:
        try:
            for ent in doc.ents:
                if ent.label_ in REDACTION_ENTITY_LABELS:
                    ent_text = ent.text.strip()
                    if len(ent_text) >= 3:
                        pattern = re.compile(re.escape(ent_text), re.IGNORECASE)
                        redacted = pattern.sub(f"[REDACTED_{ent.label_}]", redacted)
        except Exception as e:
            logger.debug("Error al aplicar redacción por entidades: %s", e)
    return redact_regex(redacted)


def redact_record(
    record: Dict[str, Any],
    doc: Optional[Any],
    hash_salt: str,
    env: str
) -> Dict[str, Any]:
    redacted = dict(record)
    file_name = Path(record.get("file", "")).name
    file_hash = hash_identifier(file_name or record.get("uuid", ""), hash_salt)
    redacted["uuid"] = hash_identifier(record.get("uuid", ""), hash_salt)
    redacted["file"] = f"file_{file_hash}"
    redacted["title"] = f"document_{file_hash}"
    redacted["summary"] = redact_text(record.get("summary", ""), doc)
    redacted["idea_summary"] = redact_text(record.get("idea_summary", ""), doc)
    redacted["entities"] = [
        (label, "[REDACTED]") for label, _ in record.get("entities", [])
    ]
    redacted["author_signature"] = ""
    redacted["legal_reference"] = [
        (label, "[REDACTED]") for label, _ in record.get("legal_reference", [])
    ]
    redacted["risk_flags"] = [
        (label, "[REDACTED]") for label, _ in record.get("risk_flags", [])
    ]
    redacted["redacted"] = True
    redacted["redaction"] = {
        "enabled": True,
        "env": env,
        "methods": [
            "spacy_entities",
            "regex_email",
            "regex_phone",
            "regex_ip",
            "regex_ssn",
            "luhn_credit_card"
        ],
        "hash_salt_set": bool(hash_salt),
    }
    return redacted


def attach_insight_sections(
    record: Dict[str, Any],
    content_hash: str,
    trace_context: Dict[str, str]
) -> None:
    tags = record.get("intent_tags", [])
    risk_flags = record.get("risk_flags", [])
    has_idea = "idea" in tags
    has_risk = "riesgo" in tags

    risk_level = "none"
    if has_risk:
        if len(risk_flags) >= 3:
            risk_level = "high"
        elif len(risk_flags) >= 1:
            risk_level = "medium"
        else:
            risk_level = "low"

    record["schema_version"] = trace_context.get("schema_version", "1.0")
    record["cognitive_entities"] = {
        "entities": record.get("entities", []),
        "legal_reference": record.get("legal_reference", []),
        "risk_flags": risk_flags,
    }
    record["idea_analysis"] = {
        "has_idea": has_idea,
        "summary": record.get("idea_summary", ""),
        "tags": tags,
    }
    record["risk_analysis"] = {
        "has_risk": has_risk,
        "flags": risk_flags,
        "level": risk_level,
    }
    record["gitops_trace"] = {
        "run_id": trace_context.get("run_id", ""),
        "generated_at": now_iso(),
        "actor": trace_context.get("actor", "unknown"),
        "env": trace_context.get("env", "dev"),
        "source": {
            "path": record.get("file", ""),
            "sha256": content_hash,
        },
        "git": {
            "commit": trace_context.get("git_commit", ""),
            "ref": trace_context.get("git_ref", ""),
        },
    }


def write_audit_event(event: Dict[str, Any], audit_path: Path) -> None:
    try:
        audit_path.parent.mkdir(parents=True, exist_ok=True)
        with audit_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(event, ensure_ascii=False) + "\n")
    except Exception as e:
        logger.warning("No se pudo escribir auditoría: %s", e)


def load_spacy_model() -> Optional[Any]:
    """Carga un modelo spaCy en español o inglés.

    Intenta cargar `es_core_news_md` porque el proyecto está orientado a
    contenidos en castellano. Si no está disponible, intenta cargar
    `es_core_news_sm`. En última instancia, recurre al modelo
    `en_core_web_sm` que suele estar presente en muchas instalaciones.

    Devuelve `None` si no se puede cargar ningún modelo.
    """
    if should_skip_models():
        logger.warning("COGNITIVE_SKIP_MODELS habilitado; se omite la carga de spaCy.")
        return None

    if spacy is None:
        logger.warning("spaCy no está instalado. La extracción de entidades estará deshabilitada.")
        return None
    
    for model_name in ["es_core_news_md", "es_core_news_sm", "en_core_web_sm"]:
        try:
            logger.debug(f"Intenta cargar: {model_name}")
            model = spacy.load(model_name)
            logger.debug(f"✓ Modelo cargado: {model_name}")
            return model
        except OSError:
            logger.debug(f"Modelo no disponible: {model_name}")
            continue
    
    logger.warning("No se pudo cargar ningún modelo spaCy.")
    return None


def load_sentiment_classifier() -> Optional[Any]:
    """Carga un clasificador de sentimientos multilingüe basado en transformers.

    Intenta cargar un modelo multilingüe que funciona bien con textos en español:
    - `xlm-roberta-base` con fine-tuning para sentimientos (multilingüe, robusto)
    - Si falla, recurre a la heurística que busca palabras clave en español
    
    NOTA: `distilbert-base-uncased-finetuned-sst-2-english` está limitado a inglés.
    Usamos un modelo multilingüe para mejor precisión en textos españoles.
    """
    if should_skip_models():
        logger.warning("COGNITIVE_SKIP_MODELS habilitado; se omite la carga de transformers.")
        return None

    if hf_pipeline is None:
        logger.warning("transformers no está instalado. Se usará clasificación heurística.")
        return None
    try:
        logger.debug("Cargando modelo de sentimientos (transformers)...")
        # Suprimir advertencias de transformers mientras se carga
        import warnings
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            classifier = hf_pipeline(
                "sentiment-analysis",
                model="lxyuan/distilbert-base-multilingual-cased-sentiments-student",
                device=-1  # CPU (cambiar a 0 si hay GPU disponible)
            )
        logger.debug("✓ Modelo de sentimientos cargado")
        return classifier
    except Exception as e:
        logger.warning(f"No se pudo cargar el modelo multilingüe: {e}. Se usará heurística.")
        return None


def heuristic_sentiment(text: str) -> Tuple[str, float]:
    """Clasificador de sentimientos por heurística (principalmente en español).

    Cuenta apariciones de palabras positivas y negativas definidas y
    devuelve una etiqueta y una puntuación entre 0 y 1. Esta función
    sirve como respaldo cuando no se dispone de modelos de Transformer.
    """
    # Palabras clave extendidas para español
    positive_words = {
        "bueno", "excelente", "maravilloso", "positivo", "satisfactorio",
        "bien", "genial", "perfecto", "óptimo", "fantástico", "magnífico",
        "agradable", "hermoso", "beneficio", "éxito", "victoria"
    }
    negative_words = {
        "malo", "terrible", "pésimo", "negativo", "riesgo", "fracaso",
        "mal", "horrible", "desastre", "catastrófico", "problema", "delito",
        "crimen", "peligro", "amenaza", "riesgoso", "perjudicial", "daño",
        "sanción", "castigo", "ilegal", "prohibido", "violación"
    }
    lower = text.lower()
    
    # Contar palabras completas (no subcadenas) para mayor precisión
    pos_count = sum(1 for word in positive_words if f" {word} " in f" {lower} " or f" {word}." in f" {lower} ")
    neg_count = sum(1 for word in negative_words if f" {word} " in f" {lower} " or f" {word}." in f" {lower} ")
    
    total = pos_count + neg_count
    if total == 0:
        return ("NEUTRAL", 0.5)
    
    score = pos_count / total
    label = "POSITIVE" if score >= 0.5 else "NEGATIVE"
    return (label, round(score, 4))


def classify_sentiment(text: str, classifier: Optional[Any]) -> Tuple[str, float]:
    """Determina el sentimiento usando el clasificador de transformers o heurístico.
    
    Si se proporciona un clasificador, lo intenta primero. Si falla o no está disponible,
    recurre a la heurística que busca palabras clave en el texto completo.
    """
    if classifier:
        try:
            # Limitar longitud para reducir carga computacional
            result = classifier(text[:512])
            if result and isinstance(result, list):
                r = result[0]
                label = r.get("label", "NEUTRAL")
                score = float(r.get("score", 0.5))
                
                # Normalizar etiquetas del modelo multilingüe (pueden ser LABEL_0, LABEL_1, etc.)
                if label in {"LABEL_0", "NEGATIVE"}:
                    label = "NEGATIVE"
                elif label in {"LABEL_1", "POSITIVE"}:
                    label = "POSITIVE"
                else:
                    label = "NEUTRAL"
                
                return (label, score)
        except Exception as e:
            logger.debug(f"Error al clasificar sentimiento con transformers: {e}")
    
    # Fallback a heurística que analiza el texto completo
    return heuristic_sentiment(text)


def extract_legal_entities(doc: Optional[Any], text: str) -> List[Tuple[str, str]]:
    """Extrae entidades que son referencias legales basándose en etiquetas y palabras clave.
    
    spaCy en español no tiene etiqueta LAW, así que buscamos MISC/ORG que contengan
    palabras clave legales: "ley", "código", "artículo", "decreto", etc.
    """
    legal_entities: List[Tuple[str, str]] = []
    
    if doc is None:
        return legal_entities
    
    legal_keywords = {
        "ley", "código", "artículo", "decreto", "reglamento", "normativa",
        "regulación", "estatuto", "ordenanza", "resolución", "sentencia",
        "juzgado", "tribunal", "fiscal", "abogado", "delito", "crimen",
        "sanción", "pena", "castigo", "ilegal", "infracción"
    }
    
    try:
        for ent in doc.ents:
            # Si es MISC u ORG, verificar si contiene palabras legales
            if ent.label_ in {"MISC", "ORG", "LOC"}:
                ent_lower = ent.text.lower()
                if any(keyword in ent_lower for keyword in legal_keywords):
                    legal_entities.append(("LEGAL", ent.text))
    except Exception as e:
        logger.debug(f"Error al extraer entidades legales: {e}")
    
    return legal_entities


def extract_entities(doc: Optional[Any]) -> List[Tuple[str, str]]:
    """Extrae entidades nombradas de un doc de spaCy como tuplas (tipo, texto).
    
    Si doc es None, devuelve una lista vacía. Las entidades se devuelven como
    pares (etiqueta, texto).
    """
    entities: List[Tuple[str, str]] = []
    if doc is None:
        return entities
    
    try:
        for ent in doc.ents:
            entities.append((ent.label_, ent.text))
    except Exception as e:
        logger.debug(f"Error al extraer entidades: {e}")
    
    return entities


def generate_cognitive_tags(text: str, doc: Optional[Any]) -> List[str]:
    """Genera etiquetas cognitivas combinando reglas heurísticas y entidades.
    
    Analiza el texto en busca de palabras clave relacionadas con conceptos
    cognitivos: idea, riesgo, legalidad, proyecto, viabilidad, emociones, etc.
    """
    tags: List[str] = []
    lower = text.lower()
    
    # Palabras clave expandidas
    idea_keywords = {"idea", "innovación", "concepto", "teoría", "hipótesis", "propuesta", "pensamiento"}
    risk_keywords = {"riesgo", "amenaza", "peligro", "problema", "delito", "crimen", "ilegalidad", "sanción"}
    legal_keywords = {"legal", "ley", "normativa", "regulación", "jurídico", "artículo", "código", "derecho"}
    project_keywords = {"proyecto", "implementación", "desarrollo", "ejecución", "plan", "programa"}
    viability_keywords = {"viable", "viabilidad", "factible", "realizable", "posible"}
    emotion_keywords = {"feliz", "triste", "emocionado", "enojado", "satisfecho", "preocupado", "esperanzado"}
    intuition_keywords = {"intuición", "presentimiento", "corazonada", "instinto", "sensación"}
    action_keywords = {"pendiente", "por hacer", "tarea", "accionar", "deber", "debe", "necesario"}
    
    # Verificar palabras clave (búsqueda aproximada para mayor cobertura)
    if any(word in lower for word in idea_keywords):
        tags.append("idea")
    if any(word in lower for word in risk_keywords):
        tags.append("riesgo")
    if any(word in lower for word in legal_keywords):
        tags.append("legal")
    if any(word in lower for word in project_keywords):
        tags.append("proyecto")
    if any(word in lower for word in viability_keywords):
        tags.append("viabilidad")
    if any(word in lower for word in emotion_keywords):
        tags.append("emoción")
    if any(word in lower for word in intuition_keywords):
        tags.append("intuición")
    if any(word in lower for word in action_keywords):
        tags.append("acción pendiente")
    
    # Analizar entidades si disponible
    if doc is not None:
        try:
            for ent in doc.ents:
                label = ent.label_
                # Mapeo de entidades a etiquetas
                if label in {"LAW", "NORP"} and "legal" not in tags:
                    tags.append("legal")
                if label in {"PERSON", "ORG"} and "proyecto" not in tags:
                    tags.append("proyecto")
        except Exception as e:
            logger.debug(f"Error al procesar entidades para tags: {e}")
    
    # Si no hay etiquetas, asignar "otros"
    if not tags:
        tags.append("otros")
    
    return tags


def generate_summary(text: str, max_chars: int = 200) -> str:
    """Devuelve un resumen simple de los primeros caracteres del texto."""
    clean = re.sub(r"\s+", " ", text.strip())
    return clean[:max_chars] + ("..." if len(clean) > max_chars else "")


def generate_record(
    file_path: Path,
    nlp_model: Optional[Any],
    sentiment_classifier: Optional[Any],
    redact: bool,
    hash_salt: str,
    env: str,
    trace_context: Dict[str, str]
) -> Dict[str, Any]:
    """Procesa un archivo y devuelve un registro semántico conforme al esquema.
    
    Lee el archivo, aplica análisis de NLP, extrae entidades, clasifica sentimiento
    y genera etiquetas cognitivas.
    """
    try:
        text = file_path.read_text(encoding='utf-8', errors='ignore')
    except Exception as e:
        logger.error(f"Error al leer {file_path}: {e}")
        raise
    
    # Procesar con spaCy si está disponible
    doc = None
    if nlp_model is not None:
        try:
            doc = nlp_model(text)
        except Exception as e:
            logger.warning(f"Error al procesar con spaCy para {file_path}: {e}")
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
    
    # Entidades legales
    legal_entities = extract_legal_entities(doc, text)
    
    # Extraer flags de riesgo (palabras clave de riesgo en el texto)
    risk_keywords = {"riesgo", "delito", "crimen", "peligro", "amenaza", "sanción", "pena", "castigo", "ilegal"}
    risk_flags = [ent for ent in legal_entities if any(kw in ent[1].lower() for kw in risk_keywords)]
    
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
    record["redacted"] = False
    record["redaction"] = {"enabled": False, "env": env}
    
    # Campos adicionales basados en heurísticas
    record["idea_summary"] = record["summary"] if "idea" in tags else ""
    record["risk_flags"] = risk_flags if "riesgo" in tags else []
    record["legal_reference"] = legal_entities if "legal" in tags else []
    
    # Firma de autor: buscar líneas que contengan "autor", "firma", "por", "escrito"
    author = None
    author_patterns = ["autor:", "firma:", "por:", "escrito por", "signed by"]
    for line in text.splitlines():
        line_lower = line.lower()
        if any(pattern in line_lower for pattern in author_patterns):
            # Extraer el texto después del patrón
            for pattern in author_patterns:
                if pattern in line_lower:
                    author = line.split(pattern)[-1].strip()
                    if author and len(author) > 2:
                        break
            if author:
                break
    
    record["author_signature"] = author or ""
    
    # Relevancia mejorada: basada en densidad de entidades + variedad de tags + sentimiento
    entity_density = len(legal_entities) / max(word_count / 1000, 1)  # entidades por 1000 palabras
    tag_diversity = len(set(tags)) / 8  # máximo 8 tags diferentes
    
    # Normalizar: dar más peso a entidades y tags que al tamaño
    relevance = (
        min(0.4, entity_density / 10) +  # Densidad de entidades (0-0.4)
        (tag_diversity * 0.4) +            # Diversidad de tags (0-0.4)
        (0.2 if len(tags) >= 4 else 0.1)  # Bonus por múltiples tags (0-0.2)
    )
    
    record["relevance_score"] = round(min(1.0, relevance), 3)

    hash_source = redact_text(text, doc)
    content_hash = hash_text(hash_source, hash_salt)

    if redact:
        redacted_record = redact_record(record, doc, hash_salt, env)
        attach_insight_sections(redacted_record, content_hash, trace_context)
        return redacted_record

    attach_insight_sections(record, content_hash, trace_context)
    return record


def main() -> None:
    parser = argparse.ArgumentParser(description='Análisis cognitivo avanzado')
    parser.add_argument('--input', default='outputs/raw', help='Directorio con archivos de texto')
    parser.add_argument('--output', default='outputs/insights/analysis.json', help='Archivo JSON de salida')
    parser.add_argument('--schema', default='schemas/insight.schema.json', help='Ruta al esquema de insights')
    parser.add_argument('--verbose', '-v', action='store_true', help='Mostrar logs detallados')
    args = parser.parse_args()

    # Ajustar nivel de logging según flag verbose
    if args.verbose:
        logger.setLevel(logging.DEBUG)
        logging.getLogger("transformers").setLevel(logging.WARNING)
    else:
        logger.setLevel(logging.WARNING)

    env = normalize_env(os.getenv("COGNITIVE_ENV", "dev"))
    force_redact = os.getenv("COGNITIVE_REDACT", "0").strip().lower() in {"1", "true", "yes"}
    redact_enabled = env == "prod" or force_redact
    hash_salt = os.getenv("COGNITIVE_HASH_SALT", "")
    audit_path = Path(os.getenv("COGNITIVE_AUDIT_LOG", "outputs/audit/analysis.jsonl"))
    redaction_mode = "env_prod" if env == "prod" else ("forced" if force_redact else "disabled")

    if env == "prod" and not hash_salt:
        logger.warning("COGNITIVE_HASH_SALT no definido; los IDs se hashearán sin salt.")

    input_dir = Path(args.input)
    output_file = Path(args.output)

    # Validar que el directorio de entrada existe
    if not input_dir.exists():
        logger.error(f"Directorio de entrada no existe: {input_dir}")
        raise FileNotFoundError(f"Directorio no encontrado: {input_dir}")

    # Cargar modelos de PLN
    print("🧠 Inicializando modelos de PLN...")
    nlp_model = load_spacy_model()
    sentiment_classifier = load_sentiment_classifier()

    if redact_enabled:
        print(f"🔒 Redacción habilitada (env={env}, modo={redaction_mode})")

    results: List[Dict[str, Any]] = []
    file_count = 0
    error_count = 0
    error_files: List[str] = []
    run_id = str(uuid.uuid4())
    start_time = time.time()
    actor = os.getenv("USER") or os.getenv("USERNAME") or "unknown"
    git_commit = os.getenv("GIT_COMMIT") or os.getenv("GITHUB_SHA") or ""
    git_ref = os.getenv("GIT_BRANCH") or os.getenv("GITHUB_REF_NAME") or ""
    trace_context = {
        "run_id": run_id,
        "actor": actor,
        "env": env,
        "git_commit": git_commit,
        "git_ref": git_ref,
        "schema_version": "1.0",
    }

    write_audit_event(
        {
            "event": "analysis_start",
            "timestamp": now_iso(),
            "run_id": run_id,
            "actor": actor,
            "env": env,
            "redaction_enabled": redact_enabled,
            "redaction_mode": redaction_mode,
            "input_dir": str(input_dir),
            "output_file": str(output_file),
        },
        audit_path
    )
    
    # Procesar archivos de texto
    print(f"📂 Procesando archivos en {input_dir}...")
    for p in input_dir.rglob('*'):
        if p.is_file() and p.suffix.lower() in {'.txt', '.json', '.md'}:
            try:
                logger.debug(f"Procesando: {p}")
                results.append(
                    generate_record(
                        p,
                        nlp_model,
                        sentiment_classifier,
                        redact_enabled,
                        hash_salt,
                        env,
                        trace_context
                    )
                )
                file_count += 1
                print(f"  ✓ {p.name}")
            except Exception as e:
                logger.error(f"Error procesando {p}: {e}")
                error_count += 1
                if redact_enabled:
                    error_files.append(f"file_{hash_identifier(p.name, hash_salt)}")
                else:
                    error_files.append(p.name)
                print(f"  ✗ {p.name} (error)")
                continue
    
    # Guardar resultados
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with output_file.open('w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    duration_ms = int((time.time() - start_time) * 1000)
    write_audit_event(
        {
            "event": "analysis_end",
            "timestamp": now_iso(),
            "run_id": run_id,
            "actor": actor,
            "env": env,
            "redaction_enabled": redact_enabled,
            "redaction_mode": redaction_mode,
            "file_count": file_count,
            "error_count": error_count,
            "error_files": error_files,
            "duration_ms": duration_ms,
            "output_file": str(output_file),
        },
        audit_path
    )
    
    # Resumen final
    print("\n" + "="*60)
    print(f"✅ Análisis completado")
    print(f"   📊 Archivos procesados: {file_count}")
    if error_count > 0:
        print(f"   ⚠️  Errores: {error_count}")
    print(f"   💾 Resultados: {output_file.absolute()}")
    print("="*60)


if __name__ == '__main__':
    main()
