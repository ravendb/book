#!/usr/bin/env bash
export _JAVA_OPTIONS="-Djavax.xml.accessExternalStylesheet=all -Djavax.xml.accessExternalDTD=all -Djdk.xml.xpathExprOpLimit=0 -Djdk.xml.xpathExprGrpLimit=0 -Djdk.xml.xpathTotalOpLimit=0 -Djdk.xml.entityExpansionLimit=0 -Djdk.xml.totalEntitySizeLimit=0 -Djdk.xml.maxOccurLimit=0 -Djdk.xml.enableExtensionFunctions=true"
set -euo pipefail

# Ensure fonts and config are set up before build
./font-setup.sh

rm -rf ./output || true
mkdir -p ./output

if [ ! -d .vendor/asciidoctor-fopub-main ]; then
  echo "Downloading asciidoctor-fopub..."
  mkdir -p .vendor
  wget -O .vendor/fopub.zip https://github.com/asciidoctor/asciidoctor-fopub/archive/refs/heads/main.zip
  unzip -q .vendor/fopub.zip -d .vendor
  rm .vendor/fopub.zip
  
  # Fix broken remote imports in DocBook XSL customizations (source)
  sed -i 's|http://docbook.sourceforge.net/release/xsl/current/highlighting/common.xsl|../docbook/highlighting/common.xsl|' .vendor/asciidoctor-fopub-main/src/dist/docbook-xsl/highlight.xsl
  sed -i 's|https://cdn.docbook.org/release/xsl/current/fo/docbook.xsl|../docbook/fo/docbook.xsl|' .vendor/asciidoctor-fopub-main/src/dist/docbook-xsl/fo-pdf.xsl
  sed -i 's|https://cdn.docbook.org/release/xsl/current/xhtml/docbook.xsl|../docbook/xhtml/docbook.xsl|' .vendor/asciidoctor-fopub-main/src/dist/docbook-xsl/xhtml.xsl
fi

if [ ! -d .vendor/asciidoctor-fopub-main/build/fopub ]; then
  echo "Building asciidoctor-fopub..."
  (cd .vendor/asciidoctor-fopub-main && chmod +x gradlew && ./gradlew installApp)
fi

# Ensure the fix is applied to the build directory as well
for f in highlight.xsl fo-pdf.xsl xhtml.xsl; do
  path=".vendor/asciidoctor-fopub-main/build/fopub/docbook-xsl/$f"
  if [ -f "$path" ]; then
    sed -i 's|http://docbook.sourceforge.net/release/xsl/current/highlighting/common.xsl|../docbook/highlighting/common.xsl|' "$path"
    sed -i 's|https://cdn.docbook.org/release/xsl/current/fo/docbook.xsl|../docbook/fo/docbook.xsl|' "$path"
    sed -i 's|https://cdn.docbook.org/release/xsl/current/xhtml/docbook.xsl|../docbook/xhtml/docbook.xsl|' "$path"
  fi
done


CUR_DIR=$(pwd)
ln -s "$CUR_DIR/.vendor" "$CUR_DIR/output/.vendor" || true
asciidoctor -b docbook5 -r asciidoctor-diagram -r ./transform.rb -a imagesdir=. -o ./output/book.xml ./book.adoc

./transform_xreflabel.rb output/book.xml

# Construct classpath with fopub extensions and system FOP
FOPUB_LIB="$PWD/.vendor/asciidoctor-fopub-main/build/fopub/lib"
CP="$FOPUB_LIB/xalan-2.7.0.jar:$FOPUB_LIB/xslthl-2.1.0.jar"

# Construct classpath with fopub's modified InputHandler and extensions
FOPUB_LIB="$PWD/.vendor/asciidoctor-fopub-main/build/fopub/lib"
# Prepend fopub-1.0.0-SNAPSHOT.jar to override FOP's InputHandler
CP="$FOPUB_LIB/fopub-1.0.0-SNAPSHOT.jar:$FOPUB_LIB/xalan-2.7.0.jar:$FOPUB_LIB/xslthl-2.1.0.jar"

java -Djavax.xml.accessExternalStylesheet=all \
  -Djavax.xml.accessExternalDTD=all \
  -Djdk.xml.xpathExprOpLimit=0 \
  -Djdk.xml.xpathExprGrpLimit=0 \
  -Djdk.xml.xpathTotalOpLimit=0 \
  -Djdk.xml.config.file=$PWD/jaxp.properties \
  -cp "$CP:/usr/share/java/fop.jar:/usr/share/java/fop-core.jar:/usr/share/java/fop-events.jar:/usr/share/java/fop-util.jar:/usr/share/java/xmlgraphics-commons.jar:/usr/share/java/commons-io.jar:/usr/share/java/commons-logging.jar:/usr/share/java/batik-all.jar:/usr/share/java/avalon-framework.jar" \
  org.apache.fop.cli.Main \
  -c .vendor/fop.xconf -xml ./output/book.xml -xsl custom.xsl \
  -param img.src.path "$CUR_DIR/" \
  -param highlight.xslthl.config "file://$CUR_DIR/.vendor/asciidoctor-fopub-main/build/fopub/docbook-xsl/xslthl-config.xml" \
  -param admon.graphics.path "$CUR_DIR/.vendor/asciidoctor-fopub-main/build/fopub/docbook/images/" \
  -param callout.graphics.path "$CUR_DIR/.vendor/asciidoctor-fopub-main/build/fopub/docbook/images/callouts/" \
  -pdf ./output/book.pdf 2>&1 
  
if [ -f ./output/book.pdf ]; then
  echo "Created ./output/book.pdf"
  if command -v xdg-open >/dev/null 2>&1; then
    #echo "Opening ./output/book.pdf..."
    xdg-open ./output/book.pdf &
  fi
else
  echo "Build failed: ./output/book.pdf not found" >&2
  exit 1
fi
