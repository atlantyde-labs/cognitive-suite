# Knowledge Pack (Cognitive Suite)

Este directorio estandariza **colecciones/diccionarios** para auditar y explotar:
- Interacciones (user/assistant)
- Fuentes (zips, logs, URLs, workflows, PRs/Issues)
- Artefactos (archivos generados/patches/config)
- Actividad (eventos operativos CI/CD)
- Decisiones (tipo ADR)
- Taxonomías (labels/fields/métricas)

## Formato recomendado
- **JSONL** para datasets (append-only, Git-friendly)
- **JSON Schema** para validar contratos

## Contratos UAT para base de conocimiento unica
- `knowledge/contracts/view-contracts.yml`: contrato de vistas publicas (secciones, enlaces y bindings taxonomicos).
- `knowledge/datasets/taxonomy.ontology.yml`: modelo taxonomico-ontologico operativo.
- `knowledge/schemas/view_contract.schema.json`: contrato estructural de vistas.
- `knowledge/schemas/taxonomy_ontology.schema.json`: contrato estructural de ontologia.

Validacion recomendada:
- `python3 scripts/validate-knowledge.py`
- `python3 scripts/validate-knowledge-uat.py`
- `python3 scripts/validate-stakeholder-intake.py`
