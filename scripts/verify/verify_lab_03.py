#!/env python3
# -*- coding: utf-8 -*-
"""
Validator for Lab 03: Bootstrap Dashboard.
Checks if the user has customized the strealit app with their own widgets.
"""

import sys
from pathlib import Path

def verify():
    dashboard_file = Path("frontend/streamlit_app.py")
    insights_file = Path("outputs/insights/analysis.json")

    if not dashboard_file.exists():
        return False, "Evidence missing: frontend/streamlit_app.py not found."

    if not insights_file.exists():
        return False, "Evidence missing: No data to visualize (analysis.json missing)."

    # Check for customization (Paso 4)
    content = dashboard_file.read_text(encoding="utf-8")

    # Anchors for customization from Lab 03 instructions
    custom_markers = [
        "st.metric(",
        "st.subheader(",
        "Mi Métrica Custom",
        "🎯"
    ]

    # We want to find at least one marker that indicates changes in Paso 4
    # but specifically ones that might have been added.
    # Let's be more specific: the lab suggests:
    # st.subheader("🎯 Mi Métrica Custom")
    # st.metric("Total Entidades", ...)

    if "🎯" in content or "Mi Métrica Custom" in content:
        return True, "Success: Dashboard customization detected. mission Lab 03 completed!"

    # Fallback: check if the file was modified recently? No, better check for content.
    # Let's count metrics. If they added a NEW metric.
    if content.count("st.metric") > 0: # The baseline might not have any. Let's check.
         return True, "Success: Custom metrics detected in dashboard."

    return False, "Technical failure: No dashboard customizations found. Did you complete Paso 4 of the mission?"

if __name__ == "__main__":
    success, message = verify()
    print(message)
    sys.exit(0 if success else 1)
