#!/bin/bash
#
# gitops/sync.sh
# ---------------
#
# Este script realiza una sincronización simple de los resultados generados
# por la suite cognitiva a un repositorio Git remoto. Está pensado para
# ejecutarse en un entorno donde ya existen credenciales SSH configuradas y
# disponibles a través de variables de entorno. El script no realiza
# operaciones destructivas y valida la existencia del repositorio antes de
# intentar hacer push.

set -euo pipefail

REPO_URL="${GIT_REPO_URL:-}"
BRANCH="${GIT_BRANCH:-main}"
COMMIT_MSG="${GIT_COMMIT_MSG:-Automated sync from cognitive suite}"

if [ -z "$REPO_URL" ]; then
  echo "❌ GIT_REPO_URL no está definido. Configura la variable de entorno antes de ejecutar." >&2
  exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "🔄 Clonando $REPO_URL ..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$WORKDIR"

echo "📁 Copiando outputs al repositorio..."
cp -r outputs/* "$WORKDIR"/ || true

cd "$WORKDIR"
if [ -n "$(git status --porcelain)" ]; then
  git add .
  git commit -m "$COMMIT_MSG"
  echo "🚀 Realizando push a $BRANCH..."
  git push origin "$BRANCH"
  echo "✅ Sincronización completada."
else
  echo "ℹ️  No hay cambios que sincronizar."
fi