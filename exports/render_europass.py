#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape


data_dir = Path("metrics/users")
template_dir = Path("exports/templates")
out_dir = Path("exports/out")
cred_root = Path("credentials/users")


def _split_name(user: str) -> tuple[str, str]:
    if "." in user:
        first, rest = user.split(".", 1)
        return first.capitalize(), rest.capitalize()
    if "-" in user:
        first, rest = user.split("-", 1)
        return first.capitalize(), rest.capitalize()
    return user.capitalize(), "Contributor"


def _gather_skillset(data: dict) -> list[str]:
    skills = set()
    skills.update(data.get("domains", []))
    skills.update(data.get("roles", []))
    skills.update(entry.get("domain") for entry in data.get("history", []) if entry.get("domain"))
    return sorted(skill.replace("_", " ") for skill in skills if skill)


def _load_credentials(user: str) -> list[dict]:
    creds = []
    base = cred_root / user
    if not base.exists():
        return creds
    for path in sorted(base.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        achievement = data.get("achievement", {})
        lab = achievement.get("lab") or path.stem
        creds.append({
            "lab": lab,
            "title": achievement.get("title"),
            "credits": achievement.get("credits"),
            "ects": achievement.get("ects_equivalent"),
        })
    return creds


def _prepare_labs(data: dict) -> list[dict]:
    labs = []
    for entry in data.get("lab_credits", []):
        labs.append(
            {
                "lab": entry.get("lab"),
                "credits": entry.get("credits", 0),
                "ects": entry.get("eu_ects_equivalent", 0),
            }
        )
    return labs


def main() -> int:
    if not data_dir.exists():
        print("No metrics/users directory found.")
        return 1
    template_env = Environment(
        loader=FileSystemLoader(str(template_dir)),
        autoescape=select_autoescape(["html", "xml"]),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    template = template_env.get_template("europass.xml")
    out_dir.mkdir(parents=True, exist_ok=True)

    for ledger_path in sorted(data_dir.glob("*.json")):
        if ledger_path.name == "template.json":
            continue
        data = json.loads(ledger_path.read_text(encoding="utf-8"))
        user = data.get("user")
        if not user:
            continue
        first_name, surname = _split_name(user)
        labs = _prepare_labs(data)
        skills = _gather_skillset(data)
        credentials = _load_credentials(user)
        context = {
            "first_name": first_name,
            "surname": surname,
            "labs": labs,
            "skills": skills,
            "xp_total": data.get("xp_total", 0),
            "xp_effective": data.get("xp_effective", 0),
            "xp_regulatory": data.get("xp_regulatory", 0),
            "credentials": credentials,
        }
        out_path = out_dir / f"{user}-europass.xml"
        out_path.write_text(template.render(**context), encoding="utf-8")
        print(f"Written Europass export for {user} -> {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
