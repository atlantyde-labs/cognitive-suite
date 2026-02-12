#!/usr/bin/env python3
import argparse
import json
import unicodedata
from datetime import datetime, timezone
from pathlib import Path

import yaml
from jsonschema import validators


ROOT = Path(__file__).resolve().parent.parent
KNOWLEDGE_DIR = ROOT / "knowledge"
SCHEMAS_DIR = KNOWLEDGE_DIR / "schemas"
DATASETS_DIR = KNOWLEDGE_DIR / "datasets"
CONTRACTS_DIR = KNOWLEDGE_DIR / "contracts"

VIEW_CONTRACTS_FILE = CONTRACTS_DIR / "view-contracts.yml"
VIEW_CONTRACT_SCHEMA = SCHEMAS_DIR / "view_contract.schema.json"
ONTOLOGY_FILE = DATASETS_DIR / "taxonomy.ontology.yml"
ONTOLOGY_SCHEMA = SCHEMAS_DIR / "taxonomy_ontology.schema.json"

DOMAINS_FILE = DATASETS_DIR / "taxonomy.domains.yml"
FIELDS_FILE = DATASETS_DIR / "taxonomy.fields.yml"
LABELS_FILE = DATASETS_DIR / "taxonomy.labels.yml"


def _load_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _validate_schema(data, schema, context: str):
    validator_cls = validators.validator_for(schema)
    validator = validator_cls(schema)
    errors = sorted(validator.iter_errors(data), key=lambda err: list(err.path))
    return [f"{context}: {'/'.join(str(p) for p in err.path) or '<root>'}: {err.message}" for err in errors]


def _norm(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    return normalized.casefold()


def _check_view_contracts(contracts: dict, ontology: dict, taxonomy: dict):
    errors = []
    checks = []

    ontology_domains = set(ontology["entities"]["domains"])
    ontology_sectors = set(ontology["entities"]["sectors"])
    taxonomy_domains = set(taxonomy["domains"])
    taxonomy_labels = set(taxonomy["labels"])
    sector_domain_map = {}
    for relation in ontology.get("relations", []):
        if (
            relation.get("source_type") == "sector"
            and relation.get("relation_type") == "governed_by"
            and relation.get("target_type") == "domain"
        ):
            sector = relation.get("source")
            domain = relation.get("target")
            if isinstance(sector, str) and isinstance(domain, str):
                sector_domain_map.setdefault(sector, set()).add(domain)

    for view in contracts["views"]:
        view_id = view["id"]
        view_path = ROOT / view["path"]
        view_result = {
            "id": view_id,
            "path": view["path"],
            "exists": view_path.exists(),
            "sections_ok": True,
            "links_ok": True,
            "narrative_ok": True,
            "taxonomy_ok": True,
        }

        if not view_path.exists():
            errors.append(f"view '{view_id}': file not found: {view['path']}")
            view_result["sections_ok"] = False
            view_result["links_ok"] = False
            view_result["narrative_ok"] = False
            view_result["taxonomy_ok"] = False
            checks.append(view_result)
            continue

        content = view_path.read_text(encoding="utf-8")
        normalized_content = _norm(content)

        for required_section in view["required_sections"]:
            if _norm(required_section) not in normalized_content:
                errors.append(
                    f"view '{view_id}': required section not found: '{required_section}' in {view['path']}"
                )
                view_result["sections_ok"] = False

        for required_link in view["required_links"]:
            if required_link not in content:
                errors.append(f"view '{view_id}': required link not found: '{required_link}' in {view['path']}")
                view_result["links_ok"] = False

        narrative_contract = view.get("narrative_contract")
        if isinstance(narrative_contract, dict):
            min_occurrences = int(narrative_contract.get("min_occurrences", 1))
            for marker in narrative_contract.get("markers", []):
                occurrences = normalized_content.count(_norm(marker))
                if occurrences < min_occurrences:
                    errors.append(
                        f"view '{view_id}': narrative marker '{marker}' appears {occurrences} times; "
                        f"expected at least {min_occurrences}"
                    )
                    view_result["narrative_ok"] = False

        domain = view["taxonomy_bindings"]["domain"]
        sector = view["taxonomy_bindings"]["sector"]
        if domain not in ontology_domains:
            errors.append(f"view '{view_id}': taxonomy domain '{domain}' not present in ontology")
            view_result["taxonomy_ok"] = False
        if domain not in taxonomy_domains:
            errors.append(f"view '{view_id}': taxonomy domain '{domain}' not present in taxonomy.domains.yml")
            view_result["taxonomy_ok"] = False
        if sector not in ontology_sectors:
            errors.append(f"view '{view_id}': taxonomy sector '{sector}' not present in ontology")
            view_result["taxonomy_ok"] = False
        allowed_domains = sorted(sector_domain_map.get(sector, set()))
        if not allowed_domains:
            errors.append(
                f"view '{view_id}': sector '{sector}' has no governed_by relation in ontology; cannot validate domain binding"
            )
            view_result["taxonomy_ok"] = False
        elif domain not in allowed_domains:
            errors.append(
                f"view '{view_id}': invalid taxonomy binding domain='{domain}' for sector='{sector}' "
                f"(allowed: {', '.join(allowed_domains)})"
            )
            view_result["taxonomy_ok"] = False

        for label in view.get("required_labels", []):
            if label not in taxonomy_labels:
                errors.append(f"view '{view_id}': required label '{label}' not present in taxonomy.labels.yml")
                view_result["taxonomy_ok"] = False

        checks.append(view_result)

    return errors, checks


def _check_ontology_alignment(ontology: dict, taxonomy: dict):
    errors = []

    ontology_domains = set(ontology["entities"]["domains"])
    ontology_labels = set(ontology["entities"]["labels"])
    ontology_fields = set(ontology["entities"]["fields"])

    taxonomy_domains = set(taxonomy["domains"])
    taxonomy_labels = set(taxonomy["labels"])
    taxonomy_fields = set(taxonomy["fields"])

    missing_domains = sorted(ontology_domains - taxonomy_domains)
    missing_labels = sorted(ontology_labels - taxonomy_labels)
    missing_fields = sorted(ontology_fields - taxonomy_fields)

    if missing_domains:
        errors.append(f"ontology domains missing from taxonomy.domains.yml: {', '.join(missing_domains)}")
    if missing_labels:
        errors.append(f"ontology labels missing from taxonomy.labels.yml: {', '.join(missing_labels)}")
    if missing_fields:
        errors.append(f"ontology fields missing from taxonomy.fields.yml: {', '.join(missing_fields)}")

    return errors


def _flatten_labels(labels_dict: dict):
    values = []
    for item in labels_dict.values():
        if isinstance(item, list):
            values.extend(item)
    return values


def main():
    parser = argparse.ArgumentParser(
        description="Validate UAT view contracts and ontology alignment for Atlantyqa knowledge base."
    )
    parser.add_argument(
        "--output",
        default="outputs/ci-evidence/knowledge-uat-report.json",
        help="Path to write JSON UAT report.",
    )
    args = parser.parse_args()

    view_contracts = _load_yaml(VIEW_CONTRACTS_FILE)
    ontology = _load_yaml(ONTOLOGY_FILE)
    taxonomy_domains = _load_yaml(DOMAINS_FILE)
    taxonomy_fields = _load_yaml(FIELDS_FILE)
    taxonomy_labels = _load_yaml(LABELS_FILE)

    taxonomy = {
        "domains": list((taxonomy_domains or {}).get("domains", {}).keys()),
        "fields": list((taxonomy_fields or {}).get("project_v2_fields", {}).get("single_select", []))
        + list((taxonomy_fields or {}).get("project_v2_fields", {}).get("number", [])),
        "labels": _flatten_labels((taxonomy_labels or {}).get("labels", {})),
    }

    report = {
        "report_version": "1.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "contracts_file": str(VIEW_CONTRACTS_FILE.relative_to(ROOT)),
        "ontology_file": str(ONTOLOGY_FILE.relative_to(ROOT)),
        "checks": [],
        "errors": [],
    }

    view_schema_errors = _validate_schema(view_contracts, _load_json(VIEW_CONTRACT_SCHEMA), "view_contracts")
    ontology_schema_errors = _validate_schema(ontology, _load_json(ONTOLOGY_SCHEMA), "taxonomy_ontology")
    report["errors"].extend(view_schema_errors)
    report["errors"].extend(ontology_schema_errors)

    view_checks = []
    if view_schema_errors or ontology_schema_errors:
        if view_schema_errors:
            report["errors"].append(
                "[knowledge-uat] semantic checks skipped: view contracts schema validation failed"
            )
        if ontology_schema_errors:
            report["errors"].append(
                "[knowledge-uat] semantic checks skipped: ontology schema validation failed"
            )
    else:
        view_errors, view_checks = _check_view_contracts(view_contracts, ontology, taxonomy)
        report["errors"].extend(view_errors)
        report["checks"].extend(view_checks)
        report["errors"].extend(_check_ontology_alignment(ontology, taxonomy))

    views = view_contracts.get("views", []) if isinstance(view_contracts, dict) else []
    report["summary"] = {
        "views_total": len(views) if isinstance(views, list) else 0,
        "views_valid": sum(
            1
            for item in view_checks
            if item["exists"] and item["sections_ok"] and item["links_ok"] and item["narrative_ok"] and item["taxonomy_ok"]
        ),
        "errors_total": len(report["errors"]),
    }

    output_path = ROOT / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2, ensure_ascii=True), encoding="utf-8")

    if report["errors"]:
        for error in report["errors"]:
            print(f"[knowledge-uat] ERROR: {error}")
        print(f"[knowledge-uat] FAILED. Report: {output_path}")
        return 1

    print(f"[knowledge-uat] OK. Report: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
