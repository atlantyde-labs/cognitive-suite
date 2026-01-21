#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
frontend/onboarding_app.py
--------------------------

Streamlit onboarding app for new contributors. It guides users through
setup, Labs selection, and evidence collection. This is the initial
experience for early adopters.
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict, Any

import streamlit as st  # type: ignore


def load_lab_files(labs_dir: Path) -> List[Path]:
    if not labs_dir.exists():
        return []
    return sorted([p for p in labs_dir.glob("lab-*.md") if p.is_file()])


def load_ledger(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {"entries": []}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {"entries": []}


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def page_intro() -> None:
    st.title("Labs Onboarding")
    st.write(
        "This experience helps new contributors complete Labs and collect evidence. "
        "Use the checklist to track progress."
    )

    st.subheader("Checklist")
    items = [
        "Read the challenge overview",
        "Run ingest and analyze",
        "Enable redaction in prod mode",
        "Open Streamlit UI",
        "Collect audit logs",
        "Submit evidence via PR",
    ]
    for item in items:
        st.checkbox(item, key=f"check_{item}")

    st.subheader("Agent tips")
    st.info("Lab Coach: Focus on evidence. If it is not reproducible, it does not count.")
    st.warning("Security Guard: Never sync raw outputs to a remote repo in prod.")


def page_setup() -> None:
    st.header("Setup")
    st.write("Recommended environment variables:")
    st.code(
        """export COGNITIVE_ENV=prod
export COGNITIVE_HASH_SALT=change_me
export COGNITIVE_UI_TOKEN_VIEWER=viewer_token
export COGNITIVE_UI_TOKEN_ANALYST=analyst_token
export COGNITIVE_UI_TOKEN_ADMIN=admin_token
""",
        language="bash",
    )

    st.write("Commands:")
    st.code(
        """python cogctl.py init
python cogctl.py ingest demo_input.json
python cogctl.py analyze
streamlit run frontend/streamlit_app.py --server.headless true --server.port 8501
""",
        language="bash",
    )


def page_labs(labs_dir: Path) -> None:
    st.header("Labs")
    labs = load_lab_files(labs_dir)
    if not labs:
        st.warning("No Labs found. Ensure the labs/ folder exists.")
        return
    lab_titles = [p.name for p in labs]
    selected = st.selectbox("Choose a Lab", options=lab_titles)
    lab_path = labs[lab_titles.index(selected)]
    st.subheader(selected)
    st.markdown(lab_path.read_text(encoding="utf-8"))


def page_evidence() -> None:
    st.header("Evidence")
    st.write("Minimum evidence for Lab completion:")
    st.markdown(
        """
- PR with required outputs
- Audit logs (`outputs/audit/*.jsonl`)
- CI logs and SBOM artifacts
"""
    )
    st.info("Reviewer: Ensure evidence is reproducible and redacted in prod.")

    st.subheader("PR Checklist")
    checklist = [
        "PR includes required outputs",
        "Redaction verified for prod outputs",
        "Audit logs attached",
        "CI checks passed",
        "SCA/SBOM artifacts linked",
        "Docs updated (if needed)",
    ]
    checked = []
    for item in checklist:
        checked.append(st.checkbox(item, key=f"pr_check_{item}"))
    total = len(checklist)
    done = sum(1 for ok in checked if ok)
    st.progress(done / total)
    st.caption(f"Checklist progress: {done}/{total}")

    st.subheader("Evidence upload hints")
    st.markdown(
        """
- Attach CI logs or link to the workflow run.
- Include `outputs/audit/analysis.jsonl` and `outputs/audit/ui_access.jsonl`.
- Add SBOM artifacts (`sbom.spdx.json`, `sbom.cdx.json`) to the PR.
- Provide a short summary of redaction validation.
"""
    )
    st.code(
        """Evidence summary (template):
- Lab:
- PR:
- Outputs:
- Audit logs:
- CI/SCA/SBOM links:
- Notes:
""",
        language="markdown",
    )

    st.subheader("Evidence uploader (stub)")
    st.caption("Files are not stored automatically; this saves only a local manifest.")
    lab_id = st.text_input("Lab ID (e.g., lab-01-secure-pipeline)")
    pr_link = st.text_input("PR link or commit")
    notes = st.text_area("Notes")
    files = st.file_uploader(
        "Select evidence files (optional)",
        accept_multiple_files=True,
    )

    if files:
        st.write("Selected files:")
        for item in files:
            st.write(f"- {item.name} ({item.size} bytes)")

    outputs_dir = Path(os.getenv("COGNITIVE_OUTPUTS", "outputs"))
    evidence_dir = outputs_dir / "evidence"
    if st.button("Save manifest"):
        manifest = {
            "timestamp": now_iso(),
            "lab": lab_id,
            "pr": pr_link,
            "notes": notes,
            "files": [{"name": f.name, "size": f.size} for f in files or []],
        }
        evidence_dir.mkdir(parents=True, exist_ok=True)
        manifest_path = evidence_dir / f"manifest-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        st.success(f"Manifest saved to {manifest_path}")


def page_rewards(ledger_path: Path) -> None:
    st.header("Rewards Ledger")
    st.caption(f"Ledger: {ledger_path}")
    ledger = load_ledger(ledger_path)
    entries = ledger.get("entries", [])
    user_default = os.getenv("COGNITIVE_LABS_USER", "")
    user_id = st.text_input("User identifier (optional)", value=user_default)

    if user_id:
        filtered = [e for e in entries if e.get("user") == user_id]
        total_points = sum(int(e.get("points", 0)) for e in filtered)
        badges = sorted({e.get("badge") for e in filtered if e.get("badge")})
        st.metric("Total points", total_points)
        st.write(f"Badges: {', '.join(badges) if badges else 'none'}")
        st.dataframe(filtered, use_container_width=True)
    else:
        summary: Dict[str, int] = {}
        for entry in entries:
            user = entry.get("user", "unknown")
            summary[user] = summary.get(user, 0) + int(entry.get("points", 0))
        st.subheader("Points by user")
        st.dataframe(
            [{"user": user, "points": points} for user, points in summary.items()],
            use_container_width=True,
        )


def main() -> None:
    labs_dir = Path(os.getenv("COGNITIVE_LABS_DIR", "labs"))
    ledger_path = Path(os.getenv("COGNITIVE_LABS_LEDGER", "labs/ledger.json"))
    st.sidebar.title("Onboarding")
    page = st.sidebar.radio("Section", ["Intro", "Setup", "Labs", "Evidence", "Rewards"])

    if page == "Intro":
        page_intro()
    elif page == "Setup":
        page_setup()
    elif page == "Labs":
        page_labs(labs_dir)
    elif page == "Rewards":
        page_rewards(ledger_path)
    else:
        page_evidence()


if __name__ == "__main__":
    main()
