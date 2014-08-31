.\build.ps1 pdf $false
.\build.ps1 epub $false

$token = Get-Content "$pwd\..\Credentials\github.txt"
$release = "v0.3"

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

Invoke-WebRequest -Uri "https://uploads.github.com/repos/ayende/book/releases/$id/assets?name=Inside RavenDB 3.0.pdf" `
	-Headers @{"Authorization" = "token $token"; "Accept" = "application/vnd.github.v3+json"} `
    -ContentType "application/pdf" `
    -Method "POST" `
    -Body $pdf

$epub = [System.IO.File]::ReadAllBytes("$pwd\Output\Inside RavenDB 3.0.epub")

Invoke-WebRequest -Uri "https://uploads.github.com/repos/ayende/book/releases/$id/assets?name=Inside RavenDB 3.0.epub" `
	-Headers @{"Authorization" = "token $token"; "Accept" = "application/vnd.github.v3+json"} `
    -ContentType "application/epub+zip" `
    -Method "POST" `
    -Body $epub
