#!/env python3
# -*- coding: utf-8 -*-
"""
Ledger Validator for Atlantyqa Cognitive Suite.
Ensures all user ledgers in metrics/users/ are consistent and follow the schema.
"""

import json
import sys
from pathlib import Path
from gamification_engine import GamificationEngine

def main():
    engine = GamificationEngine()
    ledger_dir = Path("metrics/users")

    if not ledger_dir.exists():
        print("Error: metrics/users directory not found.")
        sys.exit(1)

    invalid_count = 0
    checked_count = 0

    for ledger_file in ledger_dir.glob("*.json"):
        if ledger_file.name == "template.json":
            continue

        checked_count += 1
        with open(ledger_file, "r", encoding="utf-8") as f:
            try:
                data = json.load(f)
            except json.JSONDecodeError:
                print(f"❌ {ledger_file.name}: Invalid JSON format")
                invalid_count += 1
                continue

        is_valid, msg = engine.validate_ledger_data(data)
        if is_valid:
            print(f"✅ {ledger_file.name}: Valid")
        else:
            print(f"❌ {ledger_file.name}: {msg}")
            invalid_count += 1

    print("-" * 30)
    print(f"Summary: {checked_count} checked, {invalid_count} invalid.")

    if invalid_count > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
