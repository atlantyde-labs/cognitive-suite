#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scripts/validate_gitops.py
--------------------------

Script multiplataforma para validar que no se suben datos sensibles
al repositorio durante el flujo GitOps.
Analiza el "stage" de Git en busca de patrones sensibles.
"""

import subprocess
import sys
import re

def main():
    print("🔍 Validando datos antes de GitOps sync...")

    try:
        # Obtener el diff de los archivos preparados (staged)
        result = subprocess.run(
            ["git", "diff", "--cached"],
            capture_output=True,
            text=True,
            check=True
        )
    except subprocess.CalledProcessError as e:
        print(f"❌ Error al ejecutar Git: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print("❌ Error: Git no se encuentra instalado o no está en el PATH.")
        sys.exit(1)

    diff_text = result.stdout

    # Filtrar solo las líneas añadidas (que empiezan con '+') para no validar lo que se borra
    added_lines = "\n".join([line[1:] for line in diff_text.splitlines() if line.startswith("+") and not line.startswith("+++")])

    # Patrones prohibidos (sensibles) que no deberían estar en el diff
    # Buscamos patrones que indiquen datos no redactados
    forbidden_patterns = [
        (r'("PERSON"|PER):\s*"[^\[]', "Nombres reales detectados en campos PER/PERSON"),
        (r'(Nombre y apellidos|Trabajador|Persona):\s*(?!\[REDACTED)[^",\n]+', "Nombres reales detectados en el texto (sin redactar)"),
        (r'("EMAIL"|EMAIL):\s*"[^\[]', "Emails detectados (sin redactar)"),
        (r'\b[ABCDEFGHJKLMNPQRSUVW][0-9]{7}[0-9A-JA-J]\b', "CIF detectado"),
        (r'\b[0-9]{8}[TRWAGMYFPDXBNJZSQVHLCKE]\b', "DNI detectado"),
        (r'("password"|"secret"|"token"):\s*"[^"]+"', "Posible secreto o token detectado")
    ]

    found_issues = []

    for pattern, description in forbidden_patterns:
        if re.search(pattern, added_lines, re.IGNORECASE):
            found_issues.append(description)

    if found_issues:
        print("\n❌ ALERTA: Datos sensibles detectados en staged files!")
        for issue in found_issues:
            print(f"   - {issue}")
        print("\n🚫 El push ha sido bloqueado por seguridad.")
        print("💡 Consejo: Asegúrate de haber ejecutado 'python pipeline/redact.py' y")
        print("   de haber añadido el archivo correcto con 'git add -f outputs/insights/analysis.json'")
        sys.exit(1)

    print("✅ Validación pasada. El contenido parece seguro para push.")

if __name__ == "__main__":
    main()
