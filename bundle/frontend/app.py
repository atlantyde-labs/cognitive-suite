#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
frontend/app.py
----------------

Una interfaz muy sencilla para visualizar los resultados del análisis
cognitivo. En lugar de depender de Streamlit u otras bibliotecas no
disponibles en esta sandbox, esta aplicación imprime los resultados en la
consola. En un futuro se puede reemplazar por una interfaz de usuario
basada en Streamlit, Flask o cualquier framework web.

Para ejecutar manualmente:

```
python frontend/app.py
```
"""

import json
from pathlib import Path


def main() -> None:
    analysis_file = Path('outputs/insights/analysis.json')
    if not analysis_file.exists():
        print('⚠️  No se encontró el archivo de análisis. Ejecuta primero el comando de análisis.')
        return
    data = json.loads(analysis_file.read_text(encoding='utf-8'))
    print('📊 Resultados del análisis cognitivo:')
    for report in data:
        print(f"\n📄 Archivo: {report.get('file')}")
        print(f"   Palabras: {report.get('word_count')}")
        print(f"   Caracteres: {report.get('char_count')}")
        print(f"   Etiquetas: {', '.join(report.get('intent_tags', []))}")
        print(f"   Sentimiento: {report.get('sentiment', {}).get('label')}")


if __name__ == '__main__':
    main()