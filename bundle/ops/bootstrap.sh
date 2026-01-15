#!/bin/bash
# ops/bootstrap.sh
# -----------------
#
# Script de arranque orientado a operaciones y DevOps. Construye y
# ejecuta los contenedores Docker, ejecuta pruebas básicas y prepara
# artefactos para empaquetado y publicación. Este script está pensado
# para integrarse con CI/CD o para pruebas manuales de producción.

set -euo pipefail
echo "🔧 Ejecutando entorno de integración para mantenimiento..."

# Construir imágenes y lanzar servicios
docker compose build
docker compose up -d

# Esperar un momento para que los contenedores se inicialicen
sleep 5

# Verificar estado de los contenedores
docker compose ps

# Ejecutar script de pruebas (si existe)
if [ -f test-bootstrap.sh ]; then
  bash test-bootstrap.sh
fi

echo "✅ Bootstrap DevOps completo. Listo para release o test continuo."