#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ingestor/ingest.py
-------------------

Este módulo proporciona una utilidad de línea de comandos para ingerir archivos
de diferentes formatos (por ejemplo, PDF, DOCX, TXT, JSON) y convertirlos en
texto plano. El texto resultante se almacena en una carpeta de salida para su
procesamiento posterior por el pipeline cognitivo. La conversión es
best‑effort: cuando no se dispone de bibliotecas específicas, los archivos se
copian tal cual o se extrae el contenido mínimo posible.

Uso básico:

```
python ingestor/ingest.py /ruta/al/archivo --output outputs/raw
```

Para ingerir un directorio completo de archivos, simplemente proporcione la
ruta del directorio; todos los archivos serán procesados recursivamente.
"""

import argparse
import html
import re
import zipfile
from pathlib import Path


def extract_docx_text(file_path: Path) -> str:
    """Extrae texto de un archivo DOCX sin dependencias externas."""
    try:
        with zipfile.ZipFile(file_path) as zf:
            data = zf.read('word/document.xml').decode('utf-8')
        # Reemplazar etiquetas XML por saltos de línea
        text = re.sub('<[^<]+?>', '\n', data)
        text = html.unescape(text)
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        return '\n'.join(lines)
    except Exception:
        return ''


def extract_pdf_text(file_path: Path) -> str:
    """Extrae texto de un PDF. Primero intenta con PyMuPDF (fitz) y luego con PyPDF2."""
    # Intentar con PyMuPDF para extraer texto de cada página
    try:
        import fitz  # type: ignore
        doc = fitz.open(str(file_path))
        content = []
        for page in doc:
            text = page.get_text("text")
            if text:
                content.append(text)
        if content:
            return '\n'.join(content)
    except ImportError:
        pass  # Fallback a PyPDF2
    except Exception as e:
        print(f"⚠️ Error extrayendo con PyMuPDF: {e}")

    # Fallback a PyPDF2
    try:
        from PyPDF2 import PdfReader  # type: ignore
        reader = PdfReader(str(file_path))
        content = []
        for page in reader.pages:
            text = page.extract_text() or ''
            content.append(text)
        if any(content):
            return '\n'.join(content)
    except ImportError:
        print("❌ Error: No se encontró PyMuPDF ni PyPDF2. Instala las dependencias con 'pip install -r requirements.txt'")
    except Exception as e:
        print(f"⚠️ Error extrayendo con PyPDF2: {e}")

    return ''


def extract_audio_text(file_path: Path) -> str:
    """Transcribe un archivo de audio a texto usando OpenAI Whisper si está disponible.

    Requiere instalar la librería `whisper` o `openai-whisper`. La precisión puede
    variar según el modelo utilizado. Si Whisper no está instalado o hay algún
    error, se devuelve una cadena vacía para continuar el proceso de ingesta.
    """
    try:
        import whisper  # type: ignore
    except Exception:
        return ''
    try:
        model = whisper.load_model("base")
        result = model.transcribe(str(file_path))
        return result.get("text", "") or ''
    except Exception:
        return ''


def extract_video_text(file_path: Path) -> str:
    """Extrae el audio de un vídeo y lo transcribe a texto usando Whisper.

    Se requiere `ffmpeg` instalado en el sistema para extraer la pista de audio. Si
    no se puede extraer o transcribir, devuelve cadena vacía.
    """
    import subprocess
    import tempfile
    # Crear un archivo temporal WAV
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_audio:
        tmp_path = Path(tmp_audio.name)
    try:
        # Extraer audio con ffmpeg
        subprocess.run([
            "ffmpeg", "-i", str(file_path), "-vn", "-acodec", "pcm_s16le",
            "-ar", "16000", "-ac", "1", str(tmp_path)
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        # No se puede extraer audio
        return ''
    # Transcribir audio
    text = extract_audio_text(tmp_path)
    try:
        if tmp_path.exists():
            tmp_path.unlink()
    except Exception:
        # Silently fail if temporary file cleanup fails
        pass
    return text


def ingest_file(in_path: Path, out_path: Path) -> bool:
    """Convierte un archivo a texto plano y lo guarda en out_path."""
    suffix = in_path.suffix.lower()
    try:
        if suffix in ['.txt', '.md', '.json', '.yaml', '.yml']:
            content = in_path.read_text(encoding='utf-8', errors='ignore')
        elif suffix == '.docx':
            content = extract_docx_text(in_path)
        elif suffix == '.pdf':
            content = extract_pdf_text(in_path)
        elif suffix in ['.mp3', '.wav', '.aac', '.flac', '.m4a', '.ogg']:
            content = extract_audio_text(in_path)
        elif suffix in ['.mp4', '.mov', '.mkv', '.avi', '.flv', '.wmv']:
            content = extract_video_text(in_path)
        else:
            # Para formatos desconocidos, simplemente copiar el contenido binario a texto base64
            import base64
            content = base64.b64encode(in_path.read_bytes()).decode('utf-8')
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(content, encoding='utf-8')
        return True
    except Exception:
        return False


def main() -> None:
    parser = argparse.ArgumentParser(description='Ingesta de archivos a texto plano')
    parser.add_argument('input', help='Archivo o directorio de entrada')
    parser.add_argument('--output', '-o', default='outputs/raw', help='Directorio de salida para los textos')
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    if input_path.is_dir():
        for p in input_path.rglob('*'):
            if p.is_file():
                # Mantener estructura relativa y cambiar extensión a .txt
                rel = p.relative_to(input_path)
                out_file = output_dir / rel.with_suffix('.txt')
                ingest_file(p, out_file)
    else:
        out_file = output_dir / input_path.with_suffix('.txt').name
        ingest_file(input_path, out_file)


if __name__ == '__main__':
    main()
