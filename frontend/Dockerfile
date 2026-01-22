FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/tmp \
    XDG_CACHE_HOME=/tmp/.cache \
    STREAMLIT_CONFIG_DIR=/tmp/.streamlit
    
WORKDIR /app

RUN useradd -m -u 10001 -s /usr/sbin/nologin appuser

COPY frontend/requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir --upgrade pip==25.3 && \
    pip install --no-cache-dir -r /app/requirements.txt

COPY frontend/ /app/

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8501

CMD ["streamlit", "run", "streamlit_app.py", "--server.headless=true", "--server.port=8501"]

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD python - <<'PY'\nimport urllib.request\ntry:\n    urllib.request.urlopen('http://127.0.0.1:8501/_stcore/health', timeout=3)\n    raise SystemExit(0)\nexcept Exception:\n    raise SystemExit(1)\nPY













