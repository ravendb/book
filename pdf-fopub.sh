#!/usr/bin/env bash
set -euo pipefail

FOPUB=.vendor/asciidoctor-fopub/fopub

if [ ! -x "$FOPUB" ]; then
  echo "Vendored fopub not found at $FOPUB. Run ./setup.sh to vendor it." >&2
  exit 1
fi

rm -rf ./build || true
mkdir -p ./build ./output

asciidoctor -b docbook5 -o ./build/book.xml ./book.adoc

FOPUB_DIR="$(dirname "$FOPUB")"
DOCBOOK_DIR_REL="$FOPUB_DIR/build/fopub/docbook"
DOCBOOK_DIR_ABS="$(readlink -f "$DOCBOOK_DIR_REL")"
PROJECT_ROOT_ABS="$(readlink -f .)"

"$FOPUB" ./build/book.xml \
  -param admon.graphics.path "file://$DOCBOOK_DIR_ABS/images/" \
  -param callout.graphics.path "file://$DOCBOOK_DIR_ABS/images/callouts/" \
  -param img.src.path "$PROJECT_ROOT_ABS/" \
  "$@" 2>&1 | sed -E '/org\\.apache\\.fop|Rendered page #[0-9]+/d'
FOP_EXIT=${PIPESTATUS[0]:-0}
if [ "$FOP_EXIT" -ne 0 ]; then
  echo "fopub failed with exit code $FOP_EXIT" >&2
  exit $FOP_EXIT
fi

GENERATED=$(ls -1t ./build/book*.pdf 2>/dev/null | head -n1 || true)
if [ -n "$GENERATED" ] && [ -f "$GENERATED" ]; then
  mv "$GENERATED" ./output/book.pdf
  xdg-open ./output/book.pdf &
  exit 0
else
  echo "fopub failed to create ./output/book.pdf (no book*.pdf in ./build)" >&2
  exit 1
fi
