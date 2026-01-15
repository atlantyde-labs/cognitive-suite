# Guía para desarrolladores y colaboradores

Bienvenido/a a **Cognitive GitOps Suite** 👋  
Este proyecto se construye bajo una filosofía de **Learning by Doing**, cooperación
y soberanía tecnológica.

Aquí no solo contribuimos código: entrenamos nuestro criterio técnico,
nuestro pensamiento sistémico y nuestra capacidad de cooperar.

---

## 🧠 Filosofía de contribución

- Aprender haciendo > documentación pasiva
- Cambios pequeños, trazables y reversibles
- Local-first siempre que sea posible
- La automatización existe para **amplificar criterio humano**, no sustituirlo
- El conocimiento generado debe poder ser reutilizado por la cooperativa

---

## 🛠️ Requisitos básicos

- Git + GitHub
- Python 3.10+
- Docker + Docker Compose
- Entorno local funcional (Linux recomendado)

---

## 🚀 Primeros pasos (Learning by Doing)

```bash
git clone https://github.com/atlantyde-labs/cognitive-suite.git
cd cognitive-suite
python cogctl.py init
```

Ejercicio inicial recomendado:

1. Añade un PDF o texto a `data/input/`
2. Ejecuta:

   ```bash
   python cogctl.py ingest data/input/tu_archivo.pdf
   python cogctl.py analyze
   ```
3. Observa `outputs/insights/analysis.json`

👉 Si entiendes este flujo, **ya puedes contribuir**.

---

## 🔁 Metodología de aportación

1) Elige una unidad pequeña (un script, doc, ejemplo o reto).  
2) Trabaja en rama:
```bash
git checkout -b feature/nombre-claro
```
3) Valida localmente y no rompas CI.  
4) Describe el *por qué* en tu PR: problema, aprendizaje y siguiente paso.

---

## 🔄 Upgrades y rollbacks seguros

```bash
./upgrade_rollback.sh upgrade bundle.zip
```

Rollback:
```bash
./upgrade_rollback.sh rollback backup-YYYYMMDD-HHMMSS
```

---

## 🧪 Tipos de contribuciones bienvenidas

- Nuevos analizadores cognitivos
- Integraciones (RAG, notebooks, LLMs locales)
- Ejemplos reales (legal, educativo, técnico)
- Retos “learning by doing”
- Mejora de CI / GitOps
- Documentación pedagógica

---

## 🏛️ Modelo cooperativo

Las contribuciones son **capital cognitivo compartido**.
Contribuir aquí significa aprender, enseñar y construir futuro colectivo.
