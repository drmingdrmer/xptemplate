#!/bin/sh

pattern=${1-*}
# unalias vim
vim -u ./test/core_vimrc \
    -c 'call xpt#unittest#Runall('"'$pattern'"') | if confirm("quit","&q\nn") == 1 | qa | endif'
