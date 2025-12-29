<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:import href=".vendor/asciidoctor-fopub-main/build/fopub/docbook-xsl/fo-pdf.xsl"/>
	<xsl:param name="monospace.font.family" select="'LiberationMono, NotoSansDevanagari, NotoSansSC, Symbol, ZapfDingbats'"/>
	<xsl:param name="body.font.family" select="'serif, NotoSansDevanagari, NotoSansSC'"/>
	<xsl:param name="title.font.family" select="'sans-serif, NotoSansDevanagari, NotoSansSC'"/>
</xsl:stylesheet>
