# VSCode Development Tooling Setup - Guía Rápida

Se han agregado nuevas herramientas y extensiones de desarrollo a VSCode para mejorar la experiencia con **cognitive-suite**. Esta guía te ayudará a comenzar rápidamente.

## ✨ Qué se ha agregado

### Archivos de configuración creados en `.vscode/`:

1. **`.vscode/extensions.json`** - Lista de extensiones recomendadas
2. **`.vscode/settings.json`** - Configuración automática de formateo y linting
3. **`.vscode/tasks.json`** - Tareas automatizadas (12 tareas disponibles)
4. **`.vscode/keybindings.json`** - Atajos de teclado para tareas frecuentes
5. **`.vscode/workspace.code-workspace`** - Configuración del workspace

### Scripts y documentación:

1. **`dev/setup-vscode-env.sh`** - Script de configuración automática
2. **`docs/vscode-tooling-setup.md`** - Documentación completa

## 🚀 Configuración rápida (3 pasos)

### Paso 1: Instalar extensiones
```bash
# VSCode mostrará una notificación con "Extensiones recomendadas"
# O abre Extensions (Ctrl+Shift+X) y busca "Recomendadas"
# Haz clic en "Install All"
```

**Extensiones principales:**
- Python Pylance
- Ruff (formateador/linter Python)
- ShellCheck (linter bash)
- Shell Format (formateador bash)
- GitLens (historial de cambios)

### Paso 2: Configurar Python
```bash
cd /workspaces/cognitive-suite

# Crear virtualenv
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt
pip install ruff black pylint

# Si quieres docs
pip install -r requirements-docs.txt
```

### Paso 3: Instalar herramientas del sistema
```bash
# En Linux/Debian
sudo apt-get update
sudo apt-get install -y shellcheck shfmt

# En macOS
brew install shellcheck shfmt
```

## 📝 Tareas disponibles (Ctrl+Shift+P → "Run Task")

| Tarea | Descripción | Atajo |
|-------|-------------|-------|
| **Lint: Shell scripts** | Verifica errores bash | Ctrl+Shift+L |
| **Lint: Python files** | Verifica código Python | Ctrl+Shift+P |
| **Format: Shell scripts** | Formatea automáticamente bash | - |
| **Format: Python files** | Formatea automáticamente Python | Alt+Shift+F |
| **Test: E2E scripts** | Ejecuta pruebas E2E (dry-run) | Ctrl+Shift+T |
| **Validate: JSON schemas** | Valida JSONL contra esquemas | - |
| **Build: Docker images** | Valida Docker Compose | - |
| **Docs: Build MkDocs** | Construye documentación | - |
| **Dev: Bootstrap environment** | Inicializa el ambiente | - |
| **Run: Frontend Streamlit** | Lanza interfaz web | - |
| **Run: Pipeline analysis** | Ejecuta análisis pipeline | - |

## ⌨️ Atajos de teclado recomendados

Abre `.vscode/keybindings.json` para ver todos los atajos. Los principales:

- `Ctrl+Shift+L` - Lint Shell scripts
- `Ctrl+Shift+P` - Lint Python files
- `Ctrl+Shift+F` - Format Shell scripts
- `Alt+Shift+F` - Format Python files
- `Ctrl+Shift+T` - Run E2E Tests

## ⚙️ Características activadas automáticamente

### Al guardar archivos:
- ✅ Python: Formatea con ruff + organiza imports
- ✅ Shell: Formatea con shfmt
- ✅ YAML/JSON: Valida y formatea
- ✅ Elimina espacios en blanco al final
- ✅ Inserta salto de línea final automáticamente

### En la interfaz:
- ✅ Guías de línea en 80 y 120 caracteres
- ✅ Exclusión automática de `__pycache__`, `.git`
- ✅ Búsqueda smart (ignora archivos temporales)
- ✅ GitLens integrado (historial de líneas)

## 🔍 Validación de esquemas JSONL

El workspace soporta validación automática contra JSON schemas:

```bash
# Validar ClickOps bots
python3 bash/GitDevSecDataAIOps/tooling/forensics/validate-jsonl.py \
  --schema schemas/bot-clickops.schema.json \
  --input datasets/bot-clickops.example.jsonl

# Validar migraciones GitHub
python3 bash/GitDevSecDataAIOps/tooling/forensics/validate-jsonl.py \
  --schema schemas/github-migration-clickops.schema.json \
  --input datasets/github-migration-clickops.example.jsonl
```

## 🐛 Solucionar problemas

### Shellcheck no funciona
```bash
sudo apt-get install -y shellcheck
```

### Ruff no está disponible
```bash
source venv/bin/activate
pip install ruff
```

### Las tareas no aparecen
- Asegúrate de que `.vscode/tasks.json` existe
- Reinicia VSCode (F1 → Reload Window)

### Python formatter no se aplica
- Ve a Command Palette (Ctrl+Shift+P)
- Escribe "Python: Select Interpreter"
- Elige `./venv/bin/python`

## 📚 Documentación completa

Para más detalles sobre todas las configuraciones, consulta:
```
docs/vscode-tooling-setup.md
```

## 🎯 Próximos pasos

1. **Lee la documentación completa:**
   ```bash
   cat docs/vscode-tooling-setup.md
   ```

2. **Ejecuta una tarea de prueba:**
   - Abre Ctrl+Shift+P
   - Escribe "Run Task"
   - Selecciona "Lint: Shell scripts"

3. **Abre un archivo Python:**
   - Verifica que el formato automático funcione
   - Deberías ver cambios al guardar

4. **Prueba GitLens:**
   - Abre un archivo del proyecto
   - Haz clic en una línea para ver el historial
   - GitLens mostrará quién cambió esa línea

## 🔐 Seguridad y privacidad

- ✅ Todos los archivos `.vscode/` son públicos y seguros
- ✅ No incluyen tokens o secretos
- ✅ Se excluyen automáticamente archivos sensibles (`.env`, `.secrets`)
- ✅ Telemetría deshabilitada para herramientas de Red Hat

## ✅ Checklist de configuración

- [ ] He instalado las extensiones recomendadas
- [ ] He creado el virtualenv Python
- [ ] He instalado shellcheck y shfmt
- [ ] He seleccionado el interprete Python correcto
- [ ] He probado una tarea (Run Task)
- [ ] Veo que el formateo automático funciona
- [ ] GitLens muestra el historial de cambios

¡Listo! Tu ambiente de desarrollo está configurado. 🎉
