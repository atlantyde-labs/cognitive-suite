# ✅ Checklist de Configuración de Herramientas VSCode

Esta es tu guía paso a paso para activar todas las nuevas herramientas de desarrollo.

## 📌 Fase 1: Instalación de Extensiones (5 min)

- [ ] Abre VSCode en `/workspaces/cognitive-suite`
- [ ] Abre Extensions: `Ctrl+Shift+X`
- [ ] Busca: `@recommended` en la barra de búsqueda
- [ ] Debería aparecer: "Recommended" con varias extensiones
- [ ] Haz clic en el icono de nube o "Install All"
- [ ] Espera a que todas las extensiones se instalen (2-3 min)
- [ ] Reinicia VSCode si se sugiere

**Extensiones a instalar (12):**
- [ ] Python
- [ ] Pylance
- [ ] Ruff
- [ ] ShellCheck
- [ ] Shell Format
- [ ] YAML (Red Hat)
- [ ] GitLens
- [ ] GitHub Actions
- [ ] Docker
- [ ] Makefile Tools
- [ ] TODO Tree
- [ ] Remote Containers (opcional)

## 🐍 Fase 2: Configurar Python (5 min)

Abre Terminal integrado: `Ctrl+`` (backtick)

```bash
# 1. Crear virtualenv
python3 -m venv venv

# 2. Activar
source venv/bin/activate

# 3. Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt
pip install ruff black pylint

# 4. Instalar docs (opcional)
pip install -r requirements-docs.txt

# 5. Salir del venv por ahora
deactivate
```

**Checklist:**
- [ ] Virtualenv creado: `ls venv` (existe carpeta)
- [ ] pip actualizado sin errores
- [ ] requirements.txt instalado sin errores
- [ ] ruff instalado: `venv/bin/ruff --version`

## 🐚 Fase 3: Instalar herramientas del sistema (3 min)

En terminal (puede requerir sudo):

```bash
# Linux/Debian
sudo apt-get update
sudo apt-get install -y shellcheck shfmt

# macOS (si tienes brew)
brew install shellcheck shfmt

# Verificar
shellcheck --version
shfmt --version
```

**Checklist:**
- [ ] shellcheck instalado
- [ ] shfmt instalado
- [ ] Versiones mostradas sin errores

## 🎯 Fase 4: Seleccionar interprete Python (2 min)

En VSCode:

1. `Ctrl+Shift+P` (Command Palette)
2. Escribe: `Python: Select Interpreter`
3. Elige: `./venv/bin/python` (mostrará algo como ".\venv\bin\python")
4. Verifica en la barra inferior derecha que dice "Python 3.X.X (venv)"

**Checklist:**
- [ ] Interprete Python seleccionado
- [ ] Barra inferior muestra "(venv)"
- [ ] No hay advertencia de entorno

## ⌨️ Fase 5: Probar atajos de teclado (2 min)

En VSCode con un archivo Python abierto:

1. `Ctrl+Shift+P` → `Run Task` → `Lint: Python files`
   - [ ] Verifica que shellcheck/ruff se ejecute

2. `Ctrl+Shift+P` → `Run Task` → `Format: Python files`
   - [ ] Verifica que el código se formatea

3. Abre un archivo `.sh` y prueba:
   - [ ] `Ctrl+Shift+P` → `Run Task` → `Lint: Shell scripts`

## 🔧 Fase 6: Verificar formateo automático (2 min)

1. Abre un archivo Python: `pipeline/analyze.py` (o similar)
2. Introduce algún error deliberado (espacios extras, imports desordenados)
3. Guarda el archivo: `Ctrl+S`
4. Verifica que el archivo se formatea automáticamente

**Debe suceder automáticamente:**
- [ ] Python: Formatea con ruff
- [ ] Shell: Formatea con shfmt
- [ ] YAML: Valida y formatea
- [ ] Se elimina trailing whitespace

## 📊 Fase 7: Probar GitLens (1 min)

1. Abre un archivo del proyecto: `pipeline/analyze.py`
2. Haz clic en una línea de código
3. Deberías ver en la parte superior: "Blame: ..." con autor y fecha

**Checklist:**
- [ ] GitLens muestra autoría de líneas
- [ ] Puedes ver el commit del cambio
- [ ] Puedes hacer click para ver detalles

## 📚 Fase 8: Explorar Tareas (2 min)

`Ctrl+Shift+P` → `Tasks: Run Task` y explora:

- [ ] `Lint: Shell scripts` - Verifica bash
- [ ] `Lint: Python files` - Verifica Python
- [ ] `Format: Shell scripts` - Formatea bash
- [ ] `Format: Python files` - Formatea Python
- [ ] `Test: E2E scripts (dry-run)` - Pruebas E2E
- [ ] `Validate: JSON schemas` - Valida JSONL
- [ ] `Build: Docker images` - Valida Docker
- [ ] `Docs: Build MkDocs` - Construye docs
- [ ] `Run: Frontend Streamlit` - Lanza UI

## 🔍 Fase 9: Leer documentación (5 min)

- [ ] Lee [VSCODE_SETUP.md](VSCODE_SETUP.md) - Guía rápida
- [ ] Consulta [docs/vscode-tooling-setup.md](docs/vscode-tooling-setup.md) - Detalles
- [ ] Revisa [TOOLING_IMPROVEMENTS.md](TOOLING_IMPROVEMENTS.md) - Resumen

## ❌ Solucionar problemas comunes

### ShellCheck no funciona
```bash
# Verificar instalación
shellcheck --version

# Si falta:
sudo apt-get install -y shellcheck
```

### Ruff no se ejecuta
```bash
# Verificar
venv/bin/ruff --version

# Si falta:
source venv/bin/activate
pip install ruff
deactivate
```

### Python formatter no funciona
- Verifica que seleccionaste el interprete correcto
- `Ctrl+Shift+P` → `Python: Select Interpreter`
- Elige: `./venv/bin/python`

### Las tareas no aparecen
- Verifica: `.vscode/tasks.json` existe
- Reinicia VSCode: `Ctrl+Shift+P` → `Reload Window`

### Extensiones no se instalan
- Usa: `Ctrl+Shift+X` → busca por nombre individual
- Instala una por una si el "Install All" falla

## 📋 Resumen final

**Tiempo total:** ~30 minutos

**Beneficios:**
- ✅ Código automáticamente formateado
- ✅ Errores detectados en tiempo real
- ✅ 12 tareas automatizadas disponibles
- ✅ Historial de cambios integrado (GitLens)
- ✅ Documentación local (MkDocs)

**Proximos pasos:**
1. Abre un archivo Python → introduce cambios → guarda
2. Verifica que se formatea automáticamente
3. Prueba `Ctrl+Shift+P` → `Run Task`
4. Explora GitLens haciendo click en líneas

## 🎉 ¡Configuración completada!

Una vez termines el checklist anterior, tendrás:
- Ambiente de desarrollo profesional
- Herramientas de calidad activadas
- Productividad mejorada
- Consistencia en el código

**¿Necesitas ayuda?** Consulta la sección "Troubleshooting" en [VSCODE_SETUP.md](VSCODE_SETUP.md)
