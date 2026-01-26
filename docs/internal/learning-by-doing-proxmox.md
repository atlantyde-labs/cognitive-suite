# Learning by Doing: Started-Kit Deployments CLI Ops (Proxmox single node)

> Objetivo: clonar la rama operativa, ejecutar el bootstrap seguro en **dry-run** y preparar el despliegue local con máxima privacidad.

## 0) Requisitos en el nodo Proxmox

- Usuario operativo: `kabehz`
- `git` y `gh` instalados (opcional, se puede usar `git` directo)
- Acceso a Internet solo para clonar/pull (si `LOCAL_FIRST=true`, bloqueará endpoints externos no permitidos)

## 1) Crear el archivo `/tmp/started-kit.env` (rutas locales con placeholders)

```bash
cat <<'ENV' > /tmp/started-kit.env
REPO_URL="https://github.com/atlantyde-labs/cognitive-suite.git"
BRANCH="chore/scripts-testing"
DEST_DIR="$HOME/cognitive-suite"
USE_GH="true"
RUN_BOOTSTRAP="true"

BOOTSTRAP_ENV="$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/bootstrap.env"
BOOTSTRAP_PATH="$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/bootstrap.sh"
ENV
```

> Si no quieres usar `gh`, pon `USE_GH="false"`.

## 2) Preparar `$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/bootstrap.env`

Si aún no existe, el starter lo creará desde `bootstrap.env.example`. Ajusta con estos valores seguros:

```bash
cat <<'ENV' > "$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/bootstrap.env"
REPO_DIR="$HOME/cognitive-suite"
SUITE_ENV="$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/deploy-all-secret-suite.env"

COPY_EXAMPLES="true"
FIX_PERMS="true"
CHECK_PLACEHOLDERS="true"
ALLOW_PLACEHOLDERS="false"

# Solo si de verdad vas a tocar endpoints externos
ALLOW_EXTERNAL_CONFIRM=""

# APPLY por defecto en false: dry-run seguro
APPLY="false"
CONFIRM_APPLY=""
ENV
```

## 3) Ejecutar el starter (pull + bootstrap)

```bash
bash "$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/started-kit-deployments-cli-ops.sh" /tmp/started-kit.env
```

Esto:
- Hace `clone` o `pull` de la rama
- Ejecuta `bootstrap.sh` en **dry‑run** (no aplica cambios)
- Lanza lint y validaciones locales

## 3b) Variante air‑gap (sin pull remoto)

Si no quieres acceso externo, copia el repo en un USB o ruta local y usa:

```bash
cat <<'ENV' > /tmp/started-kit-airgap.env
SOURCE_DIR="/media/usb/cognitive-suite"
DEST_DIR="$HOME/cognitive-suite"
RUN_BOOTSTRAP="true"

BOOTSTRAP_ENV="$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/bootstrap.env"
BOOTSTRAP_PATH="$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/bootstrap.sh"

SYNC_MODE="rsync"
RSYNC_ARGS="-a --delete"
ENV
```

```bash
bash "$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/started-kit-airgap.sh" /tmp/started-kit-airgap.env
```

## 4) Ajustar el orquestador (API + SSH)

En `deploy-all-secret-suite.env` (puedes usar placeholders locales):

```bash
API_ONLY="true"
GITEA_LXC_API_ENV="bash/GitDevSecDataAIOps/proxmox/deploy-gitea-lxc-api.env"
RUN_DEPLOY_GITEA="true"
RUN_REBOOT_GUARD="true"
```

En `deploy-gitea-lxc-api.env`:

```bash
BOOTSTRAP_SSH="true"
# Si usas DHCP, define el host manualmente (placeholder)
BOOTSTRAP_SSH_HOST="<IP_DEL_LXC>"
BOOTSTRAP_SSH_USER="root"
BOOTSTRAP_SSH_PORT="22"
BOOTSTRAP_SSH_KEY="$HOME/.ssh/id_rsa"
```

Opcional: obtener atributos locales automáticamente al cargar el env (si lo deseas):

```bash
GITEA_DOMAIN="$(hostname -f)"
```

## 5) Ejecutar en modo APPLY (solo cuando todo esté validado)

```bash
APPLY=true CONFIRM_APPLY=YES \
  bash "$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/bootstrap.sh" \
  "$HOME/cognitive-suite/bash/GitDevSecDataAIOps/proxmox/bootstrap.env"
```

## 6) Ventana de reinicio controlada (si hace falta)

Permitir reinicio temporal:

```bash
sudo bash "$HOME/cognitive-suite/bash/GitDevSecDataAIOps/platforms/ops-systems/allow-reboot-now.sh"
```

Cerrar ventana manualmente:

```bash
sudo bash "$HOME/cognitive-suite/bash/GitDevSecDataAIOps/platforms/ops-systems/close-reboot-override.sh"
```

Consultar estado:

```bash
sudo bash "$HOME/cognitive-suite/bash/GitDevSecDataAIOps/platforms/ops-systems/reboot-guard-status.sh"
```

---

## Checklist rápida (Learning by Doing)

1) Crear `/tmp/started-kit.env`.
2) Ejecutar starter y validar dry‑run.
3) Configurar `deploy-all-secret-suite.env` y `deploy-gitea-lxc-api.env`.
4) Habilitar `APPLY=true` solo cuando los gates estén OK.
5) Activar `RUN_REBOOT_GUARD=true` para evitar reinicios no controlados.

Si necesitas una variante “air‑gap” (sin pull directo), lo preparo.
