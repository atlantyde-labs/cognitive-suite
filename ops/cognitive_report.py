#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Reporte cognitivo legal dirigido a compliance."""
from __future__ import annotations

import argparse
import datetime
import json
import math
from dataclasses import dataclass, asdict
from typing import List, Optional

DOMAIN_HINTS = {
    "legal": ["contrato", "cláusula", "norma", "reglamento", "jurídico"],
    "compliance": ["audit", "control", "riesgo", "política"],
    "social": ["comunidad", "impacto", "ética"],
}

@dataclass
class CognitiveAssessment:
    text: str
    domain: str
    context: Optional[str]
    timestamp: str
    confidence: float
    interpretation: str
    judgment: str
    knowledge_trace: List[str]
    recommendation: str


def detect_domain(text: str, preferred: Optional[str]) -> str:
    if preferred:
        return preferred
    lowered = text.lower()
    for domain, keywords in DOMAIN_HINTS.items():
        if any(keyword in lowered for keyword in keywords):
            return domain
    return "legal"


def compose_interpretation(domain: str, context: Optional[str]) -> str:
    fragments = [f"Contexto: {context}" if context else "Contexto pendiente"]
    if domain == "legal":
        fragments.append("Interpretación hermenéutica basada en cláusulas normativas.")
    elif domain == "compliance":
        fragments.append("Verificación de controles y política interna.")
    else:
        fragments.append("Lectura contextual desde óptica social y ética.")
    return " ".join(fragments)


def compose_judgment(domain: str) -> str:
    mapping = {
        "legal": "La disposición parece alinearse con el marco jurídico vigente.",
        "compliance": "Se detecta un control débil; recomendamos evidencia adicional.",
        "social": "El impacto social requiere validación con stakeholders.",
    }
    return mapping.get(domain, mapping["legal"])


def measure_confidence(text: str) -> float:
    tokens = text.split()
    length_score = min(len(tokens) / 200, 1.0)
    keyword_hits = sum(1 for keyword in DOMAIN_HINTS.get("legal", []) if keyword in text.lower())
    return round(0.45 + 0.1 * length_score + 0.05 * math.log1p(keyword_hits), 3)


def knowledge_trace(text: str, domain: str, context: Optional[str]) -> List[str]:
    items = [f"Dominio detectado: {domain}"]
    if context:
        items.append(f"Dominio contextual: {context}")
    items.append(f"Tokens: {len(text.split())}")
    return items


def build_assessment(text: str, domain: str, context: Optional[str]) -> CognitiveAssessment:
    chosen_domain = detect_domain(text, domain)
    interpretation = compose_interpretation(chosen_domain, context)
    judgment = compose_judgment(chosen_domain)
    confidence = measure_confidence(text)
    trace = knowledge_trace(text, chosen_domain, context)
    recommendation = (
        "Documenta referencias legales y adjunta artefactos adjuntos para la auditoría."
        if chosen_domain in ("legal", "compliance")
        else "Solicita validación cruzada con expertos del dominio."
    )
    return CognitiveAssessment(
        text=text,
        domain=chosen_domain,
        context=context,
        timestamp=datetime.datetime.utcnow().isoformat() + "Z",
        confidence=confidence,
        interpretation=interpretation,
        judgment=judgment,
        knowledge_trace=trace,
        recommendation=recommendation,
    )


def parse() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--text", required=True, help="Texto legal o de compliance")
    parser.add_argument("--domain", choices=list(DOMAIN_HINTS.keys()), help="Dominio esperado")
    parser.add_argument("--context", help="Contexto adicional")
    parser.add_argument("--out", help="Archivo JSON de salida", required=False)
    return parser.parse_args()


def main() -> None:
    args = parse()
    assessment = build_assessment(args.text, args.domain or "legal", args.context)
    payload = asdict(assessment)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, ensure_ascii=False, indent=2)
        print(f"Reporte escrito en {args.out}")
    else:
        print(json.dumps(payload, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
