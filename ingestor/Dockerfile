FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# ffmpeg para whisper
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiamos requirements primero para aprovechar caché
COPY ingestor/requirements/base.txt /app/requirements/base.txt
COPY ingestor/requirements/torch-cpu.txt /app/requirements/torch-cpu.txt

# pip upgrade (pineable si quieres ultra compliance)
RUN pip install --no-cache-dir --upgrade pip==25.3

# 1) Torch CPU explícito (EVITA nvidia-*cu12)
RUN pip install --no-cache-dir \
      --index-url https://download.pytorch.org/whl/cpu \
      -r /app/requirements/torch-cpu.txt

# 2) Dependencias app pineadas (PyPI normal)
RUN pip install --no-cache-dir -r /app/requirements/base.txt

COPY ingestor/ingest.py /app/ingest.py
ENTRYPOINT ["python", "ingest.py"]
