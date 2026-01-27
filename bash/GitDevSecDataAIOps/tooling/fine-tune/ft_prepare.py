#!/usr/bin/env python3
import argparse
import json
import os
import sys
from typing import Dict, Any, Iterable


def iter_jsonl(path: str) -> Iterable[Dict[str, Any]]:
    with open(path, "r", encoding="utf-8") as fh:
        for idx, line in enumerate(fh, 1):
            line = line.strip()
            if not line:
                continue
            try:
                yield idx, json.loads(line)
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid JSON on line {idx}: {exc}") from exc


def validate_obj(idx: int, obj: Dict[str, Any]) -> None:
    if "messages" in obj:
        msgs = obj["messages"]
        if not isinstance(msgs, list):
            raise ValueError(f"Line {idx}: messages must be list")
        for m in msgs:
            if not isinstance(m, dict):
                raise ValueError(f"Line {idx}: message is not object")
            if "role" not in m or "content" not in m:
                raise ValueError(f"Line {idx}: message missing role/content")
            if not isinstance(m["role"], str) or not isinstance(m["content"], str):
                raise ValueError(f"Line {idx}: role/content must be strings")
    elif "prompt" in obj and "completion" in obj:
        if not isinstance(obj["prompt"], str) or not isinstance(obj["completion"], str):
            raise ValueError(f"Line {idx}: prompt/completion must be strings")
    else:
        raise ValueError(f"Line {idx}: expected messages or prompt/completion")


def to_prompt_completion(obj: Dict[str, Any]) -> Dict[str, str]:
    if "prompt" in obj and "completion" in obj:
        return {"prompt": obj["prompt"], "completion": obj["completion"]}

    msgs = obj["messages"]
    if not msgs:
        raise ValueError("messages empty")
    if msgs[-1].get("role") != "assistant":
        raise ValueError("last message must be assistant")

    parts = []
    for m in msgs[:-1]:
        role = m.get("role", "").upper()
        content = m.get("content", "")
        parts.append(f"{role}: {content}")
    prompt = "\n".join(parts) + "\nASSISTANT:"
    completion = msgs[-1]["content"]
    return {"prompt": prompt, "completion": completion}


def split_sensitivity(obj: Dict[str, Any]) -> str:
    meta = obj.get("metadata") or {}
    if not isinstance(meta, dict):
        return "UNKNOWN"
    value = meta.get("sensitivity")
    if not value:
        return "UNKNOWN"
    return str(value).upper()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Input JSONL")
    parser.add_argument("--out-dir", default=".")
    parser.add_argument("--validate-only", action="store_true")
    parser.add_argument("--to-prompt", action="store_true", help="Convert to prompt/completion")
    parser.add_argument("--split-by-sensitivity", action="store_true")
    args = parser.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)

    outputs = {}
    total = 0
    try:
        for idx, obj in iter_jsonl(args.input):
            validate_obj(idx, obj)
            total += 1
            if args.validate_only:
                continue

            out_obj = obj
            if args.to_prompt:
                out_obj = to_prompt_completion(obj)

            if args.split_by_sensitivity:
                key = split_sensitivity(obj)
                out_path = os.path.join(args.out_dir, f"{os.path.basename(args.input)}.{key}.jsonl")
            else:
                out_path = os.path.join(args.out_dir, os.path.basename(args.input))

            if out_path not in outputs:
                outputs[out_path] = open(out_path, "w", encoding="utf-8")
            outputs[out_path].write(json.dumps(out_obj, ensure_ascii=True) + "\n")
    finally:
        for fh in outputs.values():
            fh.close()

    print(f"Validated {total} records")
    return 0


if __name__ == "__main__":
    sys.exit(main())
