#!/bin/sh

# unalias vim
vim -u ./test/core_vimrc \
    -c 'call xpt#unittest#Runall() | if confirm("quit","y\nn") == 1 | qa | endif'
