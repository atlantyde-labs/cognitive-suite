#!/bin/bash
# scripts/build-deb.sh
# ---------------------
#
# Construye un paquete .deb de la Cognitive GitOps Suite para su instalación
# en sistemas basados en Debian/Ubuntu. El script genera la estructura de
# directorios necesaria, copia los archivos del proyecto y crea el paquete
# con `dpkg-deb`. Se puede pasar un número de versión como primer
# argumento; por defecto se usa 1.0.0.

set -euo pipefail

VERSION="${1:-1.0.0}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PKG_NAME="cognitive-suite"
PKG_DIR="$ROOT_DIR/tmp/${PKG_NAME}_${VERSION}"

# Limpiar directorio de trabajo
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/local/lib/$PKG_NAME"
mkdir -p "$PKG_DIR/usr/local/bin"

# Copiar código fuente al directorio de instalación
cp -r "$ROOT_DIR/cogctl.py" "$PKG_DIR/usr/local/lib/$PKG_NAME/"
cp -r "$ROOT_DIR/ingestor" "$PKG_DIR/usr/local/lib/$PKG_NAME/ingestor"
cp -r "$ROOT_DIR/pipeline" "$PKG_DIR/usr/local/lib/$PKG_NAME/pipeline"
cp -r "$ROOT_DIR/frontend" "$PKG_DIR/usr/local/lib/$PKG_NAME/frontend"
cp -r "$ROOT_DIR/gitops" "$PKG_DIR/usr/local/lib/$PKG_NAME/gitops"
cp -r "$ROOT_DIR/schemas" "$PKG_DIR/usr/local/lib/$PKG_NAME/schemas"
cp -r "$ROOT_DIR/docs" "$PKG_DIR/usr/local/lib/$PKG_NAME/docs"
cp -r "$ROOT_DIR/dev" "$PKG_DIR/usr/local/lib/$PKG_NAME/dev"
cp -r "$ROOT_DIR/ops" "$PKG_DIR/usr/local/lib/$PKG_NAME/ops"
cp -r "$ROOT_DIR/.github" "$PKG_DIR/usr/local/lib/$PKG_NAME/.github"
cp "$ROOT_DIR/Makefile" "$PKG_DIR/usr/local/lib/$PKG_NAME/"
cp "$ROOT_DIR/docker-compose.yml" "$PKG_DIR/usr/local/lib/$PKG_NAME/"
cp "$ROOT_DIR/docker-compose.prod.yml" "$PKG_DIR/usr/local/lib/$PKG_NAME/"
cp "$ROOT_DIR/test-bootstrap.sh" "$PKG_DIR/usr/local/lib/$PKG_NAME/"

# Crear script wrapper para ejecutar la CLI desde /usr/local/bin
cat > "$PKG_DIR/usr/local/bin/cogctl" <<'WRAPEOF'
#!/bin/sh
python3 /usr/local/lib/cognitive-suite/cogctl.py "$@"
WRAPEOF
chmod +x "$PKG_DIR/usr/local/bin/cogctl"

# Generar archivo control
cat > "$PKG_DIR/DEBIAN/control" <<EOF
Package: cognitive-suite
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: python3 (>= 3.8)
Maintainer: Atlantyde Labs
Description: Cognitive GitOps Suite para ingesta, análisis semántico y GitOps
EOF

# Construir paquete
OUTPUT_DIR="$ROOT_DIR/dist"
mkdir -p "$OUTPUT_DIR"
dpkg-deb --build "$PKG_DIR" "$OUTPUT_DIR/${PKG_NAME}_${VERSION}_all.deb"
echo "✅ Paquete generado en $OUTPUT_DIR/${PKG_NAME}_${VERSION}_all.deb"