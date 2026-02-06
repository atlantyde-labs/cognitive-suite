# 🧪 Ejecutar GitHub Actions en local con `act`

Cuando necesitas validar el flujo completo **sin desplegar en GitHub**, `act` es la forma más fiable de emular el runner oficial. Lo usamos aquí para probar:

- `.github/workflows/early-adopter-codeowner-approval.yml` (badge + badge ledger + ledger commits).  
- `.github/workflows/regulatory-xp-award.yml` (XP regulatorio + ledger + comentarios).  
- `.github/workflows/xp-decay-monthly.yml` y `scripts/apply-xp-decay.py`.  

## 1. Requisitos previos

1. Docker (o Podman) instalado y corriendo. `act` lanza contenedores para cada job.  
2. [act](https://github.com/nektos/act) disponible:  

   ```bash
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
   ```

3. Node/Python/local deps para el workflow:  

   ```bash
   python3.10 -m pip install -r requirements.txt
   ```

   Si el entorno no tiene acceso a PyPI, descarga manualmente los wheels necesarios y usa `pip install ./packages/...`.

## 2. Configurar secretos/locales

Crea un `.actrc` o pon los secretos en el comando. El workflow usa:

| Nombre | Descripción |
| --- | --- |
| `GITHUB_TOKEN` | token con permisos `contents`, `issues`, `pull_requests`, `projects`. |
| `CODEOWNERS_TOKEN` | PAT para leer membresías CODEOWNERS. |
| `PROJECT_TOKEN` | PAT para actualizar Project v2. |
| `PROJECT_URL` | URL del Project v2 (`https://github.com/orgs/…/projects/123`). |
| `PAYLOAD_PRIVATE_KEY` | (opcional) ruta/claves para firmar Open Badges. |

Ejemplo mínimo de `.actrc`:

```
-s GITHUB_TOKEN=ghp_localtoken
-s CODEOWNERS_TOKEN=ghp_localcodeowners
-s PROJECT_TOKEN=ghp_localproject
-s PROJECT_URL=https://github.com/orgs/atlantic-labs/projects/2
```

Si necesitas simular `github.event` (PR, etiquetas, review), usa `act` con `--eventpath` apuntando a un JSON que imite el payload (`tests/fixtures/pr-codeowner.json` por ejemplo).

## 3. Ejecutar los workflows

### early-adopter badge

```bash
./run-local-workflow.sh --job gamify-approval --event tests/fixtures/pull_request_review-approved.json
```

### Elegir modo de imagen

`run-local-workflow.sh` acepta la opción `--image-mode` y permite escoger la imagen de `act`. Actualmente:

- `act-latest` (default): `catthehacker/ubuntu:full-latest`.  
- `medium`: `nektos/act-environments-ubuntu:20.04` (ligera y recomendada; versiones más nuevas no siempre están disponibles).  
- `micro`: `node:20-alpine` (solo Node.js, puede fallar en acciones sin Node).  
- `custom`: usa `--image` con cualquier imagen válida.

Ejemplo medio:

```bash
./run-local-workflow.sh --job gamify-approval --event tests/fixtures/pull_request_review-approved.json --image-mode medium
```

También puedes forzar una imagen concreta:

```bash
./run-local-workflow.sh --job gamify-approval --image ghcr.io/my/local-act-image:latest
```

### regulatory XP award

```bash
act --secret-file .actrc \
    --eventpath tests/fixtures/pull_request-labeled.json \
    --job award-regulatory-xp \
    -W .github/workflows/regulatory-xp-award.yml
```

### XP decay mensual (trigger schedule)

`act` no puede ejecutar cron real, pero puedes forzar el job con `workflow_dispatch` o `workflow_call` que ya están disponibles:

```bash
act --secret-file .actrc --job apply-decay -W .github/workflows/xp-decay-monthly.yml
```

## 4. Verifica los cambios

- Los ledgers se actualizan en `metrics/users/*.json` y `credentials/users/…`.  
- Los commits/detached signatures quedan en el repo (`git status`).  
- Las credenciales firmadas se guardan en `credentials/users/<user>/`.  
- Los comments/labels se pueden simular leyendo la salida `act` (scroll `::notice::`).  

## 5. Tips

- Si un workflow necesita más secretos (ej. `PAYLOAD_PRIVATE_KEY`), añádelos a `.actrc` como `-s PAYLOAD_PRIVATE_KEY="$(cat secrets/private.key)"`.  
- Usa `act -l` para listar jobs disponibles.  
- Usa `--reuse` para evitar bajar imágenes repetidas y acelerar la iteración.

Con esta guía puedes replicar **el ciclo completo** del sistema de XP/roles/credenciales en tu máquina, revisar los ledgers y ajustar las configuraciones declarativas antes de abrir un PR real.
