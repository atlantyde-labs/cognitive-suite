# 🧠 Cognitive GitOps Suite
Learning by Doing · Cooperativismo · Soberanía Cognitiva

[![CI](https://github.com/atlantyde-labs/cognitive-suite/actions/workflows/ci.yml/badge.svg)](https://github.com/atlantyde-labs/cognitive-suite/actions)
[![License: EUPL](https://img.shields.io/badge/License-EUPL--1.2-blue.svg)](LICENSE)
[![Learning By Doing](https://img.shields.io/badge/learning-by_doing-orange)](#ruta-de-aprendizaje-gamificada)
[![Cooperative Ready](https://img.shields.io/badge/model-cooperative-green)](#modelo-cooperativo)

> **No venimos solo a construir software.  
> Entrenamos criterio humano para cooperar con sistemas inteligentes.**

Cognitive GitOps Suite es un conjunto de herramientas local-first
para ingestar, analizar y gobernar tus datos personales y profesionales de
forma reproducible. Esta versión incluye automatización completa tanto
para desarrollo local como para despliegues productivos y ejecución en
GitHub Actions.

**TL;DR para devs con prisa**
- Local-first para trabajar sin fricción en tu máquina.
- Pipeline cognitivo reproducible (ingesta → análisis → insights).
- GitOps opcional para sincronizar resultados.
- CI/CD listo para GitHub Actions.

**Tips rápidos (pa' ir fino)**
- Tip 1: Arquitectura local-first con foco en seguridad, trazabilidad y cumplimiento, alineada con la soberanía digital europea.
- Tip 2: Diseñado con principios de control de datos, auditabilidad y compliance, orientado a soberanía digital europea.
- Tip 3: Prioriza seguridad, privacidad y cumplimiento normativo como base para soberanía digital europea.

## Índice
- [¿Qué es Cognitive GitOps Suite?](#que-es-cognitive-gitops-suite)
- [Por qué este proyecto existe](#por-que-este-proyecto-existe)
- [Modo Early Adopters (todo en local)](#modo-early-adopters-todo-en-local)
- [Artefactos generados y dónde mirarlos](#artefactos-generados-y-donde-mirarlos)
- [Flujos de ejecución](#flujos-de-ejecucion)
- [Esquemas y validación](#esquemas-y-validacion)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Ruta de Aprendizaje Gamificada](#ruta-de-aprendizaje-gamificada)
- [Cómo contribuir](#como-contribuir)
- [Upgrades y rollbacks seguros](#upgrades-y-rollbacks-seguros)
- [Paquetización Debian](#paquetizacion-debian)
- [Docs (GitHub Pages)](#docs-github-pages)
- [Modelo cooperativo](#modelo-cooperativo)
- [Licencia](#licencia)

<a id="que-es-cognitive-gitops-suite"></a>
## 🌍 ¿Qué es Cognitive GitOps Suite?

**Cognitive GitOps Suite** es un **laboratorio open-source de aprendizaje práctico** para personas que quieren:

- Aprender a **pensar con IA**, no solo usarla.
- Construir **pipelines cognitivos reproducibles**.
- Cooperar en lugar de competir.
- Prepararse para un futuro tecnológico, legal y social que ya está aquí.

Este proyecto nace en el ecosistema **ATLANTYDE / ATLANTYQA** como infraestructura
de **capital cognitivo compartido** para cooperativas, comunidades y talento técnico
que quiere aprender haciendo.

<a id="por-que-este-proyecto-existe"></a>
## 🧭 Por qué este proyecto existe (contexto real)

El contexto real ahora mismo:
- Automatización masiva.
- IA como infraestructura básica.
- Desplazamiento de roles tradicionales.
- Necesidad urgente de **criterio humano entrenado**.

👉 **La respuesta no es más herramientas.  
Es mejor aprendizaje, mejor cooperación y soberanía tecnológica.**

Este repo es un **campo de entrenamiento cognitivo**.

<a id="modo-early-adopters-todo-en-local"></a>
## ⚡ Modo Early Adopters (todo en local)

Arranca en 5 minutos, pensado para aprender haciendo:

```bash
git clone https://github.com/atlantyde-labs/cognitive-suite.git
cd cognitive-suite

# Inicializa estructura de carpetas y dependencias
python cogctl.py init

# Coloca archivos a procesar en data/input/

# Ingiere un archivo concreto
python cogctl.py ingest mi_archivo.pdf

# Ejecuta el análisis y genera insights en outputs/insights/analysis.json
python cogctl.py analyze
```

Mini reto:
1. Añade un PDF o texto en `data/input/`.
2. Ejecuta `ingest → analyze`.
3. Observa `outputs/insights/analysis.json`.

👉 Si llegas hasta aquí, **ya estás aprendiendo haciendo**.

Opcional: bootstrap rápido.
```bash
# Script de bootstrap para desarrolladores
bash dev/bootstrap.sh
```

<a id="artefactos-generados-y-donde-mirarlos"></a>
## 📦 Artefactos generados y dónde mirarlos

Este repositorio ya está preparado para que puedas inspeccionar resultados locales
sin depender de infraestructura externa:

- `data/input/` → tus archivos de entrada.
- `outputs/insights/analysis.json` → insight principal generado por el pipeline.
- `outputs/` → directorio de resultados (raw + insights según el flujo).
- `dist/` → paquetes generados (p. ej. `.deb`) cuando empaquetas.

<a id="flujos-de-ejecucion"></a>
## 🔁 Flujos de ejecución

### Prueba de extremo a extremo (Docker Compose)

Para validar el stack completo en local con Docker Compose:

```bash
bash test-bootstrap.sh
```

El script espera el resultado en `outputs/insights/analysis.json`. El timeout por
defecto es `21600` segundos (6 horas), alineado con el máximo de ejecución de
los runners públicos de GitHub Actions. Si quieres reducirlo:

```bash
BOOTSTRAP_TIMEOUT_SECS=900 bash test-bootstrap.sh
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

El workflow `.github/workflows/ci.yml` define un pipeline que:

1. Instala las dependencias necesarias de Python.
2. Inicializa la estructura de carpetas.
3. Ejecuta el bootstrap de desarrollo (`dev/bootstrap.sh`).
4. Construye las imágenes Docker y lanza un test de extremo a extremo (`test-bootstrap.sh`).
5. Publica el resultado del análisis como artefacto.

Este workflow se ejecuta en cada `push` o `pull_request` contra `main`.

<a id="esquemas-y-validacion"></a>
## 🧪 Esquemas y validación

El output principal de análisis sigue el esquema `schemas/insight.schema.json`
(JSON Schema 2020-12). Para validar los datasets de `knowledge/` y el ejemplo de
insight incluido:

```bash
python scripts/validate-knowledge.py
```

Necesita `jsonschema>=4.18` (ver `requirements.txt`/`requirements-ci.txt`).

<a id="estructura-del-repositorio"></a>
## 📂 Estructura del repositorio

- `ingestor/` – Conversión de PDF, DOCX, TXT y otros formatos a texto.
- `pipeline/` – Análisis semántico y clasificación en categorías cognitivas.
- `frontend/` – Interfaz mínima (actualmente en consola).
- `gitops/` – Sincronización de resultados a repositorios Git remotos.
- `schemas/` – Definición del esquema cognitivo (etiquetas).
- `data/` – Entradas locales para ingesta.
- `outputs/` – Artefactos generados por la suite.
- `dev/` – Scripts de bootstrap para desarrolladores.
- `ops/` – Scripts para DevOps y operaciones.
- `docker-compose.yml` – Orquestación de servicios para desarrollo.
- `docker-compose.prod.yml` – Orquestación resiliente para producción.
- `.github/workflows/ci.yml` – Workflow de CI para GitHub.

<a id="ruta-de-aprendizaje-gamificada"></a>
## 🎮 Ruta de Aprendizaje Gamificada

> La ruta está diseñada para que cada contribución sea aprendizaje aplicado.
> Puedes usar Issues con etiquetas para elegir tu siguiente reto.

### 🟢 Nivel 1 — Explorador Cognitivo
- [ ] Ejecutar `init → ingest → analyze`.
- [ ] Leer `outputs/insights/analysis.json`.
- [ ] Abrir un Issue con etiqueta `learning-task`.

🏅 Badge sugerido: `cognitive-explorer`

### 🔵 Nivel 2 — Constructor de Sentido
- [ ] Ajustar reglas / prompts / categorías.
- [ ] Añadir una categoría cognitiva.
- [ ] Documentar el aprendizaje en el PR.

🏅 Badge sugerido: `sense-builder`

### 🟣 Nivel 3 — Ingeniero Cognitivo
- [ ] Añadir un nuevo tipo de ingesta.
- [ ] Integrar embeddings / RAG / notebooks.
- [ ] Mejorar CI / GitOps.

🏅 Badge sugerido: `cognitive-engineer`

### ⚫ Nivel 4 — Cooperador Estratégico
- [ ] Proponer retos de aprendizaje.
- [ ] Mentorar a otros.
- [ ] Mejorar documentación pedagógica.

🏅 Badge sugerido: `cooperative-mentor`

<a id="como-contribuir"></a>
## 🧩 Cómo contribuir

📄 Lee: [`CONTRIBUTING.md`](CONTRIBUTING.md)
🧪 Tests: [`TESTING_GUIDE.md`](TESTING_GUIDE.md)

Y para entrar rápido:
- Abre un Issue con `good first issue` o `learning-task`.
- Haz un PR pequeño, trazable y con contexto.

<a id="upgrades-y-rollbacks-seguros"></a>
## 🔄 Upgrades y rollbacks seguros

```bash
./upgrade_rollback.sh upgrade bundle.zip
```

Rollback:
```bash
./upgrade_rollback.sh rollback backup-YYYYMMDD-HHMMSS
```

<a id="paquetizacion-debian"></a>
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

<a id="docs-github-pages"></a>
## 📚 Docs (GitHub Pages)

La carpeta `docs/` contiene la documentación oficial de la suite. Un
workflow de GitHub Actions (`.github/workflows/pages.yml`) despliega automáticamente
estos documentos en GitHub Pages cada vez que se modifican. Podrás
consultar la documentación pública en:

```
https://<TU_USUARIO>.github.io/<TU_REPOSITORIO>/
```

El portal se genera desde `docs/` y `mkdocs.yml`.

Documentos clave:
- [docs/installation.md](docs/installation.md)
- [docs/adoption-plan.md](docs/adoption-plan.md)
- [docs/execution-plan-early-adopters.md](docs/execution-plan-early-adopters.md)
- [docs/open_notebook_integration.md](docs/open_notebook_integration.md)
- [docs/internal/compute-strategy.md](docs/internal/compute-strategy.md)
- [docs/internal/execution-plan.md](docs/internal/execution-plan.md)

<a id="modelo-cooperativo"></a>
## 🏛️ Modelo cooperativo (ATLANTYDE / ATLANTYQA)

Este proyecto **no es un producto**, es un **ecosistema cooperativo**.
Contribuir aquí significa: aprender · enseñar · construir futuro compartido.

> *El futuro no se predice. Se entrena. Y se entrena mejor en cooperación.*

<a id="licencia"></a>
## ✅ Licencia

Este proyecto está licenciado bajo los términos definidos en `LICENSE`.
