.\build.ps1 pdf $true
.\build.ps1 epub $false

c:\tools\kindlegen\kindlegen.exe ".\Output\Inside RavenDB 3.0.epub"

$token = Get-Content "$pwd\..\Credentials\github.txt"
$release = "v0.3.6"

$json = Invoke-WebRequest -ErrorAction Stop `
	 -Uri "https://api.github.com/repos/ayende/book/releases" `
	-ContentType "application/json" `
	-Method "POST" `
	-Headers @{"Authorization" = "token $token"; "Accept" = "application/vnd.github.v3+json"} `
	-Body "{  
	`"tag_name`": `"$release`",   
	`"target_commitish`": `"master`",   
	`"name`": `"$release`",   
	`"body`": `"Preview of the book`",   
	`"draft`": false,   
	`"prerelease`":  true
}"

if($json -eq $null) {
	return
}

$resp = ConvertFrom-Json $json

$id = $resp.id

echo "New release id: $id"

$pdf = [System.IO.File]::ReadAllBytes("$pwd\Output\Inside RavenDB 3.0.pdf")

Echo "Uploading .pdf"

Invoke-WebRequest -Uri "https://uploads.github.com/repos/ayende/book/releases/$id/assets?name=Inside RavenDB 3.0.pdf" `
	-Headers @{"Authorization" = "token $token"; "Accept" = "application/vnd.github.v3+json"} `
    -ContentType "application/pdf" `
    -Method "POST" `
    -Body $pdf

Echo "Uploading .epub"

$epub = [System.IO.File]::ReadAllBytes("$pwd\Output\Inside RavenDB 3.0.epub")

Invoke-WebRequest -Uri "https://uploads.github.com/repos/ayende/book/releases/$id/assets?name=Inside RavenDB 3.0.epub" `
	-Headers @{"Authorization" = "token $token"; "Accept" = "application/vnd.github.v3+json"} `
    -ContentType "application/epub+zip" `
    -Method "POST" `
    -Body $epub

$mobi = [System.IO.File]::ReadAllBytes("$pwd\Output\Inside RavenDB 3.0.mobi")

Echo "Uploading .mobi"

Invoke-WebRequest -Uri "https://uploads.github.com/repos/ayende/book/releases/$id/assets?name=Inside RavenDB 3.0.mobi" `
	-Headers @{"Authorization" = "token $token"; "Accept" = "application/vnd.github.v3+json"} `
    -ContentType "application/octet-stream" `
    -Method "POST" `
    -Body $mobi