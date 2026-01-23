# 🧠 Knowledge Portal

Este portal consolida **actividad, fuentes, decisiones y taxonomías** para operar Cognitive Suite como producto enterprise.

## Qué hay aquí
- `knowledge/schemas/` → contratos (JSON Schema)
- `knowledge/datasets/` → colecciones (JSONL/YAML)

## Cómo usarlo (local-first)
1) Edita/añade líneas a los `.jsonl` (append-only).
2) En CI puedes validar con `jsonschema` (opcional).
3) Para indexación (RAG), usa los `.jsonl` como base de embeddings.

## Taxonomías clave
- Labels: domains/skills/compute/levels/roles/gamification
- Project v2 fields: Area, Skill, Compute, Level, Role, Status + XP

## Fuentes
Mete aquí los enlaces a:
- runs de Actions
- zips/patches
- docs/decisiones
- PRs/Issues relevantes
