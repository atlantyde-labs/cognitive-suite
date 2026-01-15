FROM python:3.10-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Keep frontend slim: no whisper/transformers here
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir streamlit rich textual pyyaml requests

COPY frontend/ /app/

EXPOSE 8501
CMD ["streamlit", "run", "streamlit_app.py", "--server.headless=true", "--server.port=8501"]
