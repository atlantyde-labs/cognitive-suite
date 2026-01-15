FROM python:3.10-slim

LABEL maintainer="cognitive-suite"

# Instalar dependencias para análisis semántico. Incluimos PyYAML,
# spaCy, transformers y faiss-cpu. En un entorno de producción se
# podrían optimizar estas instalaciones o usarse imágenes específicas.
WORKDIR /app
COPY ../requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir \
    pyyaml \
    spacy \
    transformers \
    sentence-transformers \
    faiss-cpu

# Opcional: descargar un modelo spaCy en el build. Se comenta para
# evitar un proceso pesado en cada build. Puede habilitarse según las
# necesidades.
# RUN python -m spacy download es_core_news_sm

COPY analyze.py /app/analyze.py

ENTRYPOINT ["python", "analyze.py"]
