#!/usr/bin/env bash
set -euo pipefail

echo "Installing packages required for Asciidoctor -> DocBook -> FOP workflow"
sudo apt update

# System packages
sudo apt install -y \
  ruby \
  ruby-dev \
  build-essential \
  pkg-config \
  libffi-dev \
  libxml2-dev \
  libxslt1-dev \
  zlib1g-dev \
  graphviz \
  plantuml \
  default-jdk \
  fop \
  xsltproc \
  docbook-xsl \
  librsvg2-bin \
  imagemagick \
  libmagickwand-dev \
  fonts-dejavu-core

echo "Installing Ruby gems (Asciidoctor toolchain)"
GEMS=(asciidoctor asciidoctor-diagram asciidoctor-pdf rouge coderay)
for g in "${GEMS[@]}"; do
  if gem list -i "$g" >/dev/null 2>&1; then
    echo "gem $g already installed"
    continue
  fi
  echo "Installing gem: $g"
  if ! sudo gem install --no-document "$g"; then
    echo "Warning: failed to install gem '$g'. It may not exist in RubyGems or require additional setup." >&2
  fi
done

PIN_SHA="c5e24f7706d866f9fe374be377198a635193daf9"
VENDOR_DIR=".vendor/asciidoctor-fopub"

mkdir -p .vendor
if [ ! -d "$VENDOR_DIR" ]; then
  echo "Cloning asciidoctor-fopub into $VENDOR_DIR"
  if ! git clone https://github.com/asciidoctor/asciidoctor-fopub.git "$VENDOR_DIR"; then
    echo "Error: failed to clone asciidoctor-fopub into $VENDOR_DIR" >&2
    exit 1
  fi
else
  echo "$VENDOR_DIR already exists; fetching updates"
  git -C "$VENDOR_DIR" fetch --all --tags --prune || true
fi

if git -C "$VENDOR_DIR" rev-parse --verify --quiet "$PIN_SHA" >/dev/null; then
  git -C "$VENDOR_DIR" checkout --detach "$PIN_SHA" || { echo "Error: failed to checkout $PIN_SHA" >&2; exit 1; }
else
  echo "Pinned commit $PIN_SHA not found locally; attempting to fetch from origin"
  git -C "$VENDOR_DIR" fetch origin "$PIN_SHA" --depth=1 || true
  if git -C "$VENDOR_DIR" rev-parse --verify --quiet "$PIN_SHA" >/dev/null; then
    git -C "$VENDOR_DIR" checkout --detach "$PIN_SHA" || { echo "Error: failed to checkout $PIN_SHA after fetch" >&2; exit 1; }
  else
    echo "Error: pinned commit $PIN_SHA not found in remote repository" >&2
    exit 1
  fi
fi

chmod +x "$VENDOR_DIR/fopub" || true
echo "$PIN_SHA" > "$VENDOR_DIR/COMMIT"
echo "Vendored asciidoctor-fopub at $PIN_SHA"
