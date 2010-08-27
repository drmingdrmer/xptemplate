#!/bin/bash

CurrentDir=${PWD##*/}
ParentDir=${PWD%/*}
DistDir=$ParentDir/dist


vim -c 'helptags doc|qa'


VCS=svn

if [ -d ../.git ]; then

    VCS=git

    if git log -1 | fgrep 'git-svn-id'; then
        VCS=gitsvn
    fi

fi


echo "VCS=$VCS"


ver=`grep VERSION plugin/xptemplate.vim | awk '{print $3}'`

rev=r
if [ "$VCS" = "svn" ]; then
    rev=r`svn info | grep Revision | awk '{print $2}'`
elif [ "$VCS" = "gitsvn" ]; then
    rev=r`git svn info | grep Revision | awk '{print $2}'`
fi


echo export "$CurrentDir" to "$DistDir" 


# remove old files those may not exist in src
cd $DistDir
find -name "*.vim" | xargs rm -f


cd $ParentDir
if [ "$VCS" = "svn" ]; then
    svn export --force $CurrentDir $DistDir
elif [ "$VCS" = "git" -o "$VCS" = "gitsvn" ]; then
    cp -R $CurrentDir/* $DistDir/
fi


cd $DistDir
rm -rf	\
    plugin/xptemplateTest.vim	\
    plugin/xptTestKey.vim	\
    plugin/xptemplate.importer.vim	\
    xpt.testall.*	\
    xpt.ex	\
    genfile.vim	\
    doc/tags	\
    xpt.files.txt	\
    bench.vim	\
    todo



if [ "$1" = "no" ]; then
    echo
else
    find -name "test.page*" | xargs rm
fi


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

echo "\" GetLatestVimScripts: 2611 1 :AutoInstall: xpt.tgz" >> plugin/xptemplate.vim

if [ "$VCS" = "svn" ]; then
    svn ci -m "dist"
elif [ "$VCS" = "git" -o "$VCS" == "gitsvn" ]; then
    git commit -a -m "dist"
fi


cd $ParentDir

rm -rf xpt
if [ "$VCS" = "svn" ]; then
    svn export dist xpt
elif [ "$VCS" = "git" -o "$VCS" == "gitsvn" ]; then
    cp -R dist xpt
fi


cd xpt
tar -czf ../xpt-$ver-$rev.tgz *
cd -


ls xpt-*.tgz


# vim: set ts=64 :
