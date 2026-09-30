#!/bin/sh
# sample.adoc から sample.pdf を作る
#   必要: asciidoctor-pdf（brew install asciidoctor）
cd "$(dirname "$0")"
asciidoctor-pdf -r ./ext.rb -a pdf-theme=theme.yml -a pdf-fontsdir=fonts sample.adoc
