FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Force torch CPU (avoids huge nvidia-*cu12 wheels on GitHub runners)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
      torch torchvision torchaudio && \
    pip install --no-cache-dir \
      PyPDF2 \
      pymupdf \
      openai-whisper \
      ffmpeg-python \
      pyyaml

COPY ingestor/ingest.py /app/ingest.py
ENTRYPOINT ["python", "ingest.py"]
