FROM python:3.10-slim

LABEL maintainer="cognitive-suite"

# Instalar dependencias necesarias para la ingesta de distintos
# formatos. Se incluye ffmpeg para extracción de audio de vídeos y
# bibliotecas Python para PDF, audio y Whisper.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app/requirements.txt
# Instalar solo las dependencias necesarias para la ingesta:
# PyPDF2, pymupdf, openai-whisper, ffmpeg-python y pyyaml.
RUN pip install --no-cache-dir \
    PyPDF2 \
    pymupdf \
    openai-whisper \
    ffmpeg-python \
    pyyaml

COPY ingest.py /app/ingest.py

ENTRYPOINT ["python", "ingest.py"]
