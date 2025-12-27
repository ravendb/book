#/usr/bin/env bash
set -euo pipefail

# Remove and recreate build directory (quietly)
rm -rf ./build || true
mkdir -p ./build

# Run Asciidoctor PDF with diagrams and local transform script
asciidoctor-pdf -r asciidoctor-diagram -r ./transform.rb --destination-dir ./output ./book.adoc

if [ -f ./output/book.pdf ]; then
  echo "Created ./output/book.pdf"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open ./output/book.pdf &
  fi
else
  echo "Build failed: ./output/book.pdf not found" >&2
  exit 1
fi
