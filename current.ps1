Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
MkDir Output  | out-null

$output = "Output\Current.pdf"

pandoc --epub-metadata=metadata.xml --standalone --highlight-style=espresso --self-contained `
	--number-sections -o $output .\Ch01\Ch01.md

start $output