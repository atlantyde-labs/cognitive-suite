#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import sys
from pathlib import Path

import yaml
from jsonschema import RefResolver

try:
    from jsonschema import Draft202012Validator as SchemaValidator
except ImportError:
    from jsonschema import Draft7Validator as SchemaValidator


ROOT = Path(__file__).resolve().parent.parent
KNOWLEDGE_DIR = ROOT / "knowledge"
SCHEMAS_DIR = KNOWLEDGE_DIR / "schemas"
DATASETS_DIR = KNOWLEDGE_DIR / "datasets"
INSIGHT_SCHEMA = ROOT / "schemas" / "insight.schema.json"
INSIGHT_SAMPLE = ROOT / "datasets" / "insight_example.json"


def rewrite_refs(value, base_uri: str):
    if isinstance(value, dict):
        rewritten = {}
        for key, item in value.items():
            if key == "$ref" and isinstance(item, str):
                if item.startswith("#") or "://" in item or item.startswith("urn:"):
                    rewritten[key] = item
                else:
                    rewritten[key] = f"{base_uri}/{item}"
            else:
                rewritten[key] = rewrite_refs(item, base_uri)
        return rewritten
    if isinstance(value, list):
        return [rewrite_refs(item, base_uri) for item in value]
    return value


def build_schema_store() -> dict:
    store = {}
    for schema_path in SCHEMAS_DIR.glob("*.schema.json"):
        base_uri = schema_path.parent.as_uri()
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        rewritten = rewrite_refs(schema, base_uri)
        store[schema_path.as_uri()] = rewritten
        store[schema_path.name] = rewritten
        schema_id = schema.get("$id")
        if schema_id:
            store[schema_id] = rewritten
    return store


SCHEMA_STORE = build_schema_store()


def load_schema(schema_path: Path) -> SchemaValidator:
    schema = SCHEMA_STORE.get(schema_path.as_uri())
    if schema is None:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        schema = rewrite_refs(schema, schema_path.parent.as_uri())
    resolver = RefResolver(base_uri=schema_path.as_uri(), referrer=schema, store=SCHEMA_STORE)
    return SchemaValidator(schema, resolver=resolver)


def validate_jsonl(path: Path, validator: SchemaValidator) -> None:
    for idx, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if not stripped:
            continue
        try:
            record = json.loads(stripped)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path}:{idx}: invalid json ({exc})") from exc
        errors = sorted(validator.iter_errors(record), key=lambda e: e.path)
        if errors:
            messages = "; ".join([error.message for error in errors])
            raise ValueError(f"{path}:{idx}: schema validation failed ({messages})")


def validate_yaml_key(path: Path, required_key: str) -> None:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or required_key not in data:
        raise ValueError(f"{path}: missing required key '{required_key}'")


def main() -> int:
    checks = [
        (DATASETS_DIR / "activity.sample.jsonl", SCHEMAS_DIR / "activity_event.schema.json"),
        (DATASETS_DIR / "decisions.sample.jsonl", SCHEMAS_DIR / "decision.schema.json"),
        (DATASETS_DIR / "interactions.sample.jsonl", SCHEMAS_DIR / "interaction.schema.json"),
        (DATASETS_DIR / "metrics.sample.jsonl", SCHEMAS_DIR / "metric.schema.json"),
        (DATASETS_DIR / "sources.sample.jsonl", SCHEMAS_DIR / "source.schema.json"),
    ]

    for dataset_path, schema_path in checks:
        validator = load_schema(schema_path)
        validate_jsonl(dataset_path, validator)

    validate_yaml_key(DATASETS_DIR / "taxonomy.domains.yml", "domains")
    validate_yaml_key(DATASETS_DIR / "taxonomy.fields.yml", "project_v2_fields")
    validate_yaml_key(DATASETS_DIR / "taxonomy.labels.yml", "labels")

    insight_schema = json.loads(INSIGHT_SCHEMA.read_text(encoding="utf-8"))
    insight_schema.pop("$id", None)
    insight_validator = SchemaValidator(
        insight_schema,
        resolver=RefResolver(base_uri=INSIGHT_SCHEMA.as_uri(), referrer=insight_schema)
    )
    insight_data = json.loads(INSIGHT_SAMPLE.read_text(encoding="utf-8"))
    errors = sorted(insight_validator.iter_errors(insight_data), key=lambda e: e.path)
    if errors:
        messages = "; ".join([error.message for error in errors])
        raise ValueError(f"{INSIGHT_SAMPLE}: schema validation failed ({messages})")

    print("Knowledge schemas and datasets validation: OK")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"Validation failed: {exc}")
        sys.exit(1)
