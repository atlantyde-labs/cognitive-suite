#!/env python3
# -*- coding: utf-8 -*-
"""
Validator for Lab 03: Bootstrap Dashboard.
Checks if the user has customized the strealit app with their own widgets.
"""

import sys
from pathlib import Path

# Fix for Windows terminal encoding issues with emojis
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def verify():
    dashboard_file = Path("frontend/streamlit_app.py")
    insights_file = Path("outputs/insights/analysis.json")

    if not dashboard_file.exists():
        return False, "Evidencia ausente: No se encontró frontend/streamlit_app.py."

    if not insights_file.exists():
        return False, "Evidencia ausente: No hay datos para visualizar (análisis ausente)."

    # Check for customization (Paso 4)
    content = dashboard_file.read_text(encoding="utf-8")

    # Markers that indicate the user followed Lab 03 instructions
    custom_markers = [
        "st.metric(",
        "Mi Métrica Custom",
        "🎯"
    ]

    if any(marker in content for marker in custom_markers):
        return True, "Éxito: Personalización del Dashboard detectada. ¡Misión Lab 03 completada! 🎉"

    return False, "Fallo técnico: No se encontraron personalizaciones en el Dashboard. ¿Has completado el Paso 4 de la misión?"

if __name__ == "__main__":
    success, message = verify()
    print(message)
    sys.exit(0 if success else 1)
