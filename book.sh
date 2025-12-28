#/usr/bin/env bash
set -euo pipefail

rm -rf ./output || true
mkdir -p ./output


if [ ! -d .vendor/asciidoctor-fopub-main ]; then
  echo "Downloading asciidoctor-fopub..."
  mkdir -p .vendor
  wget -O .vendor/fopub.zip https://github.com/asciidoctor/asciidoctor-fopub/archive/refs/heads/main.zip
  unzip -q .vendor/fopub.zip -d .vendor
  rm .vendor/fopub.zip
fi


CUR_DIR=$(pwd)
ln -s "$CUR_DIR/.vendor" "$CUR_DIR/output/.vendor" || true
asciidoctor -b docbook5 -r asciidoctor-diagram -r ./transform.rb -a imagesdir=. -o ./output/book.xml ./book.adoc

./transform_xreflabel.rb output/book.xml

.vendor/asciidoctor-fopub-main/fopub ./output/book.xml \
  -param img.src.path "$CUR_DIR/" \
  -o ./output/book.pdf 2>&1 \
  | grep -v 'org.apache.fop.events.LoggingEventListener processEvent'

if [ -f ./output/book.pdf ]; then
  echo "Created ./output/book.pdf"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open ./output/book.pdf &
  fi
else
  echo "Build failed: ./output/book.pdf not found" >&2
  exit 1
fi
