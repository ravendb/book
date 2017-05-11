param([string]$type = "pdf", [boolean]$start = $true)

if ($start) {
	Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
}
MkDir Output -ErrorAction SilentlyContinue  | out-null


$output = ".\Output\Inside RavenDB 4.0.$type"

pandoc --table-of-contents --toc-depth=3 --epub-metadata=metadata.xml `
	--standalone --highlight-style=espresso --self-contained --top-level-division=chapter `
	--listings --latex-engine=xelatex --number-sections `
	--epub-cover-image=.\Cover.jpg `
	-o $output .\title.txt .\Intro\Intro.md

if($start) {
	start $output
}

return $output