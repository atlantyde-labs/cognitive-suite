#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

scripts = [
    "render_europass.py",
    "render_dossier.py",
    "generate_zk_proof.py",
    "generate_territorial_kpis.py",
]

scripts_dir = Path(__file__).resolve().parent

if __name__ == "__main__":
    for script in scripts:
        path = scripts_dir / script
        print(f"Running {script}...")
        subprocess.run([path], check=True)
