#!/bin/sh

bench=0
while :; do
    case $1 in
        -b)
            bench=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

pattern=${1-*}

# unalias vim
vim -u ./test/core_vimrc \
    -c 'call xpt#unittest#Runall('$bench", '$pattern'"') | if confirm("quit","&q\nn") == 1 | qa | endif'
