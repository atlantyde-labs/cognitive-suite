# Cognitive Suite - Local User View (Frontend)

This module provides the local user view for Cognitive Suite:
- Streamlit UI: interactive exploration of `outputs/insights/analysis.json`
- TUI (Rich/Textual): terminal-first view for operators

## Quickstart (from repo root)

### Local (no Docker)

```bash
cd frontend
make ui-doctor
make ui-local
```

### Docker

```bash
cd frontend
make ui-build
make ui-up
```

The UI will be available at: http://localhost:8501

## Data source

By default, the UI reads:
- `../outputs/insights/analysis.json`

You can override the outputs directory using:
- `COGNITIVE_OUTPUTS=/path/to/outputs`
