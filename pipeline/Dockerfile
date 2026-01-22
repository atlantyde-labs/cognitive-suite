FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/tmp \
    XDG_CACHE_HOME=/tmp/.cache \
    HF_HOME=/tmp/hf \
    TRANSFORMERS_CACHE=/tmp/hf

WORKDIR /app

RUN useradd -m -u 10001 -s /usr/sbin/nologin appuser

COPY pipeline/requirements.txt /app/requirements.txt

# Dependencias con versiones fijadas (CPU-only)
RUN pip install --no-cache-dir --upgrade pip==25.3 && \
    pip install --no-cache-dir -r /app/requirements.txt

COPY pipeline/analyze.py /app/analyze.py

RUN chown -R appuser:appuser /app

USER appuser

ENTRYPOINT ["python", "analyze.py"]

