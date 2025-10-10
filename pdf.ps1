rm -r ./build | Out-Null
mkdir ./build | Out-Null
asciidoctor-pdf -r asciidoctor-diagram -r ./transform.rb --destination-dir ./output  .\book.adoc
./output/book.pdf
