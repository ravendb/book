param([switch]$Force)

$ErrorActionPreference = "Stop"

function Ensure-Directory($Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Replace-InFile([string]$file,[hashtable]$replacements) {
    if (Test-Path -LiteralPath $file) {
        $content = Get-Content -LiteralPath $file -Raw
        foreach ($k in $replacements.Keys) {
            $content = $content -replace [Regex]::Escape($k), [string]$replacements[$k]
        }
        Set-Content -LiteralPath $file -Value $content -Encoding UTF8
    }
}

Write-Host "Setting up vendor tooling and fonts..." -ForegroundColor Cyan

$root = (Get-Location).Path
$vendorDir = Join-Path $root ".vendor"
Ensure-Directory $vendorDir

$fopubRoot = Join-Path $vendorDir "asciidoctor-fopub-main"
if ($Force -or -not (Test-Path -LiteralPath $fopubRoot)) {
    Write-Host "Downloading asciidoctor-fopub..." -ForegroundColor Yellow
    $zipPath = Join-Path $vendorDir "fopub.zip"
    Invoke-WebRequest -Uri "https://github.com/asciidoctor/asciidoctor-fopub/archive/refs/heads/main.zip" -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $vendorDir -Force
    Remove-Item $zipPath -Force
}

# Fix remote imports in DocBook XSL customizations (source repo)
$srcXslDir = Join-Path $fopubRoot "src\dist\docbook-xsl"
Replace-InFile (Join-Path $srcXslDir "highlight.xsl") (@{
    "http://docbook.sourceforge.net/release/xsl/current/highlighting/common.xsl" = "../docbook/highlighting/common.xsl"
})
Replace-InFile (Join-Path $srcXslDir "fo-pdf.xsl") (@{
    "https://cdn.docbook.org/release/xsl/current/fo/docbook.xsl" = "../docbook/fo/docbook.xsl"
})
Replace-InFile (Join-Path $srcXslDir "xhtml.xsl") (@{
    "https://cdn.docbook.org/release/xsl/current/xhtml/docbook.xsl" = "../docbook/xhtml/docbook.xsl"
})

# Build fopub if not already built
$fopubBuildDir = Join-Path $fopubRoot "build\fopub"
if ($Force -or -not (Test-Path -LiteralPath $fopubBuildDir)) {
    Write-Host "Building asciidoctor-fopub (requires JDK)..." -ForegroundColor Yellow
    $gradlewBat = Join-Path $fopubRoot "gradlew.bat"
    if (-not (Test-Path -LiteralPath $gradlewBat)) {
        throw "gradlew.bat not found in $fopubRoot."
    }
    
    # Check if javac is available
    $javacAvailable = $null -ne (Get-Command javac -ErrorAction SilentlyContinue)
    if (-not $javacAvailable) {
        Write-Warning "JDK not found (javac not available). Using partial gradle extraction + standalone FOP..."
        
        # Run gradle extraction tasks (doesn't require javac, only JRE)
        Push-Location $fopubRoot
        try {
            & .\gradlew.bat extractDocbookXml extractDocbookXsl --no-daemon 2>&1 | Write-Output
        } finally {
            Pop-Location
        }
        
        # Download Apache FOP binary distribution
        $fopVersion = "2.9"
        $fopZip = Join-Path $vendorDir "fop-$fopVersion-bin.zip"
        $fopExtractDir = Join-Path $vendorDir "fop-$fopVersion"
        $fopDir = Join-Path $fopExtractDir "fop"
        
        if (-not (Test-Path -LiteralPath $fopDir)) {
            Write-Host "Downloading Apache FOP $fopVersion..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri "https://archive.apache.org/dist/xmlgraphics/fop/binaries/fop-$fopVersion-bin.zip" -OutFile $fopZip
            Expand-Archive -Path $fopZip -DestinationPath $vendorDir -Force
            Remove-Item $fopZip -Force
        }
        
        # Create a minimal fopub structure that book.ps1 expects
        $minimalFopubLib = Join-Path $fopubBuildDir "lib"
        Ensure-Directory $minimalFopubLib
        
        # Copy FOP jars to expected location
        Get-ChildItem -Path (Join-Path $fopDir "lib\*.jar") | ForEach-Object {
            Copy-Item $_.FullName -Destination $minimalFopubLib -Force
        }
        Get-ChildItem -Path (Join-Path $fopDir "build\*.jar") | ForEach-Object {
            Copy-Item $_.FullName -Destination $minimalFopubLib -Force
        }
        
        # Download xslthl (syntax highlighting for code blocks)
        $xslthlJar = Join-Path $minimalFopubLib "xslthl-2.1.0.jar"
        if (-not (Test-Path -LiteralPath $xslthlJar)) {
            Write-Host "Downloading xslthl..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/net/sf/xslthl/xslthl/2.1.0/xslthl-2.1.0.jar" -OutFile $xslthlJar
        }
        
        # Download Xalan (XSLT processor that supports Java extension functions)
        $xalanJar = Join-Path $minimalFopubLib "xalan-2.7.3.jar"
        if (-not (Test-Path -LiteralPath $xalanJar)) {
            Write-Host "Downloading Xalan..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/xalan/xalan/2.7.3/xalan-2.7.3.jar" -OutFile $xalanJar
        }
        
        $serializerJar = Join-Path $minimalFopubLib "serializer-2.7.3.jar"
        if (-not (Test-Path -LiteralPath $serializerJar)) {
            Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/xalan/serializer/2.7.3/serializer-2.7.3.jar" -OutFile $serializerJar
        }
        
        # Copy docbook resources from source
        $docbookXslSrc = Join-Path $fopubRoot "src\dist\docbook-xsl"
        $docbookXslDest = Join-Path $fopubBuildDir "docbook-xsl"
        if (-not (Test-Path -LiteralPath $docbookXslDest)) {
            Copy-Item $docbookXslSrc -Destination $docbookXslDest -Recurse -Force
        }
        
        # Extract and copy docbook resources
        $buildUnpackedDir = Join-Path $fopubRoot "build\unpacked"
        if (Test-Path -LiteralPath $buildUnpackedDir) {
            # Copy entire unpacked docbook directory
            $unpackedDocbook = Join-Path $buildUnpackedDir "docbook"
            $destDocbook = Join-Path $fopubBuildDir "docbook"
            if (Test-Path -LiteralPath $unpackedDocbook) {
                Copy-Item $unpackedDocbook -Destination $destDocbook -Recurse -Force
            }
        } else {
            Write-Warning "build/unpacked not found. DocBook resources may be incomplete."
        }
        
        Write-Host "Using Apache FOP $fopVersion with extracted DocBook resources." -ForegroundColor Green
    } else {
        Push-Location $fopubRoot
        try {
            & .\gradlew.bat installDist --no-daemon 2>&1 | Write-Output
            if ($LASTEXITCODE -ne 0) {
                throw "Gradle build failed."
            }
        } finally {
            Pop-Location
        }
    }
}

# Apply fixes inside the build directory
$builtXslDir = Join-Path $fopubBuildDir "docbook-xsl"
if (Test-Path -LiteralPath $builtXslDir) {
    Replace-InFile (Join-Path $builtXslDir "highlight.xsl") (@{
        "http://docbook.sourceforge.net/release/xsl/current/highlighting/common.xsl" = "../docbook/highlighting/common.xsl"
    })
    Replace-InFile (Join-Path $builtXslDir "fo-pdf.xsl") (@{
        "https://cdn.docbook.org/release/xsl/current/fo/docbook.xsl" = "../docbook/fo/docbook.xsl"
    })
    Replace-InFile (Join-Path $builtXslDir "xhtml.xsl") (@{
        "https://cdn.docbook.org/release/xsl/current/xhtml/docbook.xsl" = "../docbook/xhtml/docbook.xsl"
    })
}

# Fonts setup for FOP
$fontsDir = Join-Path $vendorDir "fonts"
Ensure-Directory $fontsDir

$libMono = Join-Path $fontsDir "LiberationMono-Regular.ttf"
$libSerif = Join-Path $fontsDir "LiberationSerif-Regular.ttf"
$libSans = Join-Path $fontsDir "LiberationSans-Regular.ttf"
if ($Force -or -not (Test-Path -LiteralPath $libMono)) {
    Write-Host "Fetching Liberation fonts..." -ForegroundColor Yellow
    $tarGz = Join-Path $root "liberation-fonts-ttf-2.1.5.tar.gz"
    Invoke-WebRequest -Uri "https://github.com/liberationfonts/liberation-fonts/files/7261482/liberation-fonts-ttf-2.1.5.tar.gz" -OutFile $tarGz
    try {
        tar -xzf $tarGz
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationMono-Regular.ttf") -Destination $libMono -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSerif-Regular.ttf") -Destination $libSerif -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSans-Regular.ttf") -Destination $libSans -Force
        Remove-Item (Join-Path $root "liberation-fonts-ttf-2.1.5") -Recurse -Force
    } catch {
        Write-Warning "Extraction of tar.gz failed. Ensure 'tar' is available, or place Liberation fonts into $fontsDir manually."
    } finally {
        Remove-Item $tarGz -Force -ErrorAction SilentlyContinue
    }
}

$notoDev = Join-Path $fontsDir "NotoSansDevanagari-Regular.ttf"
if ($Force -or -not (Test-Path -LiteralPath $notoDev)) {
    Write-Host "Fetching NotoSansDevanagari-Regular.ttf..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansDevanagari/NotoSansDevanagari-Regular.ttf" -OutFile $notoDev
}

$notoSc = Join-Path $fontsDir "NotoSansSC-Regular.otf"
if ($Force -or -not (Test-Path -LiteralPath $notoSc)) {
    Write-Host "Fetching NotoSansSC-Regular.otf..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/googlefonts/noto-cjk/raw/main/Sans/SubsetOTF/SC/NotoSansSC-Regular.otf" -OutFile $notoSc
}

# Download Noto Sans Mono for better Unicode coverage in code blocks
$notoMono = Join-Path $fontsDir "NotoSansMono-Regular.ttf"
if ($Force -or -not (Test-Path -LiteralPath $notoMono)) {
    Write-Host "Fetching NotoSansMono-Regular.ttf..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansMono/NotoSansMono-Regular.ttf" -OutFile $notoMono
}

# Download Noto Sans Symbols2 font for emoji and special symbol support
$notoSymbols = Join-Path $fontsDir "NotoSansSymbols2-Regular.ttf"
if ($Force -or -not (Test-Path -LiteralPath $notoSymbols)) {
    Write-Host "Fetching NotoSansSymbols2-Regular.ttf (emoji font)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansSymbols2/NotoSansSymbols2-Regular.ttf" -OutFile $notoSymbols
}

# Write FOP config
$fopConf = Join-Path $vendorDir "fop.xconf"
$fontsDirUri = "file:///" + ((Resolve-Path $fontsDir).Path -replace "\\","/")
$fopConfContent = @"
<fop version="1.0">
  <renderers>
    <renderer mime="application/pdf">
      <fonts>
        <font embed-url="${fontsDirUri}/LiberationMono-Regular.ttf">
          <font-triplet name="LiberationMono" style="normal" weight="normal"/>
        </font>
        <font embed-url="${fontsDirUri}/LiberationSerif-Regular.ttf">
          <font-triplet name="LiberationSerif" style="normal" weight="normal"/>
        </font>
        <font embed-url="${fontsDirUri}/LiberationSans-Regular.ttf">
          <font-triplet name="LiberationSans" style="normal" weight="normal"/>
        </font>
        <font embed-url="${fontsDirUri}/NotoSansMono-Regular.ttf">
          <font-triplet name="NotoSansMono" style="normal" weight="normal"/>
        </font>
        <font embed-url="${fontsDirUri}/NotoSansSymbols2-Regular.ttf">
          <font-triplet name="NotoSansSymbols2" style="normal" weight="normal"/>
        </font>
        <font embed-url="${fontsDirUri}/NotoSansDevanagari-Regular.ttf">
          <font-triplet name="NotoSansDevanagari" style="normal" weight="normal"/>
        </font>
        <font embed-url="${fontsDirUri}/NotoSansSC-Regular.otf">
          <font-triplet name="NotoSansSC" style="normal" weight="normal"/>
        </font>
        <auto-detect/>
      </fonts>
    </renderer>
  </renderers>
</fop>
"@
Set-Content -LiteralPath $fopConf -Value $fopConfContent -Encoding UTF8

# Ensure custom.xsl exists
$customXsl = Join-Path $root "custom.xsl"
if ($Force -or -not (Test-Path -LiteralPath $customXsl)) {
    $importPath = ".vendor/asciidoctor-fopub-main/build/fopub/docbook-xsl/fo-pdf.xsl"
    $customXslContent = @"
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:import href="$importPath"/>
  <xsl:param name="monospace.font.family" select="'LiberationMono, NotoSansMono, NotoSansSymbols2, NotoSansDevanagari, NotoSansSC, Symbol, ZapfDingbats'"/>
  <xsl:param name="body.font.family" select="'LiberationSerif, NotoSansDevanagari, NotoSansSC'"/>
  <xsl:param name="title.font.family" select="'LiberationSans, NotoSansDevanagari, NotoSansSC'"/>
</xsl:stylesheet>
"@
    Set-Content -LiteralPath $customXsl -Value $customXslContent -Encoding UTF8
}

Write-Host "Setup complete." -ForegroundColor Green