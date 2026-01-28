#!/bin/bash
set -euo pipefail

# --- Configurables ---
# URL del repositorio Git a clonar
REPO_URL="https://github.com/atlantyde-labs/cognitive-suite.git"
# Rama a utilizar. Se puede pasar como primer argumento al script. Si no, usa 'main' por defecto.
BRANCH="${1:-main}"
# Nombre del directorio del proyecto
PROJECT_DIR="cognitive-suite"

# --- Colores para los logs ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Funciones de Logging ---
log_info() {
    echo -e "${GREEN}### $1 ###${NC}"
}

log_warn() {
    echo -e "${YELLOW}AVISO: $1${NC}"
}

log_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# --- Inicio del Script ---
log_info "Paso 1: Actualizando el sistema e instalando dependencias..."
if ! command -v apt-get &> /dev/null; then
    log_error "Este script requiere 'apt-get' y está diseñado para sistemas Debian/Ubuntu."
fi
sudo apt-get update
sudo apt-get install -y git docker.io docker-compose

log_info "Paso 2: Configurando los permisos de Docker..."
if ! getent group docker >/dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker "$USER" || true
log_warn "Debes cerrar sesión y volver a iniciarla para usar 'docker' sin 'sudo'."
echo "Para este script, usaremos 'sudo' por seguridad."

log_info "Paso 3: Clonando o actualizando el repositorio del proyecto..."
if [ -d "$PROJECT_DIR" ]; then
    echo "-> El directorio '$PROJECT_DIR' ya existe. Actualizando el repositorio..."
    cd "$PROJECT_DIR"
    git fetch origin
    git checkout main # Cambia a main para evitar problemas de pull
    git pull origin main
    
    echo "-> Cambiando a la rama '$BRANCH'..."
    if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
        git checkout "$BRANCH"
        git pull origin "$BRANCH" --rebase
    else
        git checkout -b "$BRANCH" "origin/$BRANCH"
    fi
    cd ..
else
    echo "-> Clonando el repositorio desde $REPO_URL en la rama $BRANCH..."
    git clone --branch "$BRANCH" "$REPO_URL" "$PROJECT_DIR"
fi

if [ ! -d "$PROJECT_DIR" ]; then
    log_error "No se pudo clonar o encontrar el directorio del proyecto '$PROJECT_DIR'. Abortando."
fi

cd "$PROJECT_DIR"
echo "-> Directorio de trabajo: $(pwd)"

log_info "Paso 4: Preparando el archivo de configuración de entorno..."
if [ ! -f ".env.local.example" ]; then
    log_error "No se encuentra el archivo de ejemplo '.env.local.example'. Asegúrate de que la rama '$BRANCH' es correcta y el repo está completo."
fi
echo "-> Creando '.env.local' a partir del archivo de ejemplo."
cp .env.local.example .env.local

log_info "Paso 5: Levantando los servicios con Docker Compose..."
echo "-> Usando el fichero docker-compose.local-demo.yml para el despliegue."

# Comprobar si docker-compose v1 o v2 está disponible
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker compose &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    log_error "No se encontró ni 'docker-compose' (v1) ni 'docker compose' (v2). Por favor, instala uno de los dos."
fi

sudo $COMPOSE_CMD -f docker-compose.local-demo.yml up --build -d

echo ""
log_info "¡Despliegue local completado!"
log_warn "Los servicios están corriendo en segundo plano."
echo "-> Para ver los logs, ejecuta: 'sudo $COMPOSE_CMD -f docker-compose.local-demo.yml logs -f'"
echo "-> Para detener los servicios, ejecuta: 'sudo $COMPOSE_CMD -f docker-compose.local-demo.yml down'"

