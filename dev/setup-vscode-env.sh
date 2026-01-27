#!/usr/bin/env bash
set -euo pipefail

# VSCode Development Environment Setup Script
# Este script configura el ambiente local para usar las nuevas extensiones y herramientas

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

log() {
  echo "[vscode-setup] $*"
}

warn() {
  echo "[vscode-setup:WARN] $*" >&2
}

error() {
  echo "[vscode-setup:ERROR] $*" >&2
  exit 1
}

# Detectar sistema operativo
OS=$(uname -s)
case "${OS}" in
  Linux*)
    PACKAGE_MANAGER="apt-get"
    INSTALL_CMD="sudo apt-get install -y"
    ;;
  Darwin*)
    PACKAGE_MANAGER="brew"
    INSTALL_CMD="brew install"
    ;;
  *)
    warn "Sistema operativo no soportado: ${OS}"
    PACKAGE_MANAGER=""
    INSTALL_CMD=""
    ;;
esac

# Verificar si las herramientas están disponibles
check_tool() {
  local tool=$1
  if command -v "$tool" >/dev/null 2>&1; then
    log "✓ $tool está disponible"
    return 0
  else
    log "✗ $tool no está disponible"
    return 1
  fi
}

install_tool() {
  local tool=$1
  local pkg_name=${2:-$tool}

  if ! check_tool "$tool"; then
    if [[ -z "$INSTALL_CMD" ]]; then
      warn "No se puede instalar $tool automáticamente"
      return 1
    fi
    log "Instalando $pkg_name..."
    if $INSTALL_CMD "$pkg_name" >/dev/null 2>&1; then
      log "✓ $pkg_name instalado correctamente"
      return 0
    else
      warn "No se pudo instalar $pkg_name"
      return 1
    fi
  fi
}

# Función principal
setup_vscode_env() {
  log "Iniciando configuración de VSCode para cognitive-suite..."

  # 1. Verificar Python
  log "Verificando Python..."
  if ! check_tool python3; then
    error "Python 3 no está disponible"
  fi

  PYTHON_VERSION=$(python3 --version | awk '{print $2}')
  log "Python version: $PYTHON_VERSION"

  # 2. Crear virtualenv
  log "Creando virtualenv..."
  if [[ ! -d "$PROJECT_ROOT/venv" ]]; then
    python3 -m venv "$PROJECT_ROOT/venv"
    log "✓ Virtualenv creado"
  else
    log "✓ Virtualenv ya existe"
  fi

  # 3. Instalar herramientas de desarrollo
  log "Instalando herramientas de linting y formato..."

  install_tool "shellcheck"
  install_tool "shfmt"

  # Pip packages
  log "Instalando paquetes Python..."
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/venv/bin/activate"

  # Instalar ruff, pylance deps, etc
  pip install --quiet --upgrade pip
  pip install --quiet ruff black pylint

  if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
    pip install --quiet -r "$PROJECT_ROOT/requirements.txt"
    log "✓ Requisitos instalados"
  fi

  if [[ -f "$PROJECT_ROOT/requirements-docs.txt" ]]; then
    pip install --quiet -r "$PROJECT_ROOT/requirements-docs.txt"
    log "✓ Requisitos de docs instalados"
  fi

  deactivate 2>/dev/null || true

  # 4. Crear archivos de configuración si no existen
  log "Configurando VSCode..."

  if [[ ! -d "$PROJECT_ROOT/.vscode" ]]; then
    mkdir -p "$PROJECT_ROOT/.vscode"
  fi

  # Las configuraciones ya existen por create_file
  if [[ -f "$PROJECT_ROOT/.vscode/settings.json" ]]; then
    log "✓ settings.json configurado"
  fi

  if [[ -f "$PROJECT_ROOT/.vscode/extensions.json" ]]; then
    log "✓ extensions.json configurado"
  fi

  if [[ -f "$PROJECT_ROOT/.vscode/tasks.json" ]]; then
    log "✓ tasks.json configurado"
  fi

  # 5. Crear archivo de configuración local (opcional)
  if [[ ! -f "$PROJECT_ROOT/.env.local" ]]; then
    log "Creando .env.local de ejemplo..."
    cat > "$PROJECT_ROOT/.env.local.example" <<'EOF'
# VSCode Development Configuration
VSCODE_PYTHON_PATH="${PROJECT_ROOT}/venv/bin/python"
VSCODE_SHELLCHECK_ENABLE=true
VSCODE_RUFF_ENABLE=true

# Shell configuration
SHELL_FORMATTER="shfmt"
SHELL_FORMATTER_ARGS="-i 2 -bn -ci"

# Python configuration
PYTHON_FORMATTER="ruff"
PYTHON_LINTER="ruff"
EOF
    log "✓ .env.local.example creado"
  fi

  # 6. Crear script helper para activar venv
  log "Creando scripts helper..."
  cat > "$PROJECT_ROOT/.vscode/venv-activate.sh" <<'EOF'
#!/usr/bin/env bash
# Helper script para activar el virtualenv en VSCode
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/venv/bin/activate"
EOF
  chmod +x "$PROJECT_ROOT/.vscode/venv-activate.sh"
  log "✓ venv-activate.sh creado"

  # 7. Validar configuración
  log "Validando configuración..."

  # Test shell linting
  if check_tool shellcheck; then
    log "✓ Shell linting disponible"
  fi

  # Test python tools
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/venv/bin/activate"
  if python3 -m ruff --version >/dev/null 2>&1; then
    log "✓ Python formatter (ruff) disponible"
  fi
  deactivate 2>/dev/null || true

  # 8. Resumen final
  log ""
  log "=========================================="
  log "✓ Configuración completada exitosamente"
  log "=========================================="
  log ""
  log "Próximos pasos:"
  log "1. Abre VSCode en: $PROJECT_ROOT"
  log "2. Instala las extensiones recomendadas:"
  log "   - Ve a Extensions (Ctrl+Shift+X)"
  log "   - Busca 'Recomendadas'"
  log "   - Haz clic en 'Install All'"
  log ""
  log "3. Verifica que Python use el venv:"
  log "   - Abre la paleta de comandos (Ctrl+Shift+P)"
  log "   - Escribe: 'Python: Select Interpreter'"
  log "   - Elige: ./venv/bin/python"
  log ""
  log "4. Prueba las tareas disponibles:"
  log "   - Ctrl+Shift+P → 'Run Task'"
  log "   - Busca: 'Lint: Shell scripts'"
  log ""
}

# Ejecutar
setup_vscode_env
