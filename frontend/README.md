# 🧠 Cognitive GitOps Suite

Bienvenido a la **Cognitive GitOps Suite**, un conjunto de herramientas local‑first
para ingestar, analizar y gobernar tus datos personales y profesionales de
forma reproducible. Esta versión incluye automatización completa tanto
para desarrollo local como para despliegues productivos y ejecución en
GitHub Actions.

## 🚀 Quick Start

### Desarrollo local

Para probar la suite en tu máquina, ejecuta:

```bash
# Inicializa estructura de carpetas y dependencias
python cogctl.py init

# Coloca archivos a procesar en data/input/

# Ingiere un archivo concreto
python cogctl.py ingest mi_archivo.pdf

# Ejecuta el análisis y genera insights en outputs/insights/analysis.json
python cogctl.py analyze

# También puedes usar el script de bootstrap para desarrolladores
bash dev/bootstrap.sh
```

### Producción

Se incluye un archivo `docker-compose.prod.yml` con políticas de reinicio y
volúmenes preparados para despliegues persistentes. Para desplegar:

```bash
docker compose -f docker-compose.prod.yml up -d
```

Asegúrate de establecer las variables de entorno `GIT_REPO_URL` y
`GIT_BRANCH` si utilizas el servicio GitOps para sincronizar resultados
automáticamente.

### CI/CD en GitHub Actions

El directorio `.github/workflows/ci.yml` define un flujo que:

1. Instala las dependencias necesarias de Python.
2. Inicializa la estructura de carpetas.
3. Ejecuta el bootstrap de desarrollo (`dev/bootstrap.sh`).
4. Construye las imágenes Docker y lanza un test de extremo a extremo (`test-bootstrap.sh`).
5. Publica el resultado del análisis como artefacto.

Este workflow se ejecuta en cada `push` o `pull_request` contra `main`.

## 📂 Estructura

- `ingestor/` – Conversión de PDF, DOCX, TXT y otros formatos a texto.
- `pipeline/` – Análisis semántico y clasificación en categorías cognitivas.
- `frontend/` – Interfaz mínima (actualmente en consola).
- `gitops/` – Sincronización de resultados a repositorios Git remotos.
- `schemas/` – Definición del esquema cognitivo (etiquetas).
- `dev/` – Scripts de bootstrap para desarrolladores.
- `ops/` – Scripts para DevOps y operaciones.
- `docker-compose.yml` – Orquestación de servicios para desarrollo.
- `docker-compose.prod.yml` – Orquestación resiliente para producción.
- `.github/workflows/ci.yml` – Workflow de CI para GitHub.

## ✅ Licencia

Este proyecto está licenciado bajo los términos definidos en `LICENSE`.

## 📦 Paquetización Debian

Si deseas distribuir o instalar la suite como un paquete Debian, se incluye
el script `scripts/build-deb.sh`. Este script genera un paquete `.deb` con
todos los componentes de la suite y un ejecutable `cogctl` en tu PATH.

Para generar el paquete especificando un número de versión:

```bash
chmod +x scripts/build-deb.sh
./scripts/build-deb.sh 0.1.0
```

El paquete resultante se guarda en el directorio `dist/` con el nombre
`cognitive-suite_0.1.0_all.deb`. Instálalo en un equipo basado en Debian o
Ubuntu con:

```bash
sudo apt install ./dist/cognitive-suite_0.1.0_all.deb
```

Esto copiará los archivos de la suite a `/usr/local/lib/cognitive-suite` y
creará un wrapper `cogctl` en `/usr/local/bin`. Una vez instalado podrás
ejecutar la CLI desde cualquier ubicación con `cogctl`.

## 🌍 Documentación pública en GitHub Pages

La carpeta `docs/` contiene la documentación oficial de la suite. Un
workflow de GitHub Actions (`deploy-pages.yml`) despliega automáticamente
estos documentos en GitHub Pages cada vez que se modifican. Podrás
consultar la documentación pública en:

```
https://<TU_USUARIO>.github.io/<TU_REPOSITORIO>/
```

Allí encontrarás la guía de inicio rápido, la estrategia de cómputo, el
plan de ejecución, la guía de instalación y empaquetado y cualquier otra
documentación adicional que añadas bajo `docs/`.
### Learning by Doing · Cooperativismo · Soberanía Cognitiva

[![CI](https://github.com/atlantyde-labs/cognitive-suite/actions/workflows/ci.yml/badge.svg)](https://github.com/atlantyde-labs/cognitive-suite/actions)
[![License: EUPL](https://img.shields.io/badge/License-EUPL--1.2-blue.svg)](LICENSE)
[![Learning By Doing](https://img.shields.io/badge/learning-by_doing-orange)](#-ruta-de-aprendizaje-gamificada)
[![Cooperative Ready](https://img.shields.io/badge/model-cooperative-green)](#-modelo-cooperativo)

> **No construimos software.  
> Entrenamos cerebros humanos para cooperar con sistemas inteligentes.**

---

## 🌍 ¿Qué es Cognitive GitOps Suite?

**Cognitive GitOps Suite** es un **laboratorio open-source de aprendizaje práctico** para personas que quieren:

- Aprender a **pensar con IA**, no solo usarla
- Construir **pipelines cognitivos reproducibles**
- Cooperar en lugar de competir
- Prepararse para el futuro tecnológico, legal y social que ya está aquí

Este proyecto nace en el ecosistema **ATLANTYDE / ATLANTYQA** como infraestructura
de **capital cognitivo compartido** para cooperativas, comunidades y talento técnico
que quiere aprender haciendo.

---

## 🧭 Por qué este proyecto existe (contexto real)

El futuro inmediato viene marcado por:
- Automatización masiva
- IA como infraestructura básica
- Desplazamiento de roles tradicionales
- Necesidad urgente de **criterio humano entrenado**

👉 **La respuesta no es más herramientas.  
Es mejor aprendizaje, mejor cooperación y soberanía tecnológica.**

Este repositorio es un **campo de entrenamiento cognitivo**.

---

## 🚀 Quick Start (primer aprendizaje real en 5 minutos)

```bash
git clone https://github.com/atlantyde-labs/cognitive-suite.git
cd cognitive-suite
python cogctl.py init
```

Ejercicio inicial:

1. Añade un PDF o texto en `data/input/`
2. Ejecuta:
   ```bash
   python cogctl.py ingest data/input/tu_archivo.pdf
   python cogctl.py analyze
   ```
3. Observa:
   ```bash
   outputs/insights/analysis.json
   ```

👉 Si entiendes este flujo, **ya estás aprendiendo haciendo**.

---

## 🎮 Ruta de Aprendizaje Gamificada

> La ruta está diseñada para que cada contribución sea aprendizaje aplicado.
> Puedes usar Issues con etiquetas para elegir tu siguiente reto.

### 🟢 Nivel 1 — Explorador Cognitivo
- [ ] Ejecutar `init → ingest → analyze`
- [ ] Leer `outputs/insights/analysis.json`
- [ ] Abrir un Issue con etiqueta `learning-task`

🏅 Badge sugerido: `cognitive-explorer`

### 🔵 Nivel 2 — Constructor de Sentido
- [ ] Ajustar reglas / prompts / categorías
- [ ] Añadir una categoría cognitiva
- [ ] Documentar el aprendizaje en el PR

🏅 Badge sugerido: `sense-builder`

### 🟣 Nivel 3 — Ingeniero Cognitivo
- [ ] Añadir un nuevo tipo de ingesta
- [ ] Integrar embeddings / RAG / notebooks
- [ ] Mejorar CI / GitOps

🏅 Badge sugerido: `cognitive-engineer`

### ⚫ Nivel 4 — Cooperador Estratégico
- [ ] Proponer retos de aprendizaje
- [ ] Mentorar a otros
- [ ] Mejorar documentación pedagógica

🏅 Badge sugerido: `cooperative-mentor`

---

## 🧩 Cómo contribuir

📄 Lee: [`CONTRIBUTING.md`](CONTRIBUTING.md)

Y para entrar rápido:
- Abre un Issue con `good first issue` o `learning-task`
- Haz un PR pequeño y trazable

---

## 🔄 Upgrades y rollbacks seguros (sin miedo)

```bash
./upgrade_rollback.sh upgrade bundle.zip
```

Rollback:
```bash
./upgrade_rollback.sh rollback backup-YYYYMMDD-HHMMSS
```

---

## 🏛️ Modelo cooperativo ATLANTYQA

Este proyecto **no es un producto**, es un **ecosistema cooperativo**.
Contribuir aquí significa: aprender · enseñar · construir futuro compartido.

> *El futuro no se predice. Se entrena. Y se entrena mejor en cooperación.*

---

## 📚 Docs (GitHub Pages)

Si tienes GitHub Pages habilitado, visita el portal:
- `docs/` + `mkdocs.yml`

Documentos clave:
- `docs/installation.md`
- `docs/adoption-plan.md`
- `docs/open_notebook_integration.md`
- `docs/internal/compute-strategy.md`
- `docs/internal/execution-plan.md`
