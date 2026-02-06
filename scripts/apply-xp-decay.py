#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"\"\"\"Recalcula xp_effective aplicando decay mensual.\"\"\""

import json
from datetime import datetime, timezone
from pathlib import Path

import yaml


def parse_iso(value: str) -> datetime:
    normalized = value
    if normalized.endswith("Z"):
        normalized = normalized[:-1] + "+00:00"
    tz_part = normalized[-6:]
    if "+" not in tz_part and "-" not in tz_part:
        normalized = normalized + "+00:00"
    return datetime.fromisoformat(normalized)


def compute_weight(event_ts: datetime, half_life: float, floor: float) -> float:
    if half_life <= 0:
        return 1.0
    now = datetime.now(timezone.utc)
    delta = now - event_ts
    days = delta.total_seconds() / 86400
    ratio = 0.5 ** (days / half_life)
    return max(floor, ratio)


def load_decay_rules() -> dict:
    path = Path("metrics/xp-decay.yml")
    if not path.exists():
        raise RuntimeError("metrics/xp-decay.yml no existe")
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    decay = data.get("decay", {})
    default = decay.get("default", {})
    half_life = float(default.get("half_life_days", 180))
    floor = float(default.get("floor_ratio", 0.4))
    return {"half_life": half_life, "floor": floor}


def main():
    rules = load_decay_rules()
    half_life = rules["half_life"]
    floor = rules["floor"]
    users_dir = Path("metrics/users")
    if not users_dir.exists():
        raise RuntimeError("metrics/users no existe")

    updated = []
    for file in sorted(users_dir.iterdir()):
        if not file.is_file():
            continue
        data = json.loads(file.read_text(encoding="utf-8"))
        history = data.get("history", [])
        xp_total = 0.0
        xp_effective = 0.0
        xp_regulatory = 0.0

        for event in history:
            xp = float(event.get("xp", 0) or 0)
            xp_total += xp
            non_decay = event.get("non_decay") or event.get("type") == "regulatory"
            if non_decay:
                xp_regulatory += xp
                continue
            ts = event.get("timestamp")
            if not ts:
                continue
            try:
                weight = compute_weight(parse_iso(ts), half_life, floor)
            except Exception:
                continue
            xp_effective += xp * weight

        xp_effective = int(round(xp_effective))
        data["xp_total"] = int(round(xp_total))
        data["xp_effective"] = max(0, xp_effective)
        data["xp_regulatory"] = int(round(xp_regulatory))
        data["last_decay"] = datetime.now(timezone.utc).replace(tzinfo=timezone.utc).isoformat()

        file.write_text(json.dumps(data, indent=2, ensure_ascii=False))
        updated.append(file.name)

    print(f"XP decay aplicado a {len(updated)} usuarios.")
    return 0


if __name__ == "__main__":
    main()
