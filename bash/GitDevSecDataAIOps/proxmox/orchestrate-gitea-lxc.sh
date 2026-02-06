#!/usr/bin/env bash
set -euo pipefail

# orchestrate-gitea-lxc.sh
# Orquesta el despliegue completo de un contenedor Gitea LXC en Proxmox.
# 1. Genera los ficheros de secretos necesarios usando el wizard.
# 2. Despliega el LXC y configura Gitea usando el script de despliegue.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CS_ROOT="${SCRIPT_DIR}"
while [[ ! -f "${CS_ROOT}/lib/cs-common.sh" ]]; do
  if [[ "${CS_ROOT}" == "/" ]]; then
    echo "cs-common.sh not found" >&2
    exit 1
  fi
  CS_ROOT=$(dirname "${CS_ROOT}")
done
# shellcheck disable=SC1090,SC1091
source "${CS_ROOT}/lib/cs-common.sh"

CS_LOG_PREFIX="gitea-lxc-orchestrator"

CONFIG_PATH="${1:-}"
if [[ -z "${CONFIG_PATH}" || ! -f "${CONFIG_PATH}" ]]; then
  cs_die "Uso: $0 /ruta/a/tu/config.env"
fi

cs_log "Cargando configuración desde ${CONFIG_PATH}..."
# Carga la configuración del usuario
source "${CONFIG_PATH}"

# --- Paso 1: Generar los ficheros de secretos ---
cs_ui_step "Paso 1: Generando ficheros de secretos con el wizard"

# El wizard necesita su propio fichero de configuración. Lo creamos al vuelo.
WIZARD_CONFIG_PATH="${SECRETS_OUTPUT_DIR}/wizard.tmp.env"
mkdir -p "$(dirname "${WIZARD_CONFIG_PATH}")"
cat > "${WIZARD_CONFIG_PATH}" <<EOF
# Fichero de configuración temporal para el wizard
INTERACTIVE="false"
DRY_RUN="${DRY_RUN:-true}"
OUTPUT_DIR="${SECRETS_OUTPUT_DIR}"

# Secciones a escribir
WRITE_PVE_API_ENV="true"
WRITE_GITEA_ONBOARD_ENV="true"
WRITE_BOT_EVIDENCE_ENV="false" # Opcional, desactivado por defecto
RUN_CONTRIBUTOR_WIZARD="false"

# Valores para PVE
PVE_API_URL="${PVE_API_URL}"
PVE_API_TOKEN="${PVE_API_TOKEN}"
PVE_INSECURE="${PVE_INSECURE:-true}"
PVE_DRY_RUN="${DRY_RUN:-true}"

# Valores para Gitea Onboarding
GITEA_URL="${GITEA_URL}"
GITEA_TOKEN="${GITEA_TOKEN}"
GITEA_DRY_RUN="${DRY_RUN:-true}"
EOF

cs_log "Ejecutando proxmox-local-secrets-wizard.sh de forma no interactiva..."
if ! bash "${SCRIPT_DIR}/proxmox-local-secrets-wizard.sh" "${WIZARD_CONFIG_PATH}"; then
  cs_die "El wizard de secretos falló."
fi
cs_ui_ok "Ficheros de secretos generados en ${SECRETS_OUTPUT_DIR}"

# --- Paso 2: Desplegar el contenedor LXC de Gitea ---
cs_ui_step "Paso 2: Desplegando el contenedor Gitea LXC"

# El script de despliegue también necesita su fichero de configuración.
DEPLOY_CONFIG_PATH="${SECRETS_OUTPUT_DIR}/deploy-gitea.tmp.env"
# Reutilizamos la configuración principal y añadimos las rutas a los secretos generados.
cp "${CONFIG_PATH}" "${DEPLOY_CONFIG_PATH}"

cs_log "Ejecutando deploy-gitea-lxc-api.sh..."
# Asumimos que deploy-gitea-lxc-api.sh es el script principal.
if ! bash "${SCRIPT_DIR}/deploy-gitea-lxc-api.sh" "${DEPLOY_CONFIG_PATH}"; then
  cs_die "El despliegue del LXC de Gitea falló."
fi

cs_ui_ok "Orquestación de Gitea LXC completada."
cs_log "Puedes acceder a Gitea en: ${GITEA_URL}"
cs_log "La contraseña de root para el LXC ID ${LXC_ID} es: '${LXC_PASSWORD}'"
