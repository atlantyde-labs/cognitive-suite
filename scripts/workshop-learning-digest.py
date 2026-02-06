#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
from typing import Any, Iterable, List, Mapping, Optional

from wrappers.open_notebook_wrapper import OpenNotebookClient


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Genera digests microlearning y llama a Open Notebook después del split."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=Path("scripts/repo-visibility-plan.json"),
        help="Ruta al plan JSON de visibilidad.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("outputs/workshop-digests"),
        help="Carpeta donde se guardan los digests y las respuestas de Open Notebook.",
    )
    parser.add_argument(
        "--notes-file",
        type=Path,
        default=Path("docs/internal/workshop-notes.md"),
        help="Archivo colaborativo donde se documentan observaciones cognitivas y emocionales.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Marca si la ejecución previa fue en modo dry-run.",
    )
    parser.add_argument(
        "--open-notebook-api-url",
        type=str,
        default=os.environ.get("OPEN_NOTEBOOK_API_URL", ""),
        help="URL base del API de Open Notebook.",
    )
    parser.add_argument(
        "--open-notebook-notebook-id",
        type=str,
        default=os.environ.get("OPEN_NOTEBOOK_NOTEBOOK_ID", ""),
        help="Notebook destino para guardar los digests.",
    )
    parser.add_argument(
        "--open-notebook-api-key",
        type=str,
        default=os.environ.get("OPEN_NOTEBOOK_API_KEY", ""),
        help="Clave opcional para autenticar contra Open Notebook.",
    )
    return parser.parse_args()


def load_plan(config_path: Path) -> Mapping[str, Any]:
    with config_path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def format_paths(paths: Iterable[str], exclude: Iterable[str]) -> str:
    include_text = ", ".join(paths) or "ninguna ruta explícita"
    exclude_text = ", ".join(exclude) or "sin exclusiones"
    return f"Incluir ({include_text}); Excluir ({exclude_text})"


def build_digest_block(target: Mapping[str, Any], run_mode: bool) -> str:
    visibility = target.get("visibility", "desconocida")
    description = target.get("description", "").strip()
    return (
        f"### {target['id']} · {target.get('name', 'sin nombre')}\n"
        f"- Visibilidad prevista: **{visibility}**\n"
        f"- Descripción: {description}\n"
        f"- Plataformas: {', '.join(target.get('platforms', ['github', 'gitea']))}\n"
        f"- Rutas: {format_paths(target.get('paths', []), target.get('exclude', []))}\n"
        f"- Modo de ejecución: {'dry-run' if run_mode else 'run'}\n"
        f"- Mensaje sugerido: {target.get('commit_message', 'split automático')}\n\n"
        f"- Observaciones cognitivas (completar durante la sesión):\n"
        f"  - \n"
        f"- Estado emocional y energía:\n"
        f"  - \n\n"
    )


def ensure_path(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def append_notes(notes_file: Path, entries: List[str], run_mode: bool) -> None:
    ensure_path(notes_file)
    header = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
    mode_text = "dry-run" if run_mode else "run"
    with notes_file.open("a", encoding="utf-8") as fh:
        fh.write(f"\n## Registro de workshop · {header} · {mode_text}\n")
        for entry in entries:
            fh.write(entry)
        fh.write("\n")


def build_prompt_text(target: Mapping[str, Any]) -> str:
    return (
        f"Resumir brevemente y generar un quiz para el target '{target['id']}' "
        f"({target.get('name', '')}). Descripción: {target.get('description', '')}. "
        f"Visibilidad: {target.get('visibility', 'desconocida')}. "
        f"Paths considerados: {', '.join(target.get('paths', [])) or 'ninguno explícito'}. "
        f"Exclusiones: {', '.join(target.get('exclude', [])) or 'ninguno'}. "
        "Proporcione un resumen adaptativo y 3 preguntas de seguimiento con opciones."
    )


def call_open_notebook(client: OpenNotebookClient, notebook_id: str, prompt_text: str) -> Optional[str]:
    return client.chat(
        notebook_id=notebook_id,
        context_ids=[],
        message=prompt_text,
    )


def compute_hash(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def append_audit_log(digest_path: Path, entries: List[Mapping[str, str]]) -> None:
    if not entries:
        return
    with digest_path.open("a", encoding="utf-8") as fh:
        fh.write("\n## Registro de auditoría Codex→Gitea\n")
        for entry in entries:
            fh.write(
                f"- {entry['target_id']}: prompt_hash={entry['prompt_hash']} "
                f"response_hash={entry['response_hash'] or '<vacío>'}\n"
            )


def main() -> None:
    args = parse_args()
    plan = load_plan(args.config)
    targets = plan.get("targets", [])
    if not targets:
        raise SystemExit("El plan no contiene targets para procesar.")

    timestamp = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    digest_dir = args.output_dir / timestamp
    digest_dir.mkdir(parents=True, exist_ok=True)

    run_mode = args.dry_run

    digest_path = digest_dir / "digest.md"
    with digest_path.open("w", encoding="utf-8") as digest_file:
        digest_file.write(f"# Digest microlearning · {timestamp}\n\n")
        digest_entries: List[str] = []
        for target in targets:
            entry = build_digest_block(target, run_mode)
            digest_file.write(entry)
            digest_entries.append(entry)

    append_notes(args.notes_file, digest_entries, run_mode)

    client: Optional[OpenNotebookClient] = None
    if args.open_notebook_api_url and args.open_notebook_notebook_id:
        client = OpenNotebookClient(
            api_url=args.open_notebook_api_url, api_key=args.open_notebook_api_key or None
        )
    else:
        print(
            "Open Notebook no configurado (faltan api_url o notebook_id); "
            "se omite la generación de resumen/quiz."
        )

    audit_entries: List[Mapping[str, str]] = []
    if client:
        for target in targets:
            prompt_text = build_prompt_text(target)
            response = call_open_notebook(
                client=client,
                notebook_id=args.open_notebook_notebook_id,
                prompt_text=prompt_text,
            )
            response_hash = ""
            if response:
                response_path = digest_dir / f"{target['id']}-notebook-response.txt"
                response_path.write_text(response, encoding="utf-8")
                response_hash = compute_hash(response)
            audit_entries.append(
                {
                    "target_id": target["id"],
                    "prompt_hash": compute_hash(prompt_text),
                    "response_hash": response_hash,
                }
            )

    append_audit_log(digest_path, audit_entries)

    print(f"Digest generado en {digest_dir}")


if __name__ == "__main__":
    main()
