Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
MkDir Output  | out-null

$output = "Output\Current.pdf"

pandoc --epub-metadata=metadata.xml --standalone --highlight-style=tango --self-contained `
	--number-sections --listings --latex-engine=xelatex -o $output .\Ch10\Ch10.md

start $output