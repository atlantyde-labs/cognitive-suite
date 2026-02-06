#!/usr/bin/env bash
set -euo pipefail

# create-cloud-template.sh
# Automatiza la creación de plantillas Cloud-Init en Proxmox 8.4
# Referencia: https://gist.github.com/acj/3cb5674670e6145fa4f355b3239165c7
#
# Características:
# - Descarga imágenes oficiales (Ubuntu/Debian).
# - Inyecta qemu-guest-agent usando virt-customize (CRÍTICO para Proxmox).
# - Configura hardware optimizado (VirtIO SCSI, Serial Console).

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CS_ROOT="${SCRIPT_DIR}"
while [[ ! -f "${CS_ROOT}/lib/cs-common.sh" ]]; do
  if [[ "${CS_ROOT}" == "/" ]]; then
    # Fallback si no se encuentra la librería común
    break
  fi
  CS_ROOT=$(dirname "${CS_ROOT}")
done

if [[ -f "${CS_ROOT}/lib/cs-common.sh" ]]; then
  # shellcheck disable=SC1090,SC1091
  source "${CS_ROOT}/lib/cs-common.sh"
else
  # Funciones dummy si no existe la librería
  cs_log() { echo "[INFO] $*"; }
  cs_die() { echo "[ERROR] $*" >&2; exit 1; }
fi

# Cargar configuración opcional
CONFIG_PATH="${1:-}"
if [[ -n "${CONFIG_PATH}" && -f "${CONFIG_PATH}" ]]; then
    cs_log "Cargando configuración de ${CONFIG_PATH}"
    # shellcheck disable=SC1090
    source "${CONFIG_PATH}"
fi

# Valores por defecto
VMID=${VMID:-9000}
CODENAME=${CODENAME:-"noble"} # noble (24.04), jammy (22.04), bookworm (Debian 12)
STORAGE=${STORAGE:-"local-lvm"}
MEMORY=${MEMORY:-2048}
CORES=${CORES:-2}
BRIDGE=${BRIDGE:-"vmbr0"}

# URLs de imágenes Cloud oficiales
declare -A IMAGE_URLS
IMAGE_URLS["noble"]="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMAGE_URLS["jammy"]="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_URLS["bookworm"]="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"

if [[ -z "${IMAGE_URLS[$CODENAME]+x}" ]]; then
    cs_die "Codename '$CODENAME' no soportado. Usa: noble, jammy, bookworm."
fi

URL="${IMAGE_URLS[$CODENAME]}"
IMG_NAME="/tmp/$(basename "$URL")"

# 1. Verificar dependencias
if ! command -v virt-customize &> /dev/null; then
    cs_log "Instalando libguestfs-tools (necesario para inyectar agente)..."
    apt-get update && apt-get install -y libguestfs-tools
fi

# 2. Descargar imagen
if [[ ! -f "$IMG_NAME" ]]; then
    cs_log "Descargando imagen base ($CODENAME)..."
    wget -q --show-progress "$URL" -O "$IMG_NAME"
else
    cs_log "Usando imagen en caché: $IMG_NAME"
fi

# 3. Personalizar imagen (Inyectar QEMU Agent)
# Esto es vital para que Proxmox vea la IP y gestione el apagado.
cs_log "Inyectando qemu-guest-agent..."
virt-customize -a "$IMG_NAME" --install qemu-guest-agent --truncate "/etc/machine-id"

# 4. Limpieza previa
if qm status "$VMID" &> /dev/null; then
    cs_log "Eliminando VM existente ID $VMID..."
    qm stop "$VMID" && qm destroy "$VMID" --purge
fi

# 5. Crear VM
cs_log "Creando VM $VMID ($CODENAME-cloud)..."
qm create "$VMID" --name "$CODENAME-cloud" --memory "$MEMORY" --cores "$CORES" --net0 "virtio,bridge=$BRIDGE"

# 6. Importar y conectar disco
cs_log "Importando disco a $STORAGE..."
qm importdisk "$VMID" "$IMG_NAME" "$STORAGE"

# Configuración hardware Proxmox 8.x (VirtIO SCSI Single)
DISK_PATH="$STORAGE:vm-$VMID-disk-0"
qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$DISK_PATH"

# 7. Configurar Cloud-Init
cs_log "Configurando Cloud-Init y Boot..."
qm set "$VMID" --ide2 "$STORAGE:cloudinit"
qm set "$VMID" --boot c --bootdisk scsi0
qm set "$VMID" --serial0 socket --vga serial0 # Consola serie para logs
qm set "$VMID" --agent enabled=1 # Habilitar integración con QEMU Agent

# 8. Convertir a plantilla
cs_log "Convirtiendo a plantilla..."
qm template "$VMID"

cs_log "✅ Plantilla $VMID creada. Lista para clonar."
