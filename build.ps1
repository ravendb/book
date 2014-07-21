Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
MkDir Output  | out-null

$output = "Output\Inside RavenDB.pdf"

pandoc --table-of-contents --toc-depth=3 --epub-metadata=metadata.xml `
	--standalone --highlight-style=espresso --self-contained --chapters `
	--number-sections -o $output .\title.txt `
	.\Ch01\Ch01.md .\Ch02\Ch02.md

start $output