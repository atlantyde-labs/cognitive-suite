#!/usr/bin/env python3
"""Validate stakeholder intake consistency across templates, workflows, and taxonomy."""

import re
import sys
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parent.parent
ISSUE_TEMPLATE_FILE = ROOT / ".github" / "ISSUE_TEMPLATE" / "stakeholder_intake.yml"
TRIAGE_WORKFLOW_FILE = ROOT / ".github" / "workflows" / "stakeholder-intake-triage.yml"
ADD_TO_PROJECT_FILE = ROOT / ".github" / "workflows" / "add_to_project.yml"
LABELS_FILE = ROOT / ".github" / "labels.yml"
TAXONOMY_LABELS_FILE = ROOT / "knowledge" / "datasets" / "taxonomy.labels.yml"


def _load_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def _extract_stakeholder_options(issue_template: dict):
    for item in issue_template.get("body", []):
        if item.get("id") == "stakeholder_type":
            return list(item.get("attributes", {}).get("options", []))
    return []


def _extract_stakeholder_map_and_labels(triage_content: str):
    stakeholder_match = re.search(
        r"const stakeholderMap = \{([\s\S]*?)\n\s*\};", triage_content, flags=re.MULTILINE
    )
    if not stakeholder_match:
        raise ValueError("Could not parse stakeholderMap in stakeholder-intake-triage workflow")

    stakeholder_block = stakeholder_match.group(1)
    stakeholder_entries = re.findall(r'"([^"]+)"\s*:\s*\[([^\]]*)\]', stakeholder_block)
    stakeholder_map = {}
    stakeholder_labels = set()
    for key, values in stakeholder_entries:
        labels = re.findall(r'"([^"]+)"', values)
        stakeholder_map[key] = labels
        stakeholder_labels.update(labels)

    urgency_match = re.search(r"const urgencyMap = \{([\s\S]*?)\n\s*\};", triage_content, flags=re.MULTILINE)
    if not urgency_match:
        raise ValueError("Could not parse urgencyMap in stakeholder-intake-triage workflow")

    urgency_block = urgency_match.group(1)
    urgency_labels = set(re.findall(r'"(sla-[0-9]+h)"', urgency_block))

    return stakeholder_map, stakeholder_labels, urgency_labels


def _extract_add_to_project_labels(add_to_project: dict):
    jobs = add_to_project.get("jobs", {})
    job = jobs.get("add-to-project", {})
    for step in job.get("steps", []):
        if step.get("name") == "Add Issue/PR to Org Project (by labels)":
            raw = step.get("with", {}).get("labeled", "")
            return [label.strip() for label in raw.split(",") if label.strip()]
    return []


def main() -> int:
    issue_template = _load_yaml(ISSUE_TEMPLATE_FILE)
    triage_content = TRIAGE_WORKFLOW_FILE.read_text(encoding="utf-8")
    add_to_project = _load_yaml(ADD_TO_PROJECT_FILE)
    labels = _load_yaml(LABELS_FILE)
    taxonomy_labels = _load_yaml(TAXONOMY_LABELS_FILE)

    stakeholder_options = _extract_stakeholder_options(issue_template)
    stakeholder_map, stakeholder_labels, urgency_labels = _extract_stakeholder_map_and_labels(triage_content)
    add_to_project_labels = set(_extract_add_to_project_labels(add_to_project))
    label_names = {entry.get("name") for entry in labels if isinstance(entry, dict)}

    taxonomy_stakeholder_labels = set(
        (taxonomy_labels or {}).get("labels", {}).get("stakeholders", [])
    )

    errors = []

    map_keys = set(stakeholder_map.keys())
    options_set = set(stakeholder_options)
    missing_map_keys = sorted(options_set - map_keys)
    extra_map_keys = sorted(map_keys - options_set)
    if missing_map_keys:
        errors.append(f"stakeholder options missing in triage map: {', '.join(missing_map_keys)}")
    if extra_map_keys:
        errors.append(f"triage map contains keys not present in issue template: {', '.join(extra_map_keys)}")

    default_triage_labels = {"intake-stakeholder", "contrib-review", "level-beta"}
    required_triage_labels = stakeholder_labels | urgency_labels | default_triage_labels
    missing_in_labels = sorted(required_triage_labels - label_names)
    if missing_in_labels:
        errors.append(f"triage emits labels not declared in .github/labels.yml: {', '.join(missing_in_labels)}")

    audience_labels = {label for label in stakeholder_labels if label.startswith("audience-")}
    required_project_labels = audience_labels | urgency_labels | {"intake-stakeholder"}
    missing_in_project = sorted(required_project_labels - add_to_project_labels)
    if missing_in_project:
        errors.append(
            "add_to_project workflow does not include all stakeholder labels: "
            + ", ".join(missing_in_project)
        )

    missing_in_taxonomy = sorted(required_project_labels - taxonomy_stakeholder_labels)
    if missing_in_taxonomy:
        errors.append(
            "taxonomy.labels.yml stakeholders missing labels used by intake/project: "
            + ", ".join(missing_in_taxonomy)
        )

    undeclared_taxonomy_labels = sorted(taxonomy_stakeholder_labels - label_names)
    if undeclared_taxonomy_labels:
        errors.append(
            ".github/labels.yml is missing taxonomy stakeholder labels: "
            + ", ".join(undeclared_taxonomy_labels)
        )

    if errors:
        for error in errors:
            print(f"[stakeholder-intake] ERROR: {error}")
        return 1

    print("[stakeholder-intake] OK")
    print(f"- Stakeholder options: {len(stakeholder_options)}")
    print(f"- Triage sectors mapped: {len(stakeholder_map)}")
    print(f"- Required intake labels validated: {len(required_project_labels)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
