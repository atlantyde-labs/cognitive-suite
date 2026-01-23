#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
cogctl.py
---------

CLI mínima para orquestar los distintos módulos de la suite cognitiva.
Implementa subcomandos mediante el módulo estándar ``argparse`` para
eliminar dependencias externas como ``typer``. Los comandos disponibles
son:

- ``init``    → Crear la estructura básica de carpetas.
- ``ingest``  → Ingerir un archivo específico mediante el módulo de ingesta.
- ``analyze`` → Ejecutar el pipeline de análisis sobre los textos ingeridos.
- ``deploy``  → Levantar los servicios definidos en ``docker-compose.yml``.
- ``status``  → Mostrar el estado de los contenedores Docker.
- ``verify``  → Validar el progreso de un Lab (evidencia y seguridad).

Uso:

```
python cogctl.py init
python cogctl.py ingest nombre_archivo.ext
python cogctl.py analyze
python cogctl.py deploy
python cogctl.py status
```
"""

import argparse
import subprocess
import sys
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
INPUT_DIR = BASE_DIR / 'data' / 'input'
RAW_DIR = BASE_DIR / 'outputs' / 'raw'
INSIGHTS_DIR = BASE_DIR / 'outputs' / 'insights'


def cmd_init(args: argparse.Namespace) -> None:
    """Inicializa la estructura de carpetas requerida."""
    for p in [INPUT_DIR, RAW_DIR, INSIGHTS_DIR]:
        p.mkdir(parents=True, exist_ok=True)
    print('📁 Estructura creada: data/input, outputs/raw, outputs/insights')


def cmd_ingest(args: argparse.Namespace) -> None:
    """Ingesta un archivo individual mediante el módulo ``ingestor``."""
    target = INPUT_DIR / args.file
    if not target.exists():
        print(f'❌ Archivo no encontrado: {args.file}')
        raise SystemExit(1)
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    print(f'📥 Ingestando: {args.file}...')
    try:
        subprocess.run([
            sys.executable,
            str(BASE_DIR / 'ingestor' / 'ingest.py'),
            str(target),
            '--output',
            str(RAW_DIR)
        ], check=True, capture_output=True)
        print(f'✅ Ingesta completada: {RAW_DIR / args.file}')
    except subprocess.CalledProcessError as e:
        print(f'❌ Error en la ingesta: {e}')
        raise SystemExit(1)


def cmd_analyze(args: argparse.Namespace) -> None:
    """Ejecuta el análisis cognitivo sobre los textos ingeridos."""
    INSIGHTS_DIR.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run([
            sys.executable,
            str(BASE_DIR / 'pipeline' / 'analyze.py'),
            '--input', str(RAW_DIR),
            '--output', str(INSIGHTS_DIR / 'analysis.json'),
            '--schema', str(BASE_DIR / 'schemas' / 'insight.schema.json')
        ], check=True)
    except subprocess.CalledProcessError as e:
        print(f'❌ Error en el análisis: {e}')
        raise SystemExit(1)


def cmd_deploy(args: argparse.Namespace) -> None:
    """Despliega los servicios definidos en docker-compose."""
    print('🚀 Desplegando servicios...')
    subprocess.run(['docker-compose', 'up', '-d'], check=True)


def cmd_status(args: argparse.Namespace) -> None:
    """Muestra el estado actual de los contenedores Docker."""
    subprocess.run(['docker', 'ps'], check=True)


def cmd_verify(args: argparse.Namespace) -> None:
    """Valida la evidencia generada durante un Lab."""
    print("🔍 Validando Lab 01 - Línea base de pipeline seguro...")

    # Check analysis.json
    analysis_file = INSIGHTS_DIR / 'analysis.json'
    if not analysis_file.exists():
        print("❌ ERROR: No se encontró 'analysis.json'. ¿Has ejecutado 'python cogctl.py analyze'?")
        return

    import json
    try:
        data = json.loads(analysis_file.read_text(encoding='utf-8'))
        if not data:
            print("⚠️ ADVERTENCIA: 'analysis.json' está vacío. No hay archivos procesados.")
        else:
            print(f"✅ 'analysis.json' encontrado con {len(data)} registros.")
            
            # Check for redaction
            redacted_count = sum(1 for r in data if r.get('redacted'))
            if redacted_count > 0:
                print(f"✅ Seguridad: {redacted_count} registros están correctamente REDACTADOS.")
            else:
                print("⚠️ Seguridad: Ningún registro está redactado. Prueba con $env:COGNITIVE_REDACT='1' para pasar el Lab en modo 'Secure'.")

            # Check for entities (AI Power-ups)
            if any(r.get('entities') for r in data):
                print("✅ IA: Se han detectado entidades mediante spaCy.")
            else:
                print("⚠️ IA: No se han detectado entidades. ¿Has instalado spaCy y su modelo de español?")

    except Exception as e:
        print(f"❌ ERROR: Fallo al leer la evidencia: {e}")
        return

    print("\n🎉 Si ves checks verdes, ¡has completado los requisitos técnicos del Lab 01!")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description='Cognitive GitOps Suite CLI')
    subparsers = parser.add_subparsers(title='comandos', dest='command')

    # init
    parser_init = subparsers.add_parser('init', help='Inicializa la estructura de carpetas')
    parser_init.set_defaults(func=cmd_init)

    # ingest
    parser_ingest = subparsers.add_parser('ingest', help='Ingesta un archivo desde data/input')
    parser_ingest.add_argument('file', help='Nombre del archivo en data/input a ingerir')
    parser_ingest.set_defaults(func=cmd_ingest)

    # analyze
    parser_analyze = subparsers.add_parser('analyze', help='Ejecuta el análisis cognitivo')
    parser_analyze.set_defaults(func=cmd_analyze)

    # deploy
    parser_deploy = subparsers.add_parser('deploy', help='Despliega servicios con docker-compose')
    parser_deploy.set_defaults(func=cmd_deploy)

    # status
    parser_status = subparsers.add_parser('status', help='Muestra el estado de los contenedores')
    parser_status.set_defaults(func=cmd_status)

    # verify
    parser_verify = subparsers.add_parser('verify', help='Valida el progreso del Lab')
    parser_verify.set_defaults(func=cmd_verify)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    if not hasattr(args, 'func'):
        parser.print_help()
        return
    args.func(args)


if __name__ == '__main__':
    main()
