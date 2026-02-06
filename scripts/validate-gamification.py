#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Validación de configuración de gamificación y ledger de early adopters."""

import json
import sys
from datetime import datetime
from pathlib import Path

import yaml


def parse_iso(value: str) -> datetime:
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    return datetime.fromisoformat(value)


def require_number(value, name):
    if not isinstance(value, (int, float)):
        raise ValueError(f"{name} debe ser numérico (encontrado {value!r})")
    return float(value)


def main():
    base = Path("metrics")
    rules_path = base / "xp-rules.yml"
    for required in (rules_path, base / "xp-decay.yml", base / "xp-regulatory.yml"):
        if not required.exists():
            raise RuntimeError(f"{required} no existe")

    config = yaml.safe_load(rules_path.read_text(encoding="utf-8"))
    if not isinstance(config, dict):
        raise RuntimeError("metrics/xp-rules.yml no tiene formato de diccionario")

    version = config.get("version")
    if version != 1:
        raise RuntimeError(f"Versión desconocida de xp-rules: {version}")

    badges = config.get("badges") or {}
    required_badges = {"owner_badge", "early_adopter"}
    missing = required_badges - set(badges)
    if missing:
        raise RuntimeError(f"Faltan badges obligatorios: {', '.join(sorted(missing))}")

    for badge_name, badge_cfg in badges.items():
        if not isinstance(badge_cfg, dict):
            raise RuntimeError(f"Badge {badge_name} debe ser un diccionario")
        require_number(badge_cfg.get("base_xp", 0), f"{badge_name}.base_xp")
        max_xp = badge_cfg.get("max_xp")
        if max_xp is not None:
            require_number(max_xp, f"{badge_name}.max_xp")
        multiplier = badge_cfg.get("multiplier") or {}
        if not isinstance(multiplier, dict):
            raise RuntimeError(f"{badge_name}.multiplier debe ser dict")
        for key, value in multiplier.items():
            require_number(value, f"{badge_name}.multiplier.{key}")
        conditions = badge_cfg.get("conditions", {})
        if not isinstance(conditions, dict):
            raise RuntimeError(f"{badge_name}.conditions debe ser dict")
        max_commits = conditions.get("max_commits")
        if max_commits is not None:
            require_number(max_commits, f"{badge_name}.conditions.max_commits")
        requires_codeowner = conditions.get("requires_codeowner")
        if requires_codeowner is not None and not isinstance(requires_codeowner, bool):
            raise RuntimeError(f"{badge_name}.conditions.requires_codeowner debe ser booleano")

    level_defs = config.get("levels", {})
    if not isinstance(level_defs, dict) or not level_defs:
        raise RuntimeError("La sección levels debe ser un diccionario no vacío")
    for key, info in level_defs.items():
        if "min_xp" not in info:
            raise RuntimeError(f"Nivel {key} no define min_xp")
        require_number(info["min_xp"], f"levels.{key}.min_xp")

    decay_config = yaml.safe_load((base / "xp-decay.yml").read_text(encoding="utf-8")) or {}
    if not isinstance(decay_config, dict):
        raise RuntimeError("metrics/xp-decay.yml inválido")
    decay = decay_config.get("decay")
    if not isinstance(decay, dict):
        raise RuntimeError("metrics/xp-decay.yml debe contener decay dict")

    regulatory_config = yaml.safe_load((base / "xp-regulatory.yml").read_text(encoding="utf-8")) or {}
    if not isinstance(regulatory_config, dict) or "regulatory_xp" not in regulatory_config:
        raise RuntimeError("metrics/xp-regulatory.yml inválido o sin regulatory_xp")
    for key, entry in regulatory_config["regulatory_xp"].items():
        if not isinstance(entry, dict):
            raise RuntimeError(f"regulatory_xp.{key} debe ser diccionario")
        require_number(entry.get("xp", 0), f"regulatory_xp.{key}.xp")
        if "label" not in entry:
            raise RuntimeError(f"regulatory_xp.{key} debe definir label")

    labs_config = yaml.safe_load(Path("labs/lab-unlocks.yml").read_text(encoding="utf-8")) or {}
    if not isinstance(labs_config, dict) or "labs" not in labs_config:
        raise RuntimeError("labs/lab-unlocks.yml inválido o sin labs")
    for key, info in labs_config["labs"].items():
        if "unlock" not in info:
            raise RuntimeError(f"lab {key} no define unlock")
        if not isinstance(info["unlock"], dict):
            raise RuntimeError(f"lab {key} unlock debe ser dict")

    user_dir = base / "users"
    if not user_dir.exists():
        raise RuntimeError("Directorio metrics/users no existe")

    for path in sorted(user_dir.iterdir()):
        if not path.is_file() or path.name == "template.json":
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        user = data.get("user")
        if not isinstance(user, str):
            raise RuntimeError(f"Archivo {path.name} necesita campo 'user' (string)")
        for key in ("xp_total", "xp_effective", "xp_regulatory"):
            value = data.get(key)
            if value is None or not isinstance(value, (int, float)):
                raise RuntimeError(f"{path.name} {key} inválido: {value!r}")
            if value < 0:
                raise RuntimeError(f"{path.name} {key} negativo: {value}")
        level = data.get("level")
        if not isinstance(level, str):
            raise RuntimeError(f"{path.name} level inválido: {level!r}")
        badges_map = data.get("badges")
        if badges_map is None or not isinstance(badges_map, dict):
            raise RuntimeError(f"{path.name} badges debe ser dict")
        history = data.get("history")
        if history is None or not isinstance(history, list):
            raise RuntimeError(f"{path.name} history debe ser lista")
        for event in history:
            if not isinstance(event, dict):
                raise RuntimeError(f"{path.name} history entry inválido: {event}")
            ts = event.get("timestamp")
            if ts:
                parse_iso(ts)
        last_seen = data.get("last_seen")
        if last_seen:
            parse_iso(last_seen)
        if not isinstance(data.get("labs_unlocked", []), list):
            raise RuntimeError(f"{path.name} labs_unlocked debe ser lista")
        if not isinstance(data.get("labs_locked", []), list):
            raise RuntimeError(f"{path.name} labs_locked debe ser lista")
        credits = data.get("lab_credits")
        if credits is None or not isinstance(credits, list):
            raise RuntimeError(f"{path.name} lab_credits debe ser lista")
        domains = data.get("domains")
        if domains is not None and not isinstance(domains, list):
            raise RuntimeError(f"{path.name} domains debe ser lista")

    print("Validación de gamificación completada correctamente.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # pragma: no cover
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
