#!/bin/bash
#
# Script para desplegar Cognitive Suite en un entorno local (como una VM en Proxmox).
# Diseñado para ser ejecutado en una VM con Ubuntu Server.
#
set -e

# --- Configuración ---
# URL del repositorio Git. Modifícala si es necesario.
GIT_REPO_URL="https://github.com/atlantyde-labs/cognitive-suite.git"
PROJECT_DIR="cognitive-suite"
# ---------------------

# --- Verificación de Seguridad ---
# No ejecutar este script desde un directorio con el mismo nombre que el proyecto.
if [[ "$(basename "$(pwd)")" == "$PROJECT_DIR" ]]; then
    echo "ERROR: Este script no debe ejecutarse desde un directorio llamado '$PROJECT_DIR'." >&2
    echo "Por favor, ejecútalo desde tu directorio home (~/ o /root) o un nivel superior." >&2
    exit 1
fi

echo "### Paso 1: Actualizando el sistema e instalando dependencias... ###"
sudo apt-get update
sudo apt-get install -y docker.io docker-compose git

echo
echo "### Paso 2: Configurando los permisos de Docker... ###"
# Añade el usuario actual al grupo de Docker para evitar usar 'sudo' constantemente.
sudo usermod -aG docker ${USER}
echo "-> Permisos de Docker configurados."
echo "   AVISO: Debes cerrar sesión y volver a iniciarla para usar 'docker' sin 'sudo'."
echo "   Para este script, usaremos 'sudo' por seguridad."
echo

echo "### Paso 3: Clonando o actualizando el repositorio del proyecto... ###"
if [ -d "$PROJECT_DIR" ]; then
    echo "-> El directorio '$PROJECT_DIR' ya existe. Actualizando con 'git pull'..."
    cd "$PROJECT_DIR"
    git pull
else
    echo "-> Clonando el repositorio desde $GIT_REPO_URL..."
    git clone "$GIT_REPO_URL" "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi
echo "-> Directorio de trabajo: $(pwd)"
echo

echo "### Paso 4: Preparando el archivo de configuración de entorno... ###"
if [ -f ".env.local" ]; then
    echo "-> '.env.local' ya existe. No se realizarán cambios."
else
    if [ -f ".env.local.example" ]; then
        echo "-> Creando '.env.local' a partir del archivo de ejemplo."
        cp .env.local.example .env.local
    else
        echo "-> ATENCIÓN: No se encontró '.env.local.example'. Se creará un archivo '.env.local' vacío."
        echo "-> Deberás configurarlo manualmente."
        touch .env.local
    fi
fi
echo

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! ACCIÓN REQUERIDA: Revisa y edita el archivo '.env.local'.      !!!"
echo "!!!                                                                !!!"
echo "!!! Es posible que necesites ajustar puertos, credenciales u otras !!!"
echo "!!! variables de entorno para tu configuración local.              !!!"
echo "!!! Abre otra terminal y edita el archivo: nano .env.local         !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
read -p "Presiona [Enter] después de revisar el archivo para continuar..."
echo

echo "### Paso 5: Lanzando la aplicación con Docker Compose... ###"
echo "-> Esto puede tardar varios minutos mientras se construyen las imágenes de Docker..."
sudo docker-compose -f docker-compose.local-demo.yml up --build -d
echo

echo "✅✅✅ ¡Despliegue completado con éxito! ✅✅✅"
echo
echo "La Cognitive Suite se está ejecutando en segundo plano."
echo
echo "--- Comandos útiles ---"
echo "Para verificar el estado de los contenedores:"
echo "  sudo docker-compose -f docker-compose.local-demo.yml ps"
echo
echo "Para ver los logs en tiempo real:"
echo "  sudo docker-compose -f docker-compose.local-demo.yml logs -f"
echo
echo "Para detener la aplicación:"
echo "  sudo docker-compose -f docker-compose.local-demo.yml down"
echo