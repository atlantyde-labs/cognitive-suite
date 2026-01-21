FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/tmp \
    XDG_CACHE_HOME=/tmp/.cache

# ffmpeg para whisper
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 10001 -s /usr/sbin/nologin appuser

WORKDIR /app

COPY ingestor/requirements.txt /app/requirements.txt

# Dependencias con versiones fijadas (CPU-only)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

COPY ingestor/ingest.py /app/ingest.py

RUN chown -R appuser:appuser /app

USER appuser

ENTRYPOINT ["python", "ingest.py"]
