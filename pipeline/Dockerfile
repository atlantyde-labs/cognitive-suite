FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Torch CPU explícito (EVITA nvidia-*cu12)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
      torch torchvision torchaudio

# NLP stack (solo lo que usa pipeline)
RUN pip install --no-cache-dir \
      pyyaml \
      spacy \
      transformers \
      sentence-transformers \
      faiss-cpu

COPY pipeline/analyze.py /app/analyze.py
ENTRYPOINT ["python", "analyze.py"]



