# Fine-tune local-first

Este paquete valida JSONL (ChatML/messages o prompt/completion), separa por sensibilidad y convierte a prompt/completion.

## Validar dataset

```bash
python3 bash/GitDevSecDataAIOps/tooling/fine-tune/ft_prepare.py datasets/atlantityqa_cognitive_suite_ft_v2.jsonl --validate-only
```

## Separar por sensibilidad (PUBLIC/INTERNAL/PRIVATE/SECRET)

```bash
python3 bash/GitDevSecDataAIOps/tooling/fine-tune/ft_prepare.py datasets/atlantityqa_cognitive_suite_ft_v2.jsonl \
  --split-by-sensitivity --out-dir outputs
```

## Convertir a prompt/completion (solo datasets permitidos)

```bash
python3 bash/GitDevSecDataAIOps/tooling/fine-tune/ft_prepare.py outputs/atlantityqa_cognitive_suite_ft_v2.jsonl.PUBLIC.jsonl \
  --to-prompt --out-dir outputs
```

## Recomendaciones

- No mezclar SECRET con datasets para modelos compartidos.
- Ejecutar en runner self-hosted local.
- No subir artifacts si el dataset es sensible.
