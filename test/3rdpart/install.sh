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

echo '
supertab    https://github.com/ervandew/supertab.git    master
ctrlp       https://github.com/ctrlpvim/ctrlp.vim.git   master
' | while read folder url branch
do
    if test -z "$folder"
    then
        continue
    fi

    (
    git fetch $url \
        && git subtree $act --prefix $_3rd/$folder $url $branch --squash
    )
done
