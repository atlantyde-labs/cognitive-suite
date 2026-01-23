FROM python:3.10-slim AS base

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/tmp \
    XDG_CACHE_HOME=/tmp/.cache \
    HF_HOME=/tmp/hf \
    TRANSFORMERS_CACHE=/tmp/hf

WORKDIR /app

RUN useradd -m -u 10001 -s /usr/sbin/nologin appuser

RUN pip install --no-cache-dir --upgrade pip==25.3

FROM base AS playground

COPY pipeline/requirements-playground.txt /app/requirements-playground.txt

RUN pip install --no-cache-dir -r /app/requirements-playground.txt

COPY pipeline/analyze.py /app/analyze.py

RUN chown -R appuser:appuser /app

USER appuser

ENTRYPOINT ["python", "analyze.py"]

FROM base AS full

COPY pipeline/requirements.txt /app/requirements.txt

# Dependencias con versiones fijadas (CPU-only)
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY pipeline/analyze.py /app/analyze.py

RUN chown -R appuser:appuser /app

USER appuser

ENTRYPOINT ["python", "analyze.py"]
