#!/ env python3
# -*- coding: utf-8 -*-
"""
Gamification Engine for Atlantyqa Cognitive Suite.
Centralizes XP and badge logic from metrics/xp-rules.yml.
"""

import argparse
import json
import sys
from pathlib import Path
import yaml

# Add current directory to path if needed (for imports if we add any)
sys.path.append(str(Path(__file__).parent.parent))

class GamificationEngine:
    def __init__(self, config_path="metrics/xp-rules.yml"):
        self.config_path = Path(config_path)
        if not self.config_path.exists():
            print(f"Error: {self.config_path} not found.", file=sys.stderr)
            sys.exit(1)

        with open(self.config_path, "r", encoding="utf-8") as f:
            self.config = yaml.safe_load(f) or {}

    def get_task_reward(self, level_key):
        """Returns XP and Label for a given task level (level_1 to level_4)."""
        tasks = self.config.get("task_rewards", {})
        norm_key = level_key.lower().replace("-", "_")
        reward = tasks.get(norm_key) or tasks.get(f"level_{norm_key}")
        if not reward:
            # Try to map common labels like "L1"
            if norm_key in ["1", "l1", "explorer"]:
                reward = tasks.get("level_1")
            elif norm_key in ["2", "l2", "builder"]:
                reward = tasks.get("level_2")
            elif norm_key in ["3", "l3", "engineer"]:
                reward = tasks.get("level_3")
            elif norm_key in ["4", "l4", "steward"]:
                reward = tasks.get("level_4")

        return reward or {"xp": 0, "label": "Unknown"}

    def get_badge_info(self, badge_id):
        """Returns info for a specific badge."""
        badges = self.config.get("badges", {})
        return badges.get(badge_id)

    def get_level_for_xp(self, xp_total):
        """Calculates the user level based on total XP."""
        levels = self.config.get("levels", {})
        current_level = "L0"

        # Sort levels by min_xp
        sorted_levels = sorted(levels.items(), key=lambda x: x[1].get("min_xp", 0))

        for level_id, info in sorted_levels:
            if xp_total >= info.get("min_xp", 0):
                current_level = level_id

        return current_level

def main():
    parser = argparse.ArgumentParser(description="Atlantyqa Gamification Engine CLI")
    parser.add_argument("--level-info", help="Get XP and label for a level (e.g. level_1, l2, 3)")
    parser.add_argument("--calculate-level", type=int, help="Calculate final level from total XP")
    parser.add_argument("--json", action="store_true", help="Output in JSON format")

    args = parser.parse_args()
    engine = GamificationEngine()

    if args.level_info:
        info = engine.get_task_reward(args.level_info)
        if args.json:
            print(json.dumps(info))
        else:
            print(f"XP: {info.get('xp')}")
            print(f"Label: {info.get('label')}")

    elif args.calculate_level is not None:
        level = engine.get_level_for_xp(args.calculate_level)
        if args.json:
            print(json.dumps({"level": level}))
        else:
            print(level)
    else:
        # Default behavior: show version/status
        print(f"Atlantyqa Gamification Engine v{engine.config.get('version', '1')}")
        print(f"Loaded {len(engine.config.get('badges', {}))} badges and {len(engine.config.get('task_rewards', {}))} task rewards.")

if __name__ == "__main__":
    main()
