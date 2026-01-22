#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Export the Labs ledger to CSV.
"""

import argparse
import csv
import json
from pathlib import Path
from typing import Any, Dict


def load_ledger(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {"entries": []}
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser(description="Export Labs ledger to CSV")
    parser.add_argument("--ledger", default="labs/ledger.json", help="Path to ledger JSON")
    parser.add_argument("--output", default="labs/ledger.csv", help="CSV output path")
    args = parser.parse_args()

    ledger_path = Path(args.ledger)
    output_path = Path(args.output)
    ledger = load_ledger(ledger_path)
    entries = ledger.get("entries", [])

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "id",
                "timestamp",
                "user",
                "lab",
                "points",
                "badge",
                "status",
                "evidence",
                "notes",
            ],
        )
        writer.writeheader()
        for entry in entries:
            writer.writerow(entry)

    print(f"✅ Exported {len(entries)} entries to {output_path}")


if __name__ == "__main__":
    main()
