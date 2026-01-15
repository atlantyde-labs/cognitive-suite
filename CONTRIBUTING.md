# 🤝 Guía de Contribución a Cognitive GitOps Suite

Gracias por tu interés en contribuir a este proyecto de soberanía cognitiva y tecnológica.

## 🧱 Tipos de contribuciones bienvenidas
- Nuevos módulos de análisis (emocional, legal, social, etc.)
- Integración de formatos adicionales (audio, imagen, código no soportado)
- Mejoras en visualización con Streamlit/Gradio
- Automatización CI/CD o GitOps extendido
- Traducciones o adaptaciones culturales

## ⚙️ Cómo contribuir paso a paso

1. Haz un fork de este repositorio en GitHub
2. Clona tu fork localmente:
```bash
git clone git@github.com:TU_USUARIO/mi-cerebro-digital.git
cd mi-cerebro-digital
```
3. Crea una nueva rama descriptiva:
```bash
git checkout -b feature/nueva-funcion
```
4. Realiza tus cambios. Asegúrate de:
    - Seguir buenas prácticas de seguridad y trazabilidad
    - No incluir datos personales en commits
    - Mantener el estilo modular del código
5. Haz commit y push:
```bash
git commit -am "Agrega análisis emocional con HuggingFace"
git push origin feature/nueva-funcion
```
6. Abre un Pull Request explicando claramente tu aporte

## 🛡️ Reglas éticas y técnicas
- Este proyecto promueve el uso responsable, transparente y descentralizado de la IA
- No se permite código con dependencias privativas cerradas sin justificación
- Las decisiones técnicas priorizan seguridad, soberanía digital y simplicidad

## 🏅 Reconocimiento
Todas las contribuciones aceptadas serán reconocidas públicamente. Queremos visibilizar tu trabajo y trayectoria.

## 💡 ¿Tienes ideas disruptivas?
Abre un Issue con tu propuesta o súmate al canal de discusión estratégica.

> ¡Gracias por ayudar a construir herramientas que respeten nuestra inteligencia, identidad y libertad!
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
