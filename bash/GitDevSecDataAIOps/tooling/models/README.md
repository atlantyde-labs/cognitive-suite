# Model inventory (local-first)

Detecta artefactos de fine-tune y mapas (vector indexes), genera inventario JSON y reporta violaciones.

## Config

```bash
cp bash/GitDevSecDataAIOps/tooling/models/model-inventory.env.example model-inventory.env
```

## Ejecutar

```bash
bash bash/GitDevSecDataAIOps/tooling/models/run-model-inventory.sh model-inventory.env
```

## Resultado

- `outputs/model-inventory.json`
- `outputs/model-whitelist.json` (permitidos)
- `outputs/model-alerts.json` (violaciones + acciones)

## Quarantine

- `ALLOWED_SECRET_ROOTS`: rutas permitidas para artefactos SECRET.
- `QUARANTINE_MODE=copy|move`: copia o mueve artefactos SECRET fuera de ruta permitida al `VAULT_DIR`.
- `PRESERVE_PATHS=true`: preserva estructura de carpetas al mover/copiar.
- `DRY_RUN=true`: no toca ficheros, solo reporta.
