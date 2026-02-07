#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"\"\"\"Actualiza labs desbloqueados en base al XP disponible.\"\"\""

import argparse
import json
from pathlib import Path

import yaml


def load_labs() -> dict:
    path = Path("labs/lab-unlocks.yml")
    if not path.exists():
        raise RuntimeError("labs/lab-unlocks.yml no existe")
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    return data.get("labs", {})


def evaluate_user(file: Path, labs: dict):
    data = json.loads(file.read_text(encoding="utf-8"))
    xp_effective = data.get("xp_effective", 0)
    xp_regulatory = data.get("xp_regulatory", 0)
    badges = set(data.get("badges", {}).keys())
    domains = set(data.get("domains", []))

    unlocked = []
    locked = []
    credits = []

    for lab_id, info in labs.items():
        unlock = info.get("unlock", {})
        threshold_effective = unlock.get("xp_effective", 0)
        threshold_regulatory = unlock.get("xp_regulatory", 0)
        required_badges = set(unlock.get("badges", []))
        required_domains = set(unlock.get("domains", []))

        meets = True
        if xp_effective < threshold_effective:
            meets = False
        if xp_regulatory < threshold_regulatory:
            meets = False
        if required_badges and not required_badges <= badges:
            meets = False
        if required_domains and not required_domains <= domains:
            meets = False

        if meets:
            unlocked.append(lab_id)
            credit = unlock.get("credits")
            if credit:
                credits.append(
                    {
                        "lab": lab_id,
                        "credits": credit.get("credits", 0),
                        "eu_ects_equivalent": credit.get("eu_ects_equivalent", 0),
                    }
                )
        else:
            locked.append(lab_id)

    data["labs_unlocked"] = sorted(unlocked)
    data["labs_locked"] = sorted(locked)
    data["lab_credits"] = credits
    file.write_text(json.dumps(data, indent=2, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--user", help="Usuario a evaluar (nombre de archivo sin .json)")
    args = parser.parse_args()

    labs = load_labs()
    users_dir = Path("metrics/users")
    targets = []
    if args.user:
        targets.append(users_dir / f"{args.user}.json")
    else:
        targets = [p for p in users_dir.iterdir() if p.is_file()]

    for file in targets:
        if not file.exists():
            continue
        evaluate_user(file, labs)


if __name__ == "__main__":
    main()
