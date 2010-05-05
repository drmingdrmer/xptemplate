#!/bin/bash

CurrentDir=${PWD##*/}
ParentDir=${PWD%/*}
DistDir=$ParentDir/dist

VersionControlSys=svn
if [ -d ../.git ]; then
    VersionControlSys=git
fi

echo "VersionControlSys=$VersionControlSys"

rev=r
if [ "$VersionControlSys" = "svn" ]; then
    svn up
    rev=r`svn info | grep Revision | awk '{print $2}'`
fi
v=`grep VERSION plugin/xptemplate.vim | awk '{print $3}'`


# update help tags
vim -c 'helptags doc|qa'

echo export "$CurrentDir" to "$DistDir" 


# remove old files those may not exist in src
cd $DistDir
find -name "*.vim" | xargs rm -f


cd $ParentDir
if [ "$VersionControlSys" = "svn" ]; then
    svn export --force $CurrentDir $DistDir
elif [ "$VersionControlSys" = "git" ]; then
    cp -R $CurrentDir/* $DistDir/
fi


cd $DistDir
# plugin/debug.vim	\
# plugin/xpop.test.vim	\
rm -rf	\
  plugin/xptemplateTest.vim	\
  plugin/xptemplate.importer.vim	\
  xpt.testall.*	\
  xpt.ex	\
  genfile.vim	\
  doc/tags	\
  xpt.files.txt	\
  bench.vim	\
  todo	\

  

if [ "$1" = "no" ]; then
  echo
else
  find -name "test.page*" | xargs rm
fi


# remove 'call Log'
# grep -v "call \(Fatal\|Error\|Warn\|Info\|Log\|Debug\)(" plugin/$file |\
for file in `find plugin/ -name *.vim`;do

  if [[ $file == "debug.vim" ]];then
    continue
  fi

  echo remove Log and comments from $file

  grep -v "call s:log.\(Log\|Debug\)(" $file |\
  grep -v "^ *Assert " |\
  grep -v "^\s*\"" |\
  grep -v "^\s*$" |\
  sed 's/"\s*{{{//; s/"\s*}}}//' > .tmp

  mv .tmp $file
done



cd $DistDir

if [ "$VersionControlSys" = "svn" ]; then
    svn ci -m "dist"
elif [ "$VersionControlSys" = "git" ]; then

    git commit -a -m "dist"
fi



cd $ParentDir

rm -rf xpt
if [ "$VersionControlSys" = "svn" ]; then
    svn export dist xpt
elif [ "$VersionControlSys" = "git" ]; then
    cp -R dist xpt
fi

cd xpt
tar -czf ../xpt-$v-$rev.tgz *
cd -

ls xpt-*.tgz


# vim: set ts=64 :
