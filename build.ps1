Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
MkDir Output  | out-null

pandoc --table-of-contents --toc-depth=3 --epub-metadata=metadata.xml `
	--standalone --highlight-style=espresso --self-contained --chapters `
	--number-sections -o "Output\RavenDB In Depth.pdf" .\title.txt .\Ch1.md .\Ch2.md