#!/bin/sh

if [ ".$1" = ".pull" ]; then
    act=pull
elif [ ".$1" = ".add" ]; then
    act=add
else
    echo "$0 [pull|add]" >&2
    exit 1
fi

_3rd=test/3rdpart
(
url="https://github.com/ervandew/supertab.git"

git fetch $url \
    && git subtree $act --prefix $_3rd/supertab $url master --squash
)
