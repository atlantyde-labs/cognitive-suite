# Lab 01: Deep Dive - Línea Base de Pipeline Seguro

Bienvenidos al primer desafío real de la **Cognitive Suite**. Este Lab no es solo una prueba de software; es tu puerta de entrada a la **Soberanía Cognitiva**.

## 🧠 Filosofía: Aprender Haciendo
En este Lab, transformarás un documento de texto plano en **Capital Cognitivo Estructurado**. Aprenderás cómo la IA local puede proteger tu privacidad mientras extrae valor de tus datos.

## 🛠️ Requisitos Previos
Antes de empezar, asegúrate de tener tus "superpoderes" instalados:
- [x] Entorno virtual activo.
- [x] Dependencias instaladas (`pip install -r requirements.txt`).
- [x] Modelo de IA español descargado (`python -m spacy download es_core_news_md`).

---

## 🚀 Paso a Paso: El Ciclo de Vida del Dato

### 1. Ingesta (Preparando la Materia Prima)
Crea un archivo en `data/input/my_lab.txt` con contenido sensible (nombres, presupuestos, emails). Luego, "preséntaselo" a la Suite:
```powershell
python cogctl.py ingest my_lab.txt
```
*¿Por qué? Porque el sistema debe centralizar y normalizar los archivos antes de analizarlos.*

### 2. Análisis Securizado (El Cerebro de la Suite)
Ejecuta el pipeline activando la capa de **Redacción**:
```powershell
$env:COGNITIVE_REDACT="1"; python cogctl.py analyze
```
*Aquí es donde spaCy busca entidades, Transformers analiza el sentimiento y nuestras reglas bloquean fugas financieras.*

### 3. Validación Instantánea (Feedback Loop)
Usa nuestra herramienta de validación para ver si has cumplido los objetivos técnicos:
```powershell
python cogctl.py verify
```
*Si ves todos los checks en verde, ¡has configurado correctamente el motor de IA y Privacidad!*

---

## 🏆 Desafíos Extra (Para Talentos Avanzados)
Si quieres demostrar que entiendes el sistema tan bien como su creador, intenta esto:

1. **El Multi-Tag**: Escribe un texto que obligue a la IA a poner 4 o más etiquetas (ej. que hable de una idea, un riesgo legal y una acción pendiente).
2. **Sentimiento Extremo**: Intenta escribir un texto que obtenga un `score` de sentimiento superior a 0.85. ¿Qué palabras clave "emocionan" más a la IA?
3. **El Dashboard**: Abre Streamlit (`streamlit run frontend/streamlit_app.py`) y verifica que los caracteres (como el símbolo €) se ven perfectos gracias a nuestra mejora de UTF-8.

## 📝 Evidencia para tu PR
Para que tu equipo valide este Lab, tu Pull Request debe incluir:
1. El archivo `outputs/insights/analysis.json` resultante.
2. Los logs de auditoría en `outputs/audit/analysis.jsonl`.
3. Una captura de pantalla de tu Dashboard con los datos redactados.

---
> [!IMPORTANT]
> Recuerda que en este proyecto **la evidencia manda sobre la opinión**. Si no hay logs, no hay Lab.
