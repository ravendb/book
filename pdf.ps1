rm -r ./build | Out-Null
mkdir ./build | Out-Null
asciidoctor-pdf -r asciidoctor-diagram --destination-dir ./output  .\current.adoc
./output/current.pdf