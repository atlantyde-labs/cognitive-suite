# Configuración de VSCode - Nuevas Herramientas de Desarrollo

Este documento describe las extensiones y herramientas de desarrollo que se han configurado en VSCode para mejorar el flujo de trabajo en **cognitive-suite**.

## Extensiones Recomendadas

Se han agregado automáticamente las siguientes extensiones recomendadas (visible en la vista de extensiones):

### Lenguajes y Linting
- **ms-python.python**: Soporte completo de Python
- **ms-python.vscode-pylance**: Análisis estático avanzado de Python
- **charliermarsh.ruff**: Formateador y linter de Python (rápido, moderno)
- **timonwong.shellcheck**: Análisis estático para scripts bash
- **shellformat.shell-format**: Formateador automático para scripts shell
- **redhat.vscode-yaml**: Validación y formato para archivos YAML

### Control de Versiones y Colaboración
- **eamodio.gitlens**: Historial de cambios integrado
- **github.vscode-github-actions**: Soporte nativo para GitHub Actions
- **ms-azure-tools.vscode-docker**: Manejo de contenedores Docker

### Herramientas de Desarrollo
- **ms-vscode.makefile-tools**: Soporte para Makefiles
- **redhat.vscode-json-schema**: Validación de esquemas JSON
- **gruntfuggly.todo-tree**: Administración de tareas (TODO, FIXME)
- **ms-vscode-remote.remote-containers**: Desarrollo en contenedores
- **ms-vscode-remote.remote-ssh**: Desarrollo remoto por SSH

## Configuración Automática

### Formateo y Linting Automático (OnSave)

1. **Python**:
   - Formateador: `ruff`
   - Actions al guardar: Aplicar fixes y organizar imports automáticamente

2. **Shell Scripts**:
   - Formateador: `shfmt`
   - Aplica formato automático al guardar

3. **YAML/JSON**:
   - Validación automática
   - Formateo al guardar

### Configuraciones de Editor

- **Ancho de línea**: Guías visibles en 80 y 120 caracteres
- **Trailing whitespace**: Eliminado automáticamente
- **Final newline**: Se inserta automáticamente
- **Word wrap**: Habilitado para mejor legibilidad

## Tareas Disponibles (Ctrl+Shift+P)

Ejecuta cualquiera de estas tareas desde el comando *Run Task*:

### Linting
- **Lint: Shell scripts** - Verifica errores en scripts bash
- **Lint: Python files** - Verifica código Python con ruff

### Formateo
- **Format: Shell scripts** - Aplica formato automático a scripts
- **Format: Python files** - Aplica formato automático a código Python

### Pruebas
- **Test: E2E scripts (dry-run)** - Ejecuta pruebas E2E en modo seco
- **Validate: JSON schemas** - Valida esquemas JSON/JSONL

### Construcción
- **Build: Docker images** - Valida configuración Docker Compose
- **Docs: Build MkDocs** - Construye documentación local

### Desarrollo
- **Dev: Bootstrap environment** - Inicializa el ambiente de desarrollo
- **Run: Frontend Streamlit** - Lanza interfaz Streamlit
- **Run: Pipeline analysis** - Ejecuta análisis del pipeline

## Atajos de Teclado Recomendados

| Atajo | Acción |
|-------|--------|
| `Ctrl+Shift+L` | Lint Shell scripts |
| `Ctrl+Shift+P` | Lint Python files |
| `Ctrl+Shift+F` | Format Shell scripts |
| `Alt+Shift+F` | Format Python files |
| `Ctrl+Shift+T` | Run E2E Tests |

## Primeros Pasos

1. **Instalar extensiones**:
   - Abre VSCode
   - Ve a *Extensions* (Ctrl+Shift+X)
   - Se mostrará un aviso de "Extensiones recomendadas"
   - Haz clic en "Install All"

2. **Configurar Python**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Instalar herramientas de desarrollo**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y shellcheck shfmt python3-ruff
   ```

4. **Validar configuración**:
   - Abre un archivo `.py` → se formateará automáticamente
   - Abre un archivo `.sh` → se validará con shellcheck

## Validación de Esquemas JSONL

El workspace soporta validación automática de archivos JSONL contra esquemas:

- **Esquemas disponibles**:
  - `schemas/bot-clickops.schema.json` → para evidencias de bots
  - `schemas/github-migration-clickops.schema.json` → para migraciones
  - `schemas/cognitive-schema.yaml` → para configuraciones
  - `schemas/insight.schema.json` → para datos de insight

## Workspace Settings

El archivo `.vscode/settings.json` configura:

- Exclusión de archivos temporales (`__pycache__`, `.git`)
- Perfil terminal por defecto: `bash`
- Formateadores por lenguaje
- Severity levels para linting
- Indentación y espacios

## GitHub Actions Integration

Se muestra automáticamente:
- Estado de los workflows
- Resultados de CI/CD
- Pull requests y checks

Usa la pestaña de **GitHub** en el explorador lateral.

## Notas de Seguridad

- Los tokens y secretos NO se guardan en `.vscode/`
- Usa variables de entorno para credenciales locales
- Los archivos de configuración son públicos y seguros

## Troubleshooting

### Shellcheck no funciona
```bash
sudo apt-get install -y shellcheck
```

### Ruff no está disponible
```bash
pip install ruff
```

### Formateador de Python no se aplica
- Verifica que `requirements.txt` incluya `ruff`
- Reinicia VSCode

### Tareas no aparecen
- Abre la paleta de comandos: `Ctrl+Shift+P`
- Escribe: "Run Task"
- Verifica que `.vscode/tasks.json` existe

## Referencias

- [Python en VSCode](https://code.visualstudio.com/docs/languages/python)
- [Shell en VSCode](https://code.visualstudio.com/docs/languages/shellscript)
- [Ruff Documentation](https://github.com/astral-sh/ruff)
- [ShellCheck](https://www.shellcheck.net/)
