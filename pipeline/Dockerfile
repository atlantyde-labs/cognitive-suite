FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY pipeline/requirements.txt /app/requirements.txt

# Dependencias con versiones fijadas (CPU-only)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

COPY pipeline/analyze.py /app/analyze.py
ENTRYPOINT ["python", "analyze.py"]


