param([string]$type = "pdf", [boolean]$start = $true)

if ($start) {
	Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
}
MkDir Output -ErrorAction SilentlyContinue  | out-null


$output = ".\Output\Inside RavenDB 4.0.$type"

pandoc --table-of-contents --toc-depth=3 --epub-metadata=metadata.xml `
	--standalone --highlight-style=espresso --self-contained --top-level-division=part `
	--listings --latex-engine=xelatex --number-sections `
	--epub-cover-image=.\Cover.jpg `
	-o $output .\title.txt .\Intro\Intro.md .\Ch02\Ch02.md .\Ch03\Ch03.md .\Ch04\Ch04.md `
	.\Ch05\Ch05.md .\Ch06\PartII.md  .\Ch06\Ch06.md 

if($start) {
	start $output
}

return $output