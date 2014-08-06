Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
MkDir Output  | out-null

$output = "Output\Inside RavenDB.pdf"

pandoc --table-of-contents --toc-depth=2 --epub-metadata=metadata.xml `
	--standalone --highlight-style=espresso --self-contained --chapters `
	--listings --latex-engine=xelatex --number-sections `
	-o $output .\title.txt .\Intro.md .\Ch01\Ch01.md .\Ch02\Ch02.md .\Ch03\Ch03.md .\Ch04\Ch04.md

start $output