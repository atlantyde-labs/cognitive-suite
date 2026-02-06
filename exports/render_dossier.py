#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape

metrics_dir = Path("metrics/users")
creds_dir = Path("credentials/users")
template_dir = Path("exports/templates")
out_file = Path("exports/out/dossier.md")


def _collect_ledgers() -> list[dict]:
    ledgers = []
    for path in sorted(metrics_dir.glob("*.json")):
        if path.name == "template.json":
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        ledgers.append(data)
    return ledgers


def _collect_credentials() -> list[dict]:
    creds = []
    if not creds_dir.exists():
        return creds
    for user_dir in sorted(creds_dir.iterdir()):
        if not user_dir.is_dir():
            continue
        for path in sorted(user_dir.glob("*.json")):
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                continue
            achievement = data.get("achievement", {})
            lab = achievement.get("lab") or path.stem
            creds.append({"lab": lab, "user": data.get("recipient", {}).get("username", user_dir.name)})
    return creds


def main() -> int:
    ledgers = _collect_ledgers()
    template_env = Environment(
        loader=FileSystemLoader(str(template_dir)),
        trim_blocks=True,
        lstrip_blocks=True,
        autoescape=select_autoescape(["md", "gfm", "html", "xml"]),
    )
    template = template_env.get_template("dossier.md")
    data = {
        "users_total": len(ledgers),
        "auditors": sum(1 for ledger in ledgers if ledger.get("xp_regulatory", 0) >= 300 or "auditor" in ledger.get("roles", [])),
        "reviewers": sum(1 for ledger in ledgers if ledger.get("xp_regulatory", 0) >= 150 or "reviewer" in ledger.get("roles", [])),
        "credentials": _collect_credentials(),
    }
    out_file.parent.mkdir(parents=True, exist_ok=True)
    out_file.write_text(template.render(**data), encoding="utf-8")
    print(f"Dossier generado en {out_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
