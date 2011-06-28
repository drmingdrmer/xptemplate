#!/bin/bash

case $1 in
    gentest)
        cd ftplugin/
        langs=`ls -d * | grep -v "^_" | awk '{printf($1" ");}'`
        cd -

        echo "vim -c \"XPTtestAll $langs\"" >test.bat
        exit
        ;;
    tosvn)
        rsync -Rrvc --delete \
            --exclude=.git/ --exclude=.svn/ \
            --exclude=dist-sub/ \
            --exclude=.gitmodules \
            --exclude=*.xpt.vimc \
            --exclude-from=../.gitignore \
            .././ \
            ../../xptemplate.svn/trunk/./
        exit
        ;;
    "")
        echo "export"
        ;;
    *)
        echo "error"
        exit -1
        ;;

esac

CurrentDir=$PWD
ParentDir=${PWD%/*}
ver=`cat VERSION`.`date +%y%m%d`

dodist () {
    DistName=$1
    DistDir=$ParentDir/$DistName
    vim -c 'helptags doc|qa'

    # remove old files those may not exist in src
    cd $DistDir && find -name "*.vim" | xargs rm -f

    cp -R $CurrentDir/* $DistDir/


    cd $DistDir
    rm -rf `cat $CurrentDir/$0 | awk '/^# __TO_REMOVE__/,/^# __TO_REMOVE__ END/{ if ( $1 != "#" ) print $0; }'`

    find -name "test.page*" | xargs rm

    for file in `find plugin/ -name *.vim`;do

        if [[ $file == "debug.vim" ]];then
            continue
        fi

        echo remove Logs/Comments/Empty_Lines from $file

        grep -v "call s:log.\(Log\|Debug\)(" $file |\
            grep -v "^\s*Assert " |\
            grep -v "^\s*\"" |\
            grep -v "^\s*$" |\
            sed 's/"\s*{{{//; s/"\s*}}}//' > .tmp

        mv .tmp $file
    done


    cd $DistDir
    cat > __ <<-END
	" GetLatestVimScripts: 2611 1 :AutoInstall: xpt.tgz
	" VERSION: $ver
	END
    cat $DistDir/plugin/xptemplate.vim >> __
    mv __ $DistDir/plugin/xptemplate.vim


    cd $ParentDir
    rm -rf xpt
    cp -R $DistName xpt

    cd xpt
    tar -czf ../xpt-$ver.tgz *

    cd $CurrentDir
}

dodist dist
dodist dist-sub




exit

# vim: set ts=64 :
# __TO_REMOVE__
plugin/xptemplateTest.vim
plugin/xptTestKey.vim
plugin/xptemplate.importer.vim
xpt.testall.*
xpt.ex
genfile.vim
doc/tags
xpt.files.txt
bench.vim
test.bat
test.sh
tags
todo
# __TO_REMOVE__ END
