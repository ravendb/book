param([string]$type = "pdf", [boolean]$start = $true)

if ($start) {
	Remove-Item  Output -Force -Recurse -ErrorAction SilentlyContinue | out-null 
}
MkDir Output -ErrorAction SilentlyContinue  | out-null


$output = ".\Output\Inside RavenDB 4.0.$type"

pandoc --table-of-contents --toc-depth=3 --epub-metadata=metadata.xml `
	--standalone --highlight-style=espresso --self-contained --top-level-division=part `
	--listings --pdf-engine=xelatex --number-sections --css=pandoc.css `
	--epub-cover-image=.\Cover.jpg --epub-embed-font=Styling/RobotoMono-Regular.ttf `
	-o $output .\title.txt .\Intro\Intro.md .\Ch02\Ch02.md .\Ch03\Ch03.md .\Ch04\Ch04.md `
	.\Ch05\Ch05.md .\Ch06\PartII.md  .\Ch06\Ch06.md .\Ch07\Ch07.md .\Ch08\Ch08.md `
	.\Ch09\PartIII.md  .\Ch09\Ch09.md .\Ch10\Ch10.md .\Ch11\Ch11.md .\Ch12\Ch12.md `
	.\Ch13\PartIV.md .\Ch13\Ch13.md .\Ch14\Ch14.md .\Ch15\PartV.md .\Ch15\Ch15.md `
	.\Ch16\Ch16.md .\Ch17\Ch17.md .\Ch18\Ch18.md .\Ch19\Ch19.md .\index.md `

if($start) {
	start $output
}

return $output