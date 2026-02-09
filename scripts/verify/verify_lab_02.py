#!/env python3
# -*- coding: utf-8 -*-
"""
Validator for Lab 02: GitOps Steward.
Checks if the pipeline was executed in 'prod' mode with hashing and salt.
"""

import json
import sys
from pathlib import Path

def verify():
    insights_file = Path("outputs/insights/analysis.json")

    if not insights_file.exists():
        return False, "Evidence missing: outputs/insights/analysis.json not found."

    try:
        with open(insights_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        return False, f"Error reading evidence: {e}"

    if not data:
        return False, "Evidence empty."

    # Lab 02 specific checks
    for record in data:
        redaction = record.get("redaction", {})
        if redaction.get("env") != "prod":
            return False, f"Environment mismatch: Expected 'prod', found '{redaction.get('env')}'. Missions in Lab 02 must be prod-ready."

        if not redaction.get("enabled"):
             return False, "Security failure: Redaction must be enabled in Lab 02."

        if not redaction.get("hash_salt_set"):
             return False, "Privacy failure: COGNITIVE_HASH_SALT must be set to ensure irreversible IDs."

    return True, "Success: Phase 2 production alignment verified. Data is safe for GitOps synchronization."

if __name__ == "__main__":
    success, message = verify()
    print(message)
    sys.exit(0 if success else 1)
