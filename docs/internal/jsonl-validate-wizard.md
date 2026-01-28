# JSONL Validation Wizard

Wizard interactivo para validar JSONL semanticos contra schemas.

## Ejecutar

```bash
bash bash/GitDevSecDataAIOps/tooling/bots/jsonl-validate-wizard.sh
```

## Modo no interactivo

```bash
INPUT_PATH=outputs \
AUTO_SCHEMA=true \
INTERACTIVE=false \
OUTPUT_FILE=outputs/jsonl-validate-summary.json \
bash bash/GitDevSecDataAIOps/tooling/bots/jsonl-validate-wizard.sh
```

## Auto schema
- `bot-*` → `schemas/bot-clickops.schema.json`
- `github-migration*` → `schemas/github-migration-clickops.schema.json`
