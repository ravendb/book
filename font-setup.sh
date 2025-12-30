# Unicode Font Support for PDF
#
# This section ensures that the PDF output supports all Unicode characters (e.g., Hindi, Chinese) in code blocks and programlistings.
#
# 1. Download required fonts (Noto Sans Devanagari, Noto Sans SC) if not present.
# 2. Configure FOP to use these fonts as fallbacks for monospace.
# 3. Set the monospace.font.family XSL parameter to include the fallback fonts.
#
# You may need to adjust the paths if you change the directory structure.

FONTS_DIR=".vendor/fonts"
FOP_CONF=".vendor/fop.xconf"
CUSTOM_XSL="custom.xsl"

mkdir -p "$FONTS_DIR"
# Download Liberation Mono (from official Liberation Fonts GitHub TTF tar.gz)
if [ ! -s "$FONTS_DIR/LiberationMono-Regular.ttf" ] || [ ! -s "$FONTS_DIR/LiberationSerif-Regular.ttf" ] || [ ! -s "$FONTS_DIR/LiberationSans-Regular.ttf" ]; then
  rm -f "$FONTS_DIR/LiberationMono-Regular.ttf" "$FONTS_DIR/LiberationSerif-Regular.ttf" "$FONTS_DIR/LiberationSans-Regular.ttf"
  TMP_LIBERATION="liberation-fonts-ttf-2.1.5.tar.gz"
  wget -O "$TMP_LIBERATION" "https://github.com/liberationfonts/liberation-fonts/files/7261482/liberation-fonts-ttf-2.1.5.tar.gz"
  tar -xzf "$TMP_LIBERATION"
  cp liberation-fonts-ttf-2.1.5/LiberationMono-Regular.ttf "$FONTS_DIR/"
  cp liberation-fonts-ttf-2.1.5/LiberationSerif-Regular.ttf "$FONTS_DIR/"
  cp liberation-fonts-ttf-2.1.5/LiberationSans-Regular.ttf "$FONTS_DIR/"
  rm -rf liberation-fonts-ttf-2.1.5 "$TMP_LIBERATION"
fi
# Download Noto Sans Devanagari (from Google Fonts GitHub)
if [ ! -s "$FONTS_DIR/NotoSansDevanagari-Regular.ttf" ]; then
  rm -f "$FONTS_DIR/NotoSansDevanagari-Regular.ttf"
  wget -O "$FONTS_DIR/NotoSansDevanagari-Regular.ttf" "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansDevanagari/NotoSansDevanagari-Regular.ttf"
fi

# Download Noto Sans SC (Simplified Chinese)
if [ ! -s "$FONTS_DIR/NotoSansSC-Regular.otf" ]; then
  rm -f "$FONTS_DIR/NotoSansSC-Regular.otf"
  wget -O "$FONTS_DIR/NotoSansSC-Regular.otf" "https://github.com/googlefonts/noto-cjk/raw/main/Sans/SubsetOTF/SC/NotoSansSC-Regular.otf"
fi

# Download Noto Sans Mono for better Unicode coverage in code blocks
if [ ! -s "$FONTS_DIR/NotoSansMono-Regular.ttf" ]; then
  rm -f "$FONTS_DIR/NotoSansMono-Regular.ttf"
  wget -O "$FONTS_DIR/NotoSansMono-Regular.ttf" "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansMono/NotoSansMono-Regular.ttf"
fi

# Download Noto Sans Symbols2 font for emoji and special symbol support
if [ ! -s "$FONTS_DIR/NotoSansSymbols2-Regular.ttf" ]; then
  rm -f "$FONTS_DIR/NotoSansSymbols2-Regular.ttf"
  wget -O "$FONTS_DIR/NotoSansSymbols2-Regular.ttf" "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansSymbols2/NotoSansSymbols2-Regular.ttf"
fi

# Always update FOP config to ensure all fonts are included
cat > "$FOP_CONF" <<EOF
<fop version="1.0">
  <renderers>
    <renderer mime="application/pdf">
      <fonts>
        <font embed-url="${PWD}/$FONTS_DIR/LiberationMono-Regular.ttf">
          <font-triplet name="LiberationMono" style="normal" weight="normal"/>
        </font>
        <font embed-url="${PWD}/$FONTS_DIR/LiberationSerif-Regular.ttf">
          <font-triplet name="LiberationSerif" style="normal" weight="normal"/>
        </font>
        <font embed-url="${PWD}/$FONTS_DIR/LiberationSans-Regular.ttf">
          <font-triplet name="LiberationSans" style="normal" weight="normal"/>
        </font>
        <font embed-url="${PWD}/$FONTS_DIR/NotoSansMono-Regular.ttf">
          <font-triplet name="NotoSansMono" style="normal" weight="normal"/>
        </font>
        <font embed-url="${PWD}/$FONTS_DIR/NotoSansSymbols2-Regular.ttf">
          <font-triplet name="NotoSansSymbols2" style="normal" weight="normal"/>
        </font>
        <font embed-url="${PWD}/$FONTS_DIR/NotoSansDevanagari-Regular.ttf">
          <font-triplet name="NotoSansDevanagari" style="normal" weight="normal"/>
        </font>
        <font embed-url="${PWD}/$FONTS_DIR/NotoSansSC-Regular.otf">
          <font-triplet name="NotoSansSC" style="normal" weight="normal"/>
        </font>
        <auto-detect/>
      </fonts>
    </renderer>
  </renderers>
</fop>
EOF


# Write a valid XSLT file if missing
if [ ! -f "$CUSTOM_XSL" ]; then
  cat > "$CUSTOM_XSL" <<EOF
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:import href=".vendor/asciidoctor-fopub-main/build/fopub/docbook-xsl/fo-pdf.xsl"/>
  <xsl:param name="monospace.font.family" select="'LiberationMono, NotoSansMono, NotoSansSymbols2, NotoSansDevanagari, NotoSansSC, Symbol, ZapfDingbats'"/>
  <xsl:param name="body.font.family" select="'LiberationSerif, NotoSansDevanagari, NotoSansSC'"/>
  <xsl:param name="title.font.family" select="'LiberationSans, NotoSansDevanagari, NotoSansSC'"/>
</xsl:stylesheet>
EOF
fi

