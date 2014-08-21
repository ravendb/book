Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
MkDir Output  | out-null

$output = "Output\Inside RavenDB 3.0.epub"

pandoc --table-of-contents --toc-depth=3 --epub-metadata=metadata.xml `
	--standalone --highlight-style=espresso --self-contained --chapters `
	--listings --latex-engine=xelatex --number-sections `
	--epub-cover-image=.\Cover.png `
	-o $output .\title.txt .\Ch01\Ch01.md .\Part1.md .\Ch02\Ch02.md .\Ch03\Ch03.md `
	.\Ch04\Ch04.md .\Ch05\Ch05.md .\Part2.md .\Part3.md .\Part4.md

start $output