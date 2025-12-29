$ErrorActionPreference = "Stop"

Write-Host "Building AsciiDoc book with FOP (Windows)..." -ForegroundColor Cyan

# Relax Java XML security limits for transformations
$env:_JAVA_OPTIONS = "-Djavax.xml.accessExternalStylesheet=all -Djavax.xml.accessExternalDTD=all -Djdk.xml.xpathExprOpLimit=0 -Djdk.xml.xpathExprGrpLimit=0 -Djdk.xml.xpathTotalOpLimit=0 -Djdk.xml.entityExpansionLimit=0 -Djdk.xml.totalEntitySizeLimit=0 -Djdk.xml.maxOccurLimit=0 -Djdk.xml.enableExtensionFunctions=true"

# Ensure vendor tooling and fonts are prepared
& ./setup.ps1 | Write-Output

# Prepare output directory
Remove-Item ./output -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path ./output | Out-Null

# Create symlink from output/.vendor to .vendor (for relative XSL paths)
$vendorPath = (Resolve-Path ./.vendor).Path
$junctionPath = Join-Path (Resolve-Path ./output).Path ".vendor"
try {
    New-Item -ItemType Junction -Path $junctionPath -Target $vendorPath -Force -ErrorAction Stop | Out-Null
} catch {
    # Fallback: copy .vendor into output if junction fails
    Copy-Item $vendorPath $junctionPath -Recurse -Force
}

# Verify prerequisites
if (-not (Get-Command asciidoctor -ErrorAction SilentlyContinue)) {
    throw "'asciidoctor' not found. Install: gem install asciidoctor asciidoctor-diagram"
}
if (-not (Get-Command ruby -ErrorAction SilentlyContinue)) {
    throw "'ruby' not found. Please install Ruby."
}
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw "'java' not found. Please install a JDK (Java 11+ recommended)."
}

# Generate DocBook XML from AsciiDoc
Write-Host "Generating DocBook XML..." -ForegroundColor Yellow
& asciidoctor -b docbook5 -r asciidoctor-diagram -r ./transform.rb -a imagesdir=. -o ./output/book.xml ./book.adoc | Write-Output

# Post-process xrefs
Write-Host "Post-processing cross-references..." -ForegroundColor Yellow
& ruby ./transform_xreflabel.rb ./output/book.xml | Write-Output

# Build classpath from fopub libs
$fopubLib = Join-Path (Resolve-Path ./.vendor/asciidoctor-fopub-main/build/fopub/lib).Path ""
if (-not (Test-Path -LiteralPath $fopubLib)) {
    throw "fopub lib directory not found at $fopubLib. Ensure setup.ps1 completed successfully."
}

$jars = Get-ChildItem -LiteralPath $fopubLib -Filter *.jar | Sort-Object Name
# Prioritize xalan and xslthl at the front of classpath
$priority = $jars | Where-Object {$_.Name -like "xalan*" -or $_.Name -like "serializer*" -or $_.Name -like "xslthl*"}
$rest = $jars | Where-Object {$_.Name -notlike "xalan*" -and $_.Name -notlike "serializer*" -and $_.Name -notlike "xslthl*"}
$jarPaths = @()
$jarPaths += ($priority | Select-Object -ExpandProperty FullName)
$jarPaths += ($rest | Select-Object -ExpandProperty FullName)
$cp = ($jarPaths -join ';')

# Paths for parameters (use forward slashes for FO)
$root = (Resolve-Path .).Path -replace "\\","/"
$xslthlCfg = "$root/.vendor/asciidoctor-fopub-main/build/fopub/docbook-xsl/xslthl-config.xml"
$admonImg = "file:///$root/.vendor/asciidoctor-fopub-main/build/fopub/docbook/images/"
$calloutImg = "file:///$root/.vendor/asciidoctor-fopub-main/build/fopub/docbook/images/callouts/"

# Run Apache FOP CLI via Java with configured classpath and params
Write-Host "Converting to PDF with FOP..." -ForegroundColor Yellow
$javaArgs = @(
    "-Djavax.xml.accessExternalStylesheet=all",
    "-Djavax.xml.accessExternalDTD=all",
    "-Djdk.xml.xpathExprOpLimit=0",
    "-Djdk.xml.xpathExprGrpLimit=0",
    "-Djdk.xml.xpathTotalOpLimit=0",
    "-Djdk.xml.config.file=$root/jaxp.properties",
    "-cp", $cp,
    "org.apache.fop.cli.Main",
    "-c", "$root/.vendor/fop.xconf",
    "-xml", "$root/output/book.xml",
    "-xsl", "$root/custom.xsl",
    "-param", "img.src.path", "file:///$root/",
    "-param", "highlight.xslthl.config", "file:///$xslthlCfg",
    "-param", "admon.graphics.path", $admonImg,
    "-param", "callout.graphics.path", $calloutImg,
    "-pdf", "$root/output/book.pdf"
)

& java @javaArgs

if (Test-Path -LiteralPath ./output/book.pdf) {
    Write-Host "Created ./output/book.pdf" -ForegroundColor Green
    try { Start-Process ./output/book.pdf } catch { }
} else {
    Write-Host "Build failed: ./output/book.pdf not found" -ForegroundColor Red
    Write-Host "Check the FOP output above for errors." -ForegroundColor Yellow
    exit 1
}