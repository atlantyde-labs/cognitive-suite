#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"\"\"\"Agrega XP regulatorio según las reglas de etiquetas y compliance.\"\"\""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import yaml


def load_config():
    path = Path("metrics/xp-regulatory.yml")
    if not path.exists():
        raise RuntimeError("metrics/xp-regulatory.yml no existe")
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    return data.get("regulatory_xp", {})


def ensure_ledger(user: str, timestamp: str) -> Path:
    ledger_dir = Path("metrics/users")
    ledger_dir.mkdir(parents=True, exist_ok=True)
    ledger_file = ledger_dir / f"{user}.json"

    if not ledger_file.exists():
        ledger_file.write_text(
            json.dumps(
                {
                    "user": user,
                    "xp_total": 0,
                    "xp_effective": 0,
                    "xp_regulatory": 0,
                    "level": "L0",
                    "last_seen": timestamp,
                    "badges": {},
                    "history": [],
                    "feedback": [],
                    "domains": [],
                    "labs_unlocked": [],
                    "labs_locked": [],
                    "lab_credits": [],
                },
                indent=2,
                ensure_ascii=False,
            )
        )

    return ledger_file


def parse_labels(raw: str):
    try:
        data = json.loads(raw)
        if isinstance(data, list):
            return {str(label).lower() for label in data}
        return set()
    except json.JSONDecodeError:
        return set()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--user", required=True)
    parser.add_argument("--pr", required=True)
    parser.add_argument("--labels", required=True)
    parser.add_argument("--timestamp", required=True)
    args = parser.parse_args()

    labels = parse_labels(args.labels)
    config = load_config()
    ledger_file = ensure_ledger(args.user, args.timestamp)
    data = json.loads(ledger_file.read_text(encoding="utf-8"))
    history = data.get("history", [])
    existing = {(entry.get("type"), entry.get("source_pr")) for entry in history}

    awarded = []
    for key, rule in config.items():
        label = rule.get("label", "").lower()
        if label and label not in labels:
            continue
        requires = [req.lower() for req in rule.get("requires_labels", [])]
        if not set(requires).issubset(labels):
            continue
        domains = {dom.lower() for dom in rule.get("domains", [])}
        if domains and not domains & labels:
            continue
        entry_key = (key, int(args.pr))
        if entry_key in existing:
            continue
        xp_value = rule.get("xp", 0)
        domain = rule.get("domain")
        data["xp_total"] = int(data.get("xp_total", 0) + xp_value)
        data["xp_regulatory"] = int(data.get("xp_regulatory", 0) + xp_value)
        event = {
            "type": "regulatory",
            "regulatory": key,
            "domain": domain,
            "xp": xp_value,
            "pr": int(args.pr),
            "timestamp": args.timestamp,
            "non_decay": True,
            "source_pr": int(args.pr),
        }
        data.setdefault("history", []).append(event)
        data["last_seen"] = args.timestamp
        awarded.append(
            {
                "type": key,
                "domain": domain,
                "xp": xp_value,
                "label": label,
            }
        )

    ledger_file.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    result = {
        "awarded": bool(awarded),
        "entries": awarded,
        "xp": sum(item["xp"] for item in awarded),
        "domains": [entry["domain"] for entry in awarded if entry.get("domain")],
    }
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
