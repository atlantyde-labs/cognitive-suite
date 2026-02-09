#!/env python3
# -*- coding: utf-8 -*-
"""
Validator for Lab 02: GitOps Steward.
Checks if the pipeline was executed in 'prod' mode with hashing and salt.
"""

import json
import os
import sys
from pathlib import Path

# Fix for Windows terminal encoding issues
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def verify():
    insights_file = Path("outputs/insights/analysis.json")

    if not insights_file.exists():
        return False, "Evidence missing: outputs/insights/analysis.json not found."

    try:
        with open(insights_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        return False, f"Error reading evidence: {e}"

    if not data:
        return False, "Evidence empty."

    # Lab 02 specific checks
    for record in data:
        redaction = record.get("redaction", {})
        if redaction.get("env") != "prod":
            return False, f"Desajuste de entorno: Se esperaba 'prod', se encontró '{redaction.get('env')}'. Las misiones en el Laboratorio 02 deben estar listas para producción."

        if not redaction.get("enabled"):
            return False, "Fallo de seguridad: La redacción debe estar habilitada en el Laboratorio 02."

        if not redaction.get("hash_salt_set"):
            return False, "Fallo de privacidad: COGNITIVE_HASH_SALT debe configurarse para garantizar IDs irreversibles."

    # The instruction provided a snippet that seems to replace the final success message
    # and also introduces new logic related to COGNITIVE_ENV.
    # I will interpret this as replacing the final success message and adding the new env check.
    # The new env check seems to be a general check, not tied to a specific record in the loop.
    # I will place it before the final success message.

    # Simulación simple: verificar si COGNITIVE_ENV es 'prod'
    env = os.getenv("COGNITIVE_ENV", "dev").lower()

    if env not in ["prod", "production"]:
        return False, "Fallo operacional: El entorno no está en modo PRODUCCIÓN (COGNITIVE_ENV != 'prod')."

    # Podríamos verificar si hay un log de auditoría reciente
    return True, "Éxito: Modo PRODUCCIÓN de GitOps verificado correctamente. Los datos están seguros para la sincronización de GitOps."


if __name__ == "__main__":
    success, message = verify()
    print(message)
    sys.exit(0 if success else 1)
