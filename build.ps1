param([string]$type = "pdf", [boolean]$start = $true)

if ($start) {
	Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
}
MkDir Output -ErrorAction SilentlyContinue  | out-null


$output = ".\Output\Inside RavenDB 3.0.$type"

pandoc --table-of-contents --toc-depth=3 --epub-metadata=metadata.xml `
	--standalone --highlight-style=espresso --self-contained --chapters `
	--listings --latex-engine=xelatex --number-sections `
	--epub-cover-image=.\Cover.jpg `
	-o $output .\title.txt .\Ch01\Ch01.md .\Part1.md .\Ch02\Ch02.md .\Ch03\Ch03.md `
	.\Ch04\Ch04.md .\Ch05\Ch05.md .\Part2.md .\Ch06\Ch06.md .\Ch07\Ch07.md .\Ch08\Ch08.md .\Ch09\Ch09.md .\Part3.md .\Part4.md

if($start) {
	start $output
}

return $output