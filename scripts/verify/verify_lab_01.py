#!/env python3
# -*- coding: utf-8 -*-
"""
Validator for Lab 01: Deep Dive.
Checks if the security pipeline was correctly executed with redaction enabled.
"""

import json
import sys
from pathlib import Path

# Fix for Windows terminal encoding issues
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def verify():
    insights_file = Path("outputs/insights/analysis.json")
    analysis_file = Path("outputs/insights/analysis.json")
    audit_file = Path("outputs/audit/analysis.jsonl")

    if not analysis_file.exists():
        return False, "Evidencia ausente: No se encontró el archivo analysis.json. Ejecuta el pipeline primero."

    try:
        data = json.loads(analysis_file.read_text(encoding="utf-8"))
        if not data:
            return False, "Evidencia inválida: El archivo de análisis está vacío."

        # Check for redaction (Lab 01 core requirement)
        v = any(rec.get("redacted") for rec in data)
        if v:
            count = sum(1 for rec in data if rec.get("redacted"))
            # Audit trail check (optional but recommended for Phase 2)
            if not audit_file.exists():
                return False, "Fallo de auditoría: No se encontró outputs/audit/analysis.jsonl. La misión requiere un registro de auditoría."
            return True, f"Éxito: {count} registros verificados con redacción segura."
        else:
            return False, "Fallo técnico: No se detectó redacción de datos sensibles. Revisa el Paso 3 del Lab 01."

    except Exception as e:
        return False, f"Error de análisis: {str(e)}"

if __name__ == "__main__":
    success, message = verify()
    print(message)
    sys.exit(0 if success else 1)
