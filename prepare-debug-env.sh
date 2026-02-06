#!/usr/bin/env bash
set -euo pipefail

# prepare-debug-env.sh
# Script de utilidad para configurar un entorno de depuración local
# Soluciona los errores de "Missing env file" y permite ejecución paso a paso.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "${SCRIPT_DIR}"

echo "🔧 Configurando entorno de depuración en: ${SCRIPT_DIR}"

# 1. Generar deploy-all-secret-suite.env (Requerido por bootstrap.sh)
if [[ ! -f "deploy-all-secret-suite.env" ]]; then
    echo "-> Generando deploy-all-secret-suite.env (DRY_RUN=true)"
    cp deploy-all-secret-suite.env.example deploy-all-secret-suite.env
    cp bash/GitDevSecDataAIOps/proxmox/deploy-all-secret-suite.env.example deploy-all-secret-suite.env
    # Asegurar DRY_RUN=true para seguridad
    if grep -q "DRY_RUN=" deploy-all-secret-suite.env; then
        sed -i 's/DRY_RUN=.*/DRY_RUN=true/' deploy-all-secret-suite.env
    else
        echo "DRY_RUN=true" >> deploy-all-secret-suite.env
    fi
else
    echo "-> deploy-all-secret-suite.env ya existe (saltado)"
fi

# 2. Generar proxmox-local-secrets-wizard.env (Para ejecución no interactiva)
if [[ ! -f "proxmox-local-secrets-wizard.env" ]]; then
    echo "-> Generando proxmox-local-secrets-wizard.env (DRY_RUN=true, Non-Interactive)"
    cp bash/proxmox/proxmox-local-secrets-wizard.env.example proxmox-local-secrets-wizard.env
    cp bash/GitDevSecDataAIOps/proxmox/proxmox-local-secrets-wizard.env.example proxmox-local-secrets-wizard.env


    # Configuración segura para debug local
    {
        echo ""
        echo "# DEBUG OVERRIDES"
        echo "DRY_RUN=true"
        echo "INTERACTIVE=false"
        echo "OUTPUT_DIR=./outputs/secrets"
        # Valores dummy para pasar validaciones
        echo "PVE_API_URL=https://127.0.0.1:8006/api2/json"
        echo "PVE_API_TOKEN=${PVE_API_TOKEN}"
    } >> proxmox-local-secrets-wizard.env
else
    echo "-> proxmox-local-secrets-wizard.env ya existe (saltado)"
fi

# 3. Crear directorios de salida locales para evitar errores de permisos
mkdir -p outputs/secrets

echo "✅ Entorno preparado."
echo ""
echo "📋 INSTRUCCIONES PARA MODO DEBUGGER (Paso a paso):"
echo ""
echo "1. Ejecuta el wizard paso a paso:"
echo "   bash -x ./proxmox-local-secrets-wizard.sh ./proxmox-local-secrets-wizard.env"
echo ""
echo "2. Ejecuta el bootstrap paso a paso:"
echo "   bash -x ./bootstrap.sh"
