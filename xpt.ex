#!/bin/bash

case $1 in
    gentest)
        cd ftplugin/
        langs=`ls -d * | grep -v "^_" | awk '{printf($1" ");}'`
        cd -

        echo "vim -c \"XPTtestAll $langs\"" >test.bat
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
githash=`git log --max-count=1 --format=%h`
today=`date +%y%m%d`
ver=`cat VERSION`.$today-$githash
distname=dist.$today-$githash

compact() {
    local file=$1

    echo remove Logs/Comments/Empty_Lines from $file

    grep -v "call s:log.\(Log\|Debug\)(" $file |\
        grep -v "^ *Assert " |\
        grep -v "^ *\"" |\
        grep -v "^ *$" |\
        sed 's/" *{{{//; s/" *}}}//' > .tmp

    mv .tmp $file
}

create_tgz() {
    rm -rf $ParentDir/xpt && mkdir $ParentDir/xpt && cp -R ./* $ParentDir/xpt/
    cd $ParentDir/xpt && tar -czf ../xpt-$ver.tgz *
}

dodist () {

    git branch $distname && git checkout $distname || { echo "Failed to create branch $distname"; exit 1; }

    cat $CurrentDir/$0 | awk '/^# __TO_REMOVE__/,/^# __TO_REMOVE__ END/{ if ( $1 != "#" ) print $0; }' | while read f; do git rm -rf $f; done
    git rm `find . -name "test.page*"`
    rm `find . -name "*.xpt.vimc"`


    for file in `find plugin/ -name *.vim | grep -v "/debug\.vim$"`;do
        compact $file
    done


    mv plugin/xptemplate.vim .tmp
    cat > plugin/xptemplate.vim <<-END
	" GetLatestVimScripts: 2611 1 :AutoInstall: xpt.tgz
	" VERSION: $ver
	END
    cat .tmp >> plugin/xptemplate.vim && rm .tmp

    git commit -a -m "$distname"

    create_tgz
    cd $CurrentDir


    git branch dist
    git merge -s ours dist

    git co dist && git merge $distname

}

dodist
exit

# __TO_REMOVE__
xpt.ex
plugin/xptemplateTest.vim
plugin/xptTestKey.vim
plugin/xptemplate.importer.vim
xpt.testall.*
genfile.vim
doc/tags
xpt.files.txt
bench.vim
test.bat
test.sh
tags
todo
experiment/
resource/
VERSION
# __TO_REMOVE__ END
