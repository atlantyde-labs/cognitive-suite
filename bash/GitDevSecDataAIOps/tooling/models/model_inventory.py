#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import re
import shutil
from pathlib import Path
from typing import Dict, List

MODEL_FILES = {
    "pytorch_model.bin",
    "model.safetensors",
    "model.bin",
    "ggml-model-f16.bin",
    "ggml-model-q4_0.bin",
    "gguf",
}
ADAPTER_FILES = {
    "adapter_model.bin",
    "adapter_model.safetensors",
    "adapter_config.json",
}
TOKENIZER_FILES = {
    "tokenizer.json",
    "tokenizer.model",
    "vocab.json",
    "merges.txt",
    "special_tokens_map.json",
}
TRAINING_FILES = {
    "trainer_state.json",
    "training_args.bin",
    "rng_state.pth",
}
CONFIG_FILES = {"config.json"}

VECTOR_EXTS = {".faiss", ".index", ".hnsw", ".ivf", ".ann", ".scann"}
VECTOR_FILES = {"chroma.sqlite3"}
VECTOR_DIRS = {"qdrant_storage", "chroma", "lancedb", "milvus"}

CHECKPOINT_RE = re.compile(r"checkpoint-\d+")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def detect_kind(path: Path) -> str:
    name = path.name
    if name in MODEL_FILES:
        return "model_weight"
    if name in ADAPTER_FILES:
        return "adapter"
    if name in TOKENIZER_FILES:
        return "tokenizer"
    if name in TRAINING_FILES:
        return "training_metadata"
    if name in CONFIG_FILES:
        return "config"
    if name in VECTOR_FILES or path.suffix in VECTOR_EXTS:
        return "vector_index"
    return "file"


def detect_origin(path: Path) -> str:
    for part in path.parts:
        if CHECKPOINT_RE.fullmatch(part):
            return "fine_tune"
    parent = path.parent
    if any((parent / f).exists() for f in TRAINING_FILES):
        return "fine_tune"
    return "unknown"


def detect_map(path: Path) -> bool:
    if path.name in VECTOR_FILES or path.suffix in VECTOR_EXTS:
        return True
    if any(part in VECTOR_DIRS for part in path.parts):
        return True
    return False


def classify_sensitivity(kind: str, origin: str, default: str) -> str:
    if kind == "vector_index":
        return "SECRET"
    if origin == "fine_tune":
        return "SECRET"
    return default


def is_under(path: Path, roots: List[Path]) -> bool:
    for root in roots:
        try:
            path.relative_to(root)
            return True
        except ValueError:
            continue
    return False


def collect_artifacts(roots: List[Path], hash_mode: str, default_sensitivity: str) -> List[Dict]:
    artifacts = []
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if path.is_dir():
                if path.name in VECTOR_DIRS:
                    artifacts.append({
                        "path": str(path),
                        "kind": "vector_store",
                        "origin": "unknown",
                        "sensitivity": "SECRET",
                        "size_bytes": 0,
                    })
                continue
            kind = detect_kind(path)
            origin = detect_origin(path)
            sensitivity = classify_sensitivity(kind, origin, default_sensitivity)
            if detect_map(path):
                kind = "vector_index"
                sensitivity = "SECRET"

            entry = {
                "path": str(path),
                "kind": kind,
                "origin": origin,
                "sensitivity": sensitivity,
                "size_bytes": path.stat().st_size,
            }
            if hash_mode == "sha256":
                entry["sha256"] = sha256_file(path)
            artifacts.append(entry)
    return artifacts


def move_or_copy(src: Path, dest_dir: Path, mode: str, dry_run: bool) -> str:
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / src.name
    if dry_run:
        return f"dry-run:{mode}:{dest}"
    if mode == "move":
        shutil.move(str(src), str(dest))
        return f"moved:{dest}"
    if mode == "copy":
        shutil.copy2(str(src), str(dest))
        return f"copied:{dest}"
    return "skipped"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--roots", default=".", help="Comma-separated roots to scan")
    parser.add_argument("--output", default="outputs/model-inventory.json")
    parser.add_argument("--hash", choices=["none", "sha256"], default="none")
    parser.add_argument("--default-sensitivity", default="INTERNAL")
    parser.add_argument("--allowed-secret-roots", default="", help="Comma-separated roots allowed for SECRET artifacts")
    parser.add_argument("--quarantine-mode", choices=["none", "copy", "move"], default="none")
    parser.add_argument("--vault-dir", default="", help="Target directory for quarantine")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--alerts-output", default="outputs/model-alerts.json")
    parser.add_argument("--fail-on-violation", action="store_true")
    args = parser.parse_args()

    roots = [Path(p.strip()) for p in args.roots.split(",") if p.strip()]
    allowed_secret_roots = [Path(p.strip()) for p in args.allowed_secret_roots.split(",") if p.strip()]

    artifacts = collect_artifacts(roots, args.hash, args.default_sensitivity.upper())

    violations = []
    actions = []

    for item in artifacts:
        path = Path(item["path"])
        if item["sensitivity"] != "SECRET":
            continue
        if allowed_secret_roots and not is_under(path, allowed_secret_roots):
            violations.append({
                "path": item["path"],
                "reason": "SECRET artifact outside allowed roots",
            })
            if args.quarantine_mode != "none" and args.vault_dir:
                action = move_or_copy(path, Path(args.vault_dir), args.quarantine_mode, args.dry_run)
                actions.append({
                    "path": item["path"],
                    "action": action,
                })

    summary = {}
    for item in artifacts:
        key = f"{item['kind']}:{item['sensitivity']}"
        summary[key] = summary.get(key, 0) + 1

    payload = {
        "generated_at": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "roots": [str(r) for r in roots],
        "summary": summary,
        "artifacts": artifacts,
    }

    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=True, indent=2)

    alerts = {
        "generated_at": payload["generated_at"],
        "violations": violations,
        "actions": actions,
    }
    os.makedirs(os.path.dirname(args.alerts_output) or ".", exist_ok=True)
    with open(args.alerts_output, "w", encoding="utf-8") as fh:
        json.dump(alerts, fh, ensure_ascii=True, indent=2)

    print(f"Inventory written to {args.output} ({len(artifacts)} items)")
    print(f"Alerts written to {args.alerts_output} ({len(violations)} violations)")

    if args.fail_on_violation and violations:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
