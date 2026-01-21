#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Append a reward entry to the Labs ledger.
"""

import argparse
import json
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_ledger(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {"schema_version": "1.0", "entries": []}
    return json.loads(path.read_text(encoding="utf-8"))


def write_ledger(path: Path, data: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Append a Labs reward entry")
    parser.add_argument("--ledger", default="labs/ledger.json", help="Path to ledger JSON")
    parser.add_argument("--user", required=True, help="User identifier")
    parser.add_argument("--lab", required=True, help="Lab identifier")
    parser.add_argument("--points", type=int, required=True, help="Points awarded")
    parser.add_argument("--badge", default="", help="Badge awarded")
    parser.add_argument("--status", default="awarded", help="Status: awarded|pending|revoked")
    parser.add_argument("--evidence", default="", help="Evidence reference (PR/commit/link)")
    parser.add_argument("--notes", default="", help="Optional notes")
    args = parser.parse_args()

    ledger_path = Path(args.ledger)
    ledger = load_ledger(ledger_path)
    entries = ledger.setdefault("entries", [])

    entry = {
        "id": str(uuid.uuid4()),
        "timestamp": now_iso(),
        "user": args.user,
        "lab": args.lab,
        "points": args.points,
        "badge": args.badge,
        "status": args.status,
        "evidence": args.evidence,
        "notes": args.notes,
    }
    entries.append(entry)
    write_ledger(ledger_path, ledger)
    print(f"✅ Added entry {entry['id']} to {ledger_path}")


if __name__ == "__main__":
    main()
