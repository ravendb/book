param([switch]$Force)

$ErrorActionPreference = "Stop"

# Relax Java XML security limits for transformations
$env:_JAVA_OPTIONS = "-Djavax.xml.accessExternalStylesheet=all -Djavax.xml.accessExternalDTD=all -Djdk.xml.xpathExprOpLimit=0 -Djdk.xml.xpathExprGrpLimit=0 -Djdk.xml.xpathTotalOpLimit=0 -Djdk.xml.entityExpansionLimit=0 -Djdk.xml.totalEntitySizeLimit=0 -Djdk.xml.maxOccurLimit=0 -Djdk.xml.enableExtensionFunctions=true"

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

function Download-IfMissing([string]$Uri,[string]$Dest,[switch]$ForceDownload) {
    if ($ForceDownload -or -not (Test-Path -LiteralPath $Dest)) {
        Invoke-WebRequest -Uri $Uri -OutFile $Dest
    }
}

Write-Host "Setting up vendor tooling, fonts, and building PDF (PowerShell, cross-platform)..." -ForegroundColor Cyan

$root = (Get-Location).Path
$vendorDir = Join-Path $root ".vendor"
Ensure-Directory $vendorDir

# ---------- Download and prepare asciidoctor-fopub ----------
$fopubRoot = Join-Path $vendorDir "asciidoctor-fopub-main"
if ($Force -or -not (Test-Path -LiteralPath $fopubRoot)) {
    Write-Host "Downloading asciidoctor-fopub..." -ForegroundColor Yellow
    $zipPath = Join-Path $vendorDir "fopub.zip"
    Invoke-WebRequest -Uri "https://github.com/asciidoctor/asciidoctor-fopub/archive/refs/heads/main.zip" -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $vendorDir -Force
    Remove-Item $zipPath -Force
}

# Fix remote imports in DocBook XSL customizations (source repo)
$srcXslDir = Join-Path $fopubRoot "src/dist/docbook-xsl"
Replace-InFile (Join-Path $srcXslDir "highlight.xsl") (@{ "http://docbook.sourceforge.net/release/xsl/current/highlighting/common.xsl" = "../docbook/highlighting/common.xsl" })
Replace-InFile (Join-Path $srcXslDir "fo-pdf.xsl") (@{ "https://cdn.docbook.org/release/xsl/current/fo/docbook.xsl" = "../docbook/fo/docbook.xsl" })
Replace-InFile (Join-Path $srcXslDir "xhtml.xsl") (@{ "https://cdn.docbook.org/release/xsl/current/xhtml/docbook.xsl" = "../docbook/xhtml/docbook.xsl" })

$fopubBuildDir = Join-Path $fopubRoot "build/fopub"
$gradleScript = if ($IsWindows) { Join-Path $fopubRoot "gradlew.bat" } else { Join-Path $fopubRoot "gradlew" }

if ($Force -or -not (Test-Path -LiteralPath $fopubBuildDir)) {
    Write-Host "Building asciidoctor-fopub (requires JDK; falls back to binary FOP if javac missing)..." -ForegroundColor Yellow
    if (-not $IsWindows) { & chmod +x $gradleScript }

    $javacAvailable = $null -ne (Get-Command javac -ErrorAction SilentlyContinue)
    if (-not $javacAvailable) {
        Write-Warning "JDK not found (javac not available). Using partial gradle extraction + standalone FOP..."

        Push-Location $fopubRoot
        try {
            & $gradleScript extractDocbookXml extractDocbookXsl --no-daemon 2>&1 | Write-Output
        } finally {
            Pop-Location
        }

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

        $minimalFopubLib = Join-Path $fopubBuildDir "lib"
        Ensure-Directory $minimalFopubLib

        Get-ChildItem -Path (Join-Path $fopDir "lib/*.jar") | ForEach-Object { Copy-Item $_.FullName -Destination $minimalFopubLib -Force }
        Get-ChildItem -Path (Join-Path $fopDir "build/*.jar") | ForEach-Object { Copy-Item $_.FullName -Destination $minimalFopubLib -Force }

        Download-IfMissing "https://repo1.maven.org/maven2/net/sf/xslthl/xslthl/2.1.0/xslthl-2.1.0.jar" (Join-Path $minimalFopubLib "xslthl-2.1.0.jar") -ForceDownload:$Force
        Download-IfMissing "https://repo1.maven.org/maven2/xalan/xalan/2.7.3/xalan-2.7.3.jar" (Join-Path $minimalFopubLib "xalan-2.7.3.jar") -ForceDownload:$Force
        Download-IfMissing "https://repo1.maven.org/maven2/xalan/serializer/2.7.3/serializer-2.7.3.jar" (Join-Path $minimalFopubLib "serializer-2.7.3.jar") -ForceDownload:$Force

        $docbookXslSrc = Join-Path $fopubRoot "src/dist/docbook-xsl"
        $docbookXslDest = Join-Path $fopubBuildDir "docbook-xsl"
        if (-not (Test-Path -LiteralPath $docbookXslDest)) {
            Copy-Item $docbookXslSrc -Destination $docbookXslDest -Recurse -Force
        }

        $buildUnpackedDir = Join-Path $fopubRoot "build/unpacked"
        if (Test-Path -LiteralPath $buildUnpackedDir) {
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
            & $gradleScript installDist --no-daemon 2>&1 | Write-Output
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
    Replace-InFile (Join-Path $builtXslDir "highlight.xsl") (@{ "http://docbook.sourceforge.net/release/xsl/current/highlighting/common.xsl" = "../docbook/highlighting/common.xsl" })
    Replace-InFile (Join-Path $builtXslDir "fo-pdf.xsl") (@{ "https://cdn.docbook.org/release/xsl/current/fo/docbook.xsl" = "../docbook/fo/docbook.xsl" })
    Replace-InFile (Join-Path $builtXslDir "xhtml.xsl") (@{ "https://cdn.docbook.org/release/xsl/current/xhtml/docbook.xsl" = "../docbook/xhtml/docbook.xsl" })
}

# ---------- Fonts ----------
$fontsDir = Join-Path $vendorDir "fonts"
Ensure-Directory $fontsDir

$libFontsPresent = Test-Path -LiteralPath (Join-Path $fontsDir "LiberationMono-Regular.ttf")
if ($Force -or -not $libFontsPresent) {
    Write-Host "Fetching Liberation fonts..." -ForegroundColor Yellow
    $tarGz = Join-Path $root "liberation-fonts-ttf-2.1.5.tar.gz"
    Invoke-WebRequest -Uri "https://github.com/liberationfonts/liberation-fonts/files/7261482/liberation-fonts-ttf-2.1.5.tar.gz" -OutFile $tarGz
    try {
        tar -xzf $tarGz
        $fontRoot = Join-Path $root "liberation-fonts-ttf-2.1.5"
        foreach ($name in @(
            "LiberationMono-Regular.ttf","LiberationMono-Bold.ttf","LiberationMono-Italic.ttf","LiberationMono-BoldItalic.ttf",
            "LiberationSerif-Regular.ttf","LiberationSerif-Bold.ttf","LiberationSerif-Italic.ttf","LiberationSerif-BoldItalic.ttf",
            "LiberationSans-Regular.ttf","LiberationSans-Bold.ttf","LiberationSans-Italic.ttf","LiberationSans-BoldItalic.ttf"
        )) {
            Copy-Item (Join-Path $fontRoot $name) -Destination $fontsDir -Force
        }
        Remove-Item $fontRoot -Recurse -Force
    } catch {
        Write-Warning "Extraction of Liberation fonts failed. Ensure 'tar' is available, or place fonts into $fontsDir manually."
    } finally {
        Remove-Item $tarGz -Force -ErrorAction SilentlyContinue
    }
}

Download-IfMissing "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansMono/NotoSansMono-Regular.ttf" (Join-Path $fontsDir "NotoSansMono-Regular.ttf") -ForceDownload:$Force
Download-IfMissing "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansSymbols2/NotoSansSymbols2-Regular.ttf" (Join-Path $fontsDir "NotoSansSymbols2-Regular.ttf") -ForceDownload:$Force

# ---------- Generate config from templates ----------
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

Write-Host "Setup complete. Building book..." -ForegroundColor Green

# ---------- Build pipeline ----------
Remove-Item ./output -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path ./output | Out-Null

# Link .vendor into output (symlink on non-Windows, junction on Windows)
$vendorPath = (Resolve-Path ./.vendor).Path
$junctionPath = Join-Path (Resolve-Path ./output).Path ".vendor"
if (Test-Path -LiteralPath $junctionPath) { Remove-Item $junctionPath -Recurse -Force -ErrorAction SilentlyContinue }
try {
    if ($IsWindows) {
        New-Item -ItemType Junction -Path $junctionPath -Target $vendorPath -Force -ErrorAction Stop | Out-Null
    } else {
        New-Item -ItemType SymbolicLink -Path $junctionPath -Target $vendorPath -Force -ErrorAction Stop | Out-Null
    }
} catch {
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

Write-Host "Generating DocBook XML..." -ForegroundColor Yellow
& asciidoctor -b docbook5 -r asciidoctor-diagram -r ./transform.rb -a imagesdir=. -o ./output/book.xml ./book.adoc | Write-Output

Write-Host "Post-processing cross-references..." -ForegroundColor Yellow
& ruby ./transform_xreflabel.rb ./output/book.xml | Write-Output

$fopubLib = Join-Path (Resolve-Path ./.vendor/asciidoctor-fopub-main/build/fopub/lib).Path ""
if (-not (Test-Path -LiteralPath $fopubLib)) {
    throw "fopub lib directory not found at $fopubLib. Setup step failed."
}

$jars = Get-ChildItem -LiteralPath $fopubLib -Filter *.jar | Sort-Object Name
$priority = $jars | Where-Object { $_.Name -like "xalan*" -or $_.Name -like "serializer*" -or $_.Name -like "xslthl*" }
$rest = $jars | Where-Object { $_.Name -notlike "xalan*" -and $_.Name -notlike "serializer*" -and $_.Name -notlike "xslthl*" }
$jarPaths = @()
$jarPaths += ($priority | Select-Object -ExpandProperty FullName)
$jarPaths += ($rest | Select-Object -ExpandProperty FullName)
$cpSeparator = if ($IsWindows) { ';' } else { ':' }
$cp = ($jarPaths -join $cpSeparator)

$rootFwd = (Resolve-Path .).Path -replace "\\","/"
$xslthlCfg = "$rootFwd/.vendor/asciidoctor-fopub-main/build/fopub/docbook-xsl/xslthl-config.xml"
$admonImg = "file:///$rootFwd/.vendor/asciidoctor-fopub-main/build/fopub/docbook/images/"
$calloutImg = "file:///$rootFwd/.vendor/asciidoctor-fopub-main/build/fopub/docbook/images/callouts/"

Write-Host "Converting to PDF with FOP..." -ForegroundColor Yellow
$javaArgs = @(
    "-Djavax.xml.accessExternalStylesheet=all",
    "-Djavax.xml.accessExternalDTD=all",
    "-Djdk.xml.xpathExprOpLimit=0",
    "-Djdk.xml.xpathExprGrpLimit=0",
    "-Djdk.xml.xpathTotalOpLimit=0",
    "-Djdk.xml.config.file=$rootFwd/jaxp.properties",
    "-cp", $cp,
    "org.apache.fop.cli.Main",
    "-c", "$rootFwd/.vendor/fop.xconf",
    "-xml", "$rootFwd/output/book.xml",
    "-xsl", "$rootFwd/custom.xsl",
    "-param", "img.src.path", "file:///$rootFwd/",
    "-param", "highlight.xslthl.config", "file:///$xslthlCfg",
    "-param", "admon.graphics.path", $admonImg,
    "-param", "callout.graphics.path", $calloutImg,
    "-pdf", "$rootFwd/output/book.pdf"
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