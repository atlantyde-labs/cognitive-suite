# Cognitive Suite – Local User View (Frontend)

Este bundle añade la **vista de usuario local** (Streamlit) para explorar `outputs/insights/analysis.json`.

## Quickstart (Docker)

```bash
make ui-build
make ui-up
```

Abre `http://localhost:8501`.

## Quickstart (Local)

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
make ui-local
```

## Outputs

Por defecto la UI busca:

- `outputs/insights/analysis.json`

Puedes redefinir la raíz con:

- `COGNITIVE_OUTPUTS=/ruta/a/outputs`

## Documentación

- `docs/user-view/local-ui.md`
