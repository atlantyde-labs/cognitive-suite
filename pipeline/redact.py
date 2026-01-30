#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pipeline/redact.py
------------------

Script de redacción para el Lab 02.
Este script actúa como un wrapper sobre analyze.py pero forzando
el modo de redacción para proteger la soberanía de los datos.
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description='Redacción de datos sensibles (Lab 02)')
    parser.add_argument('--input', default='outputs/raw', help='Directorio con archivos de texto')
    parser.add_argument('--output', default='outputs/insights', help='Directorio de salida para los insights seguros')
    args = parser.parse_args()

    # Asegurar que el directorio de salida existe
    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)

    # Definir el archivo de salida final
    output_file = out_dir / 'analysis.json'

    print("🛡️ Activando Escudo de Privacidad (Soberanía de Datos)...")

    # Configurar el entorno para forzar la redacción
    env = os.environ.copy()
    env["COGNITIVE_REDACT"] = "1"
    env["COGNITIVE_ENV"] = "prod"
    if "COGNITIVE_HASH_SALT" not in env:
        env["COGNITIVE_HASH_SALT"] = "lab_secret_salt_2026"

    # Determinar la ruta a analyze.py
    base_dir = Path(__file__).resolve().parent
    analyze_script = base_dir / 'analyze.py'

    if not analyze_script.exists():
        print(f"❌ Error: No se encuentra {analyze_script}")
        sys.exit(1)

    # Verificar si spaCy está disponible en el entorno actual
    try:
        import spacy
    except ImportError:
        print("⚠️ Advertencia: spaCy no está disponible en este entorno de Python.")
        print("💡 Consejo: Asegúrate de estar usando el entorno virtual (.venv)")
        print("   Ejecuta: .venv\\Scripts\\python.exe pipeline\\redact.py ...")

    # Ejecutar el pipeline de análisis con redacción forzada
    try:
        subprocess.run([
            sys.executable,
            str(analyze_script),
            '--input', args.input,
            '--output', str(output_file)
        ], env=env, check=True)

        print(f"\n✅ Redacción completada con éxito.")
        print(f"🔒 Los datos sensibles han sido enmascarados.")
        print(f"💾 Archivo seguro generado en: {output_file.absolute()}")

    except subprocess.CalledProcessError as e:
        print(f"❌ Error durante el proceso de redacción: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
