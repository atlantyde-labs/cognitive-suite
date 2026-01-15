FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# ffmpeg para whisper
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1) Torch CPU explícito (EVITA nvidia-*cu12)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
      torch torchvision torchaudio

# 2) Dependencias específicas de ingesta + whisper
RUN pip install --no-cache-dir \
      PyPDF2 \
      pymupdf \
      openai-whisper \
      ffmpeg-python \
      pyyaml

COPY ingestor/ingest.py /app/ingest.py

ENTRYPOINT ["python", "ingest.py"]
