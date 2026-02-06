#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

metrics_dir = Path("metrics/users")
output_path = Path("dashboard/public/kpis-territorial.json")


def _safe_float(value) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def main() -> int:
    if not metrics_dir.exists():
        print("metrics/users missing")
        return 1
    regions: dict[str, dict] = {}
    for path in sorted(metrics_dir.glob("*.json")):
        if path.name == "template.json":
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        territory = data.get("territory") or {}
        region = territory.get("region", "global").lower()
        province = territory.get("province", "unknown").lower()
        programs = territory.get("program", []) if isinstance(territory.get("program"), list) else []
        xp_regulatory = int(data.get("xp_regulatory", 0))
        labs = len(data.get("labs_unlocked", []))
        users = regions.setdefault(region, {"participants": 0, "auditors": 0, "labs_completed": 0, "provinces": {}})
        users["participants"] += 1
        users["labs_completed"] += labs
        if xp_regulatory >= 300:
            users["auditors"] += 1
        province_entry = users["provinces"].setdefault(province, {"participants": 0, "iti": 0, "fp_dual": 0})
        province_entry["participants"] += 1
        if "ITI" in programs or "iti" in programs:
            province_entry["iti"] += 1
        if "FP_DUAL" in programs or "fp_dual" in programs:
            province_entry["fp_dual"] += 1
    for region, data in regions.items():
        participants = data.get("participants", 0)
        labs = data.get("labs_completed", 0)
        data["employability_rate"] = round(min(1.0, labs / max(1, participants * 2)), 2)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(regions, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Territorial KPIs exported to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
