#!/env python3
# -*- coding: utf-8 -*-
"""
Validator for Lab 01: Deep Dive.
Checks if the security pipeline was correctly executed with redaction enabled.
"""

import json
import sys
from pathlib import Path

def verify():
    insights_file = Path("outputs/insights/analysis.json")
    audit_file = Path("outputs/audit/analysis.jsonl")

    if not insights_file.exists():
        return False, "Evidence missing: outputs/insights/analysis.json not found. Run 'python cogctl.py analyze' first."

    try:
        with open(insights_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        return False, f"Error reading evidence: {e}"

    if not data:
        return False, "Evidence empty: No processed records found in analysis.json."

    # Check for redaction
    redacted_records = [r for r in data if r.get("redacted") is True]

    if not redacted_records:
        return False, "Security failure: No records were redacted. Did you set COGNITIVE_REDACT=1?"

    # Audit trail check (optional but recommended for Phase 2)
    if not audit_file.exists():
         return False, "Audit failure: outputs/audit/analysis.jsonl not found. The mission requires an audit trail."

    return True, f"Success: {len(redacted_records)} records verified with secure redaction."

if __name__ == "__main__":
    success, message = verify()
    print(message)
    sys.exit(0 if success else 1)
