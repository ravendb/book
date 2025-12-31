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
        # Copy all Liberation font variants (regular, bold, italic, bold-italic)
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationMono-Regular.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationMono-Bold.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationMono-Italic.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationMono-BoldItalic.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSerif-Regular.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSerif-Bold.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSerif-Italic.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSerif-BoldItalic.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSans-Regular.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSans-Bold.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSans-Italic.ttf") -Destination $fontsDir -Force
        Copy-Item (Join-Path $root "liberation-fonts-ttf-2.1.5\LiberationSans-BoldItalic.ttf") -Destination $fontsDir -Force
        Remove-Item (Join-Path $root "liberation-fonts-ttf-2.1.5") -Recurse -Force
    } catch {
        Write-Warning "Extraction of tar.gz failed. Ensure 'tar' is available, or place Liberation fonts into $fontsDir manually."
    } finally {
        Remove-Item $tarGz -Force -ErrorAction SilentlyContinue
    }
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

# Generate FOP config from template
$fopConfTemplate = Join-Path $root "fop.xconf.template"
$fopConf = Join-Path $vendorDir "fop.xconf"
if ($Force -or -not (Test-Path -LiteralPath $fopConf)) {
    if (-not (Test-Path -LiteralPath $fopConfTemplate)) {
        throw "fop.xconf.template not found at $fopConfTemplate"
    }
    
    $fontsDirUri = "file:///" + ((Resolve-Path $fontsDir).Path -replace "\\","/")
    $fopConfContent = (Get-Content -LiteralPath $fopConfTemplate -Raw) -replace "{{FONTS_DIR_URI}}", $fontsDirUri
    Set-Content -LiteralPath $fopConf -Value $fopConfContent -Encoding UTF8
    Write-Host "Generated fop.xconf from template" -ForegroundColor Yellow
}

# Generate custom.xsl from template
$customXslTemplate = Join-Path $root "custom.xsl.template"
$customXsl = Join-Path $root "custom.xsl"
if ($Force -or -not (Test-Path -LiteralPath $customXsl)) {
    if (-not (Test-Path -LiteralPath $customXslTemplate)) {
        throw "custom.xsl.template not found at $customXslTemplate"
    }
    
    $importPath = ".vendor/asciidoctor-fopub-main/build/fopub/docbook-xsl/fo-pdf.xsl"
    $customXslContent = (Get-Content -LiteralPath $customXslTemplate -Raw) -replace "{{IMPORT_PATH}}", $importPath
    Set-Content -LiteralPath $customXsl -Value $customXslContent -Encoding UTF8
    Write-Host "Generated custom.xsl from template" -ForegroundColor Yellow
}

Write-Host "Setup complete." -ForegroundColor Green