rm -r ./build
mkdir ./build 
asciidoctor-pdf -r asciidoctor-diagram --destination-dir ./output  .\book.adoc
./output/book.pdf