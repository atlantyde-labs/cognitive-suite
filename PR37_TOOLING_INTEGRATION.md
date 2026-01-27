# Integración: Nuevas herramientas de desarrollo con PR #37

Este documento explica cómo las nuevas herramientas de desarrollo en VSCode mejoran el flujo de trabajo del PR **Scripts Bash Managements Ops Systems** (#37).

## 🎯 Contexto del PR

El PR #37 introduce:
- ✅ Nuevos scripts bash para gestión de operaciones
- ✅ Workflows de GitHub Actions actualizados
- ✅ Herramientas para fine-tuning de modelos
- ✅ Inventario de modelos con control de acceso
- ✅ Validación de esquemas JSONL

## 🔗 Cómo se integran las nuevas herramientas

### 1. Linting automático de nuevos scripts bash

Con la configuración de VSCode, todos los nuevos scripts `.sh` se validan automáticamente:

```bash
# Ejecutar linting
Run Task → Lint: Shell scripts

# O con atajo
Ctrl+Shift+L
```

**Beneficio:** Los scripts en `bash/GitDevSecDataAIOps/` se verifican contra `shellcheck`.

### 2. Validación de JSONL en CI

Los workflows del PR ahora pueden usar las tareas de validación:

```bash
# En .github/workflows/
Run Task → Validate: JSON schemas
```

Valida automáticamente:
- `datasets/atlantityqa_cognitive_suite_ft_v2.jsonl`
- `datasets/bot-clickops.example.jsonl`
- `datasets/github-migration-clickops.example.jsonl`

### 3. Tareas automatizadas para E2E

El nuevo workflow `e2e-public-runner-validation.yml` se acelera con tareas:

```bash
# Dry-run antes de commit
Run Task → Test: E2E scripts (dry-run)

# En CI automáticamente
bash -n bash/GitDevSecDataAIOps/tooling/tests/mock-e2e.sh
```

### 4. Formateo consistente

Todos los scripts bash nuevos se formatean automáticamente:

```bash
Run Task → Format: Shell scripts
```

**Aplica automáticamente en scripts:**
- `bash/GitDevSecDataAIOps/tooling/fine-tune/ft_prepare.py` (Python también)
- `bash/GitDevSecDataAIOps/tooling/models/model_inventory.py`
- `bash/GitDevSecDataAIOps/proxmox/*`

## 📊 Mejoras específicas para el PR

### Antes (sin nuevas herramientas)
```
❌ Validación manual de scripts
❌ Formateo irregular
❌ Falta detección de errores comunes
❌ Testing manual antes de PR
❌ Documentación sin sincronizar
```

### Después (con nuevas herramientas)
```
✅ Validación automática en VSCode
✅ Formateo consistente al guardar
✅ Detección de errores en tiempo real
✅ Tareas automatizadas para testing
✅ Documentación auto-generada (MkDocs)
```

## 🛠️ Flujo de trabajo mejorado para el PR

### 1. Crear nuevo script bash

```bash
# VSCode detecta automáticamente
cat > bash/GitDevSecDataAIOps/tooling/nuevo-script.sh <<'EOF'
#!/usr/bin/env bash
# Tu script
EOF

# Al guardar (Ctrl+S):
# ✅ Formatea con shfmt automáticamente
# ✅ Valida con shellcheck en tiempo real
```

### 2. Probar script antes de commit

```bash
# Run Task → Test: E2E scripts (dry-run)
# O manualmente
bash -n bash/GitDevSecDataAIOps/tooling/nuevo-script.sh
shellcheck bash/GitDevSecDataAIOps/tooling/nuevo-script.sh
```

### 3. Validar JSONL del PR

```bash
Run Task → Validate: JSON schemas

# Valida automáticamente contra:
# - bot-clickops.schema.json
# - github-migration-clickops.schema.json
```

### 4. Antes de hacer push

```bash
# Ejecutar todos los lints
Run Task → Lint: Shell scripts
Run Task → Lint: Python files
Run Task → Validate: JSON schemas

# Si todo está verde, push con confianza
```

## 📋 Checklist para contribuyentes del PR #37

Cuando trabajes en scripts para el PR:

- [ ] Nuevo script bash creado
- [ ] Al guardar, shfmt formatea automáticamente
- [ ] `Ctrl+Shift+L` → shellcheck sin errores
- [ ] JSONL validados con `Validate: JSON schemas`
- [ ] `Run Task → Test: E2E scripts` pasa
- [ ] Python code con ruff validado
- [ ] Documentación en `docs/` actualizada (MkDocs)
- [ ] Listo para push

## 🚀 Ventajas para el PR

1. **Calidad:** Todos los scripts validados antes de merge
2. **Consistencia:** Formato uniforme en todos los scripts
3. **Documentación:** Auto-generada con MkDocs
4. **Testing:** Tareas E2E listos
5. **Auditoría:** GitLens muestra quién cambió qué

## 🔄 Integración con CI/CD

El archivo `.github/workflows/` ahora puede reutilizar:

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Lint Shell scripts
        run: |
          scripts=$(find bash/GitDevSecDataAIOps scripts -name '*.sh')
          shellcheck $scripts

      - name: Validate JSONL
        run: |
          python3 bash/GitDevSecDataAIOps/tooling/forensics/validate-jsonl.py \
            --schema schemas/bot-clickops.schema.json \
            --input datasets/bot-clickops.example.jsonl
```

## 📚 Documentación de soporte

| Documento | Propósito |
|-----------|-----------|
| [VSCODE_SETUP.md](VSCODE_SETUP.md) | Guía rápida (3 pasos) |
| [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) | Checklist detallado |
| [docs/vscode-tooling-setup.md](docs/vscode-tooling-setup.md) | Referencia completa |
| [TOOLING_IMPROVEMENTS.md](TOOLING_IMPROVEMENTS.md) | Cambios realizados |

## 🎓 Ejemplo: Flujo completo del PR

```bash
# 1. Clonar rama
git clone -b chore/scripts-testing https://github.com/atlantyde-labs/cognitive-suite.git
cd cognitive-suite

# 2. Abrir en VSCode
code .

# 3. Instalar extensiones (notificación automática)
# → Click en "Install All"

# 4. Crear virtualenv (ver SETUP_CHECKLIST.md)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. Crear nuevo script bash
vim bash/GitDevSecDataAIOps/tooling/nuevo-feature.sh

# 6. Al guardar → automáticamente se formatea
# (shfmt + shellcheck)

# 7. Ejecutar lints
Ctrl+Shift+P → Run Task → Lint: Shell scripts

# 8. Validar JSONL si aplica
Ctrl+Shift+P → Run Task → Validate: JSON schemas

# 9. Test E2E
Ctrl+Shift+P → Run Task → Test: E2E scripts (dry-run)

# 10. Si todo está verde
git add .
git commit -m "feat: nuevo script bash"
git push

# → PR validado con CI/CD
```

## 🔐 Seguridad en el flujo

- ✅ ShellCheck detecta vulnerabilidades bash comunes
- ✅ JSONL validation previene datos malformados
- ✅ Python ruff detecta issues de seguridad
- ✅ GitLens audita cambios por autor

## ✅ Resumen

Las nuevas herramientas de VSCode mejoran significativamente el flujo de trabajo del PR #37:

1. **Validación**: Automática en tiempo real
2. **Formateo**: Consistente al guardar
3. **Testing**: Tareas de E2E integradas
4. **Documentación**: Auto-generada
5. **Auditoría**: Trazabilidad completa

**Resultado:** PR de mayor calidad, con menos errores y más rápido de revisar.

---

**Integración completada:** Enero 2026
**Compatible con:** PR #37 - Scripts Bash Managements Ops Systems
