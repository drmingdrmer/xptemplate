#!/bin/sh

bench=0
profile=0
while :; do
    case $1 in
        -b)
            bench=1
            shift
            ;;
        -p)
            profile=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

pattern=${1-*}

# unalias vim

XPT_BENCH=$bench XPT_PROFILE=$profile \
    vim -u ./test/core_vimrc \
    -c 'call xpt#unittest#Runall('"'$pattern'"') | if confirm("quit","&q\nn") == 1 | qa | endif'
