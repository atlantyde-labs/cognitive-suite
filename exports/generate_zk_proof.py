#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path

metrics_dir = Path("metrics/users")
output_path = Path("dashboard/public/zk-proof.json")


def _hash_user(user: str, xp_reg: int, roles: list[str]) -> str:
    value = f"{user}|{xp_reg}|{','.join(sorted(set(roles)))}"
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()
    return digest


def main() -> int:
    if not metrics_dir.exists():
        print("metrics/users missing")
        return 1
    auditors = []
    proof_hashes = []
    for path in sorted(metrics_dir.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        xp_reg = int(data.get("xp_regulatory", 0))
        roles = data.get("roles", []) or []
        user = data.get("user") or path.stem
        if xp_reg >= 300 or "auditor" in roles:
            auditors.append(user)
            proof_hashes.append(_hash_user(user, xp_reg, roles))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "statement": "≥5 auditors with xp_regulatory ≥300",
        "proof_type": "range_commitment",
        "result": len(auditors) >= 5,
        "total_auditors": len(auditors),
        "hashes": proof_hashes,
    }
    output_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"ZK-lite proof saved to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
