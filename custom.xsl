<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:import href=".vendor/asciidoctor-fopub-main/build/fopub/docbook-xsl/fo-pdf.xsl"/>
  <xsl:param name="monospace.font.family" select="'LiberationMono, NotoSansMono, NotoSansSymbols2, NotoSansDevanagari, NotoSansSC, Symbol, ZapfDingbats'"/>
  <xsl:param name="body.font.family" select="'LiberationSerif, NotoSansDevanagari, NotoSansSC'"/>
  <xsl:param name="title.font.family" select="'LiberationSans, NotoSansDevanagari, NotoSansSC'"/>
</xsl:stylesheet>
