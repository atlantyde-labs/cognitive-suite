# Model inventory (local-first)

Detecta artefactos de fine-tune y mapas (vector indexes) y genera un inventario JSON con hashes.

## Config

```bash
cp bash/GitDevSecDataAIOps/tooling/models/model-inventory.env.example model-inventory.env
```

## Ejecutar

```bash
bash bash/GitDevSecDataAIOps/tooling/models/run-model-inventory.sh model-inventory.env
```

## Salida

- `outputs/model-inventory.json`
- Incluye `sensitivity=SECRET` por defecto para fine-tune y mapas.
