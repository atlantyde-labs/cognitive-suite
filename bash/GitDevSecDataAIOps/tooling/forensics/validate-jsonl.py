#!/usr/bin/env python3
import argparse
import json
import sys

try:
    import jsonschema  # type: ignore
except Exception as exc:  # pragma: no cover
    print(f"[validate-jsonl] ERROR: jsonschema not available: {exc}", file=sys.stderr)
    sys.exit(1)


def load_schema(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def iter_lines(path: str):
    with open(path, "r", encoding="utf-8") as fh:
        for idx, line in enumerate(fh, start=1):
            line = line.strip()
            if not line:
                continue
            yield idx, line


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate JSONL against JSON Schema.")
    parser.add_argument("--schema", required=True, help="Path to JSON schema")
    parser.add_argument("--input", required=True, help="Path to JSONL file")
    args = parser.parse_args()

    schema = load_schema(args.schema)
    validator = jsonschema.Draft202012Validator(schema)

    errors = []
    total = 0
    for idx, line in iter_lines(args.input):
        total += 1
        try:
            payload = json.loads(line)
        except json.JSONDecodeError as exc:
            errors.append((idx, f"JSON decode error: {exc}"))
            continue
        for err in validator.iter_errors(payload):
            errors.append((idx, err.message))

    if errors:
        print(f"[validate-jsonl] FAIL: {len(errors)} errors across {total} lines", file=sys.stderr)
        for idx, msg in errors[:50]:
            print(f"[line {idx}] {msg}", file=sys.stderr)
        if len(errors) > 50:
            print(f"... truncated {len(errors) - 50} errors", file=sys.stderr)
        return 1

    print(f"[validate-jsonl] OK: {total} lines validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
