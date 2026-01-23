#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Run from inside a git repository."
  exit 1
fi

out_dir="${1:-dist}"
name="${2:-cognitive-suite-src}"
sha="$(git rev-parse --short HEAD)"

mkdir -p "$out_dir"

zip_path="${out_dir}/${name}-${sha}.zip"
tar_path="${out_dir}/${name}-${sha}.tar.gz"

git archive --format=zip --output "$zip_path" HEAD
git archive --format=tar HEAD | gzip -c > "$tar_path"

echo "Wrote:"
echo "  $zip_path"
echo "  $tar_path"
