import json
from pathlib import Path

import yaml


METRICS_DIR = Path("metrics")


def _load_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def test_xp_rules_definitions():
    path = METRICS_DIR / "xp-rules.yml"
    assert path.exists()
    cfg = _load_yaml(path)
    assert cfg.get("version") == 1
    badges = cfg.get("badges", {})
    assert "owner_badge" in badges
    assert badges["owner_badge"].get("base_xp", 0) > 0
    levels = cfg.get("levels", {})
    assert levels
    for level, value in levels.items():
        assert "min_xp" in value


def test_decay_rules_defined():
    path = METRICS_DIR / "xp-decay.yml"
    assert path.exists()
    cfg = _load_yaml(path)
    decay = cfg.get("decay", {})
    assert "default" in decay
    default = decay["default"]
    assert default.get("half_life_days", 0) > 0
    assert 0 <= default.get("floor_ratio", 0) <= 1


def test_regulatory_xp_rules():
    path = METRICS_DIR / "xp-regulatory.yml"
    assert path.exists()
    cfg = _load_yaml(path)
    reg = cfg.get("regulatory_xp", {})
    assert reg
    for name, entry in reg.items():
        assert entry.get("xp", -1) >= 0
        assert "label" in entry


def test_labs_unlock_matrix():
    path = Path("labs") / "lab-unlocks.yml"
    assert path.exists()
    cfg = _load_yaml(path)
    labs = cfg.get("labs", {})
    assert labs
    for lab, info in labs.items():
        unlock = info.get("unlock", {})
        assert unlock
        assert "credits" in unlock
        assert any(key in unlock for key in ("xp_effective", "xp_regulatory"))


def test_ledgers_follow_template():
    template_path = METRICS_DIR / "users" / "template.json"
    assert template_path.exists()
    template = json.loads(template_path.read_text(encoding="utf-8"))
    for ledger_path in sorted((METRICS_DIR / "users").glob("*.json")):
        if ledger_path.name == "template.json":
            continue
        data = json.loads(ledger_path.read_text(encoding="utf-8"))
        assert data.get("user")
        assert data.get("xp_total") >= 0
        assert "history" in data
        assert isinstance(data.get("badges"), dict)
