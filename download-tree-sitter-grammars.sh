#!/bin/bash


IFS=$'\n'
# ZSH does not split words by default (like other shells):
setopt sh_word_split

export TREESITTER_RUNTIME_AND_GRAMMARS=\
"
tree-sitter/tree-sitter/
tree-sitter/tree-sitter-c-sharp/
tree-sitter/tree-sitter-cpp/
tree-sitter/tree-sitter-go/
tree-sitter/tree-sitter-java/
tree-sitter/tree-sitter-javascript/
tree-sitter/tree-sitter-php/
tree-sitter/tree-sitter-python/
tree-sitter/tree-sitter-ruby/
tree-sitter/tree-sitter-typescript/
tree-sitter/tree-sitter-bash/
tree-sitter/tree-sitter-html/
tree-sitter/tree-sitter-css/
tree-sitter/tree-sitter-json/
tree-sitter/tree-sitter-julia/
tree-sitter/tree-sitter-regex/
airbus-cert/tree-sitter-powershell/
"

FOLDER=./externals/


for TREESITTER in $TREESITTER_RUNTIME_AND_GRAMMARS
do
    if [[ $TREESITTER == "#"* ]]
    then
        continue
    fi

    md $FOLDER/$TREESITTER/
    
    curl \
        -v -L -C - \
        --output-dir ./$FOLDER/$TREESITTER/ \
        -O https://github.com/$TREESITTER/archive/refs/heads/master.zip

done



