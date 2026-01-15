#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
frontend/tui.py
---------------

Interfaz de usuario basada en terminal utilizando Rich. Permite
visualizar los resultados del análisis cognitivo en modo texto, con
opciones para filtrar por etiquetas y mostrar detalles de un registro
seleccionado. Esta TUI no es interactiva en tiempo real como Textual,
pero proporciona una experiencia amigable en la consola.

Uso:

```
python frontend/tui.py
```
"""

import json
from pathlib import Path
from typing import List, Dict, Any

from rich.console import Console
from rich.table import Table


def load_data(path: Path) -> List[Dict[str, Any]]:
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []


def display_table(data: List[Dict[str, Any]], console: Console, tags_filter: List[str]) -> None:
    table = Table(title="Resultados del análisis cognitivo")
    table.add_column("#", justify="right", style="cyan")
    table.add_column("UUID", style="magenta")
    table.add_column("Archivo", style="green")
    table.add_column("Etiquetas", style="yellow")
    table.add_column("Sentimiento", style="blue")
    table.add_column("Relevancia", style="red")
    for idx, rec in enumerate(data, 1):
        tags = rec.get("intent_tags", [])
        if tags_filter and not any(t in tags for t in tags_filter):
            continue
        table.add_row(
            str(idx),
            rec.get("uuid", ""),
            Path(rec.get("file", "")).name,
            ", ".join(tags),
            rec.get("sentiment", {}).get("label", ""),
            str(rec.get("relevance_score", "")),
        )
    console.print(table)


def main() -> None:
    console = Console()
    analysis_path = Path("outputs/insights/analysis.json")
    data = load_data(analysis_path)
    if not data:
        console.print("[bold red]⚠️  No se encontró el archivo de análisis. Ejecuta primero el pipeline.")
        return
    # Mostrar etiquetas disponibles
    all_tags = sorted({tag for rec in data for tag in rec.get("intent_tags", [])})
    console.print("Etiquetas disponibles: " + ", ".join(all_tags))
    console.print("Ingrese etiquetas separadas por coma para filtrar (o presione Enter para todas):")
    tags_input = input("> ").strip()
    tags_filter: List[str] = []
    if tags_input:
        tags_filter = [t.strip() for t in tags_input.split(",") if t.strip() in all_tags]
    console.clear()
    display_table(data, console, tags_filter)
    console.print("\nSeleccione el número de un registro para ver detalles, o presione Enter para salir:")
    selection = input("> ").strip()
    if not selection:
        return
    try:
        idx = int(selection) - 1
    except ValueError:
        console.print("Entrada no válida.")
        return
    if 0 <= idx < len(data):
        rec = data[idx]
        console.print(f"\n[bold]{rec.get('title')}[/bold] ({rec.get('uuid')})")
        console.print(f"Archivo: {rec.get('file')}")
        console.print(f"Tipo: {rec.get('content_type')}")
        console.print(f"Etiquetas: {', '.join(rec.get('intent_tags', []))}")
        sentiment = rec.get('sentiment', {})
        console.print(f"Sentimiento: {sentiment.get('label')} (score {sentiment.get('score')})")
        console.print(f"Resumen: {rec.get('summary')}")
        if rec.get('entities'):
            console.print("Entidades:")
            ent_table = Table(show_header=True, header_style="bold blue")
            ent_table.add_column("Tipo")
            ent_table.add_column("Texto")
            for ent in rec['entities']:
                ent_table.add_row(ent[0], ent[1])
            console.print(ent_table)
        if rec.get('author_signature'):
            console.print(f"Firma de autor: {rec.get('author_signature')}")
        console.print(f"Relevancia: {rec.get('relevance_score')}")
    else:
        console.print("Número fuera de rango.")


if __name__ == '__main__':
    main()
