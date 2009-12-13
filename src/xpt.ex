#!/bin/bash

CurrentDir=${PWD##*/}
ParentDir=${PWD%/*}
DistDir=$ParentDir/dist

echo export "$CurrentDir" to "$DistDir" 
# exit



v=`grep VERSION plugin/xptemplate.vim | awk '{print $3}'`


# remove old files those may not exist in src
cd $DistDir
find -name "*.vim" | xargs rm -f


cd $ParentDir
svn export --force $CurrentDir $DistDir
# svn export $CurrentDir/../xpt.ftp.svn/trunk/ftplugin $DistDir/ftplugin


cd $DistDir
# plugin/debug.vim	\
# plugin/xpop.test.vim	\
rm -rf	\
  plugin/xptemplateTest.vim	\
  plugin/xptemplate.importer.vim	\
  xpt.ex	\
  genfile.vim	\
  doc/tags	\
  xpt.files.txt	\
  bench.vim	\
  todo	\

  

if [ "$1" = "no" ]; then
  echo
else
  find -name "test.page" | xargs rm
fi


# remove 'call Log'
# grep -v "call \(Fatal\|Error\|Warn\|Info\|Log\|Debug\)(" plugin/$file |\
for file in `ls plugin/`;do

  if [[ $file == "debug.vim" ]];then
    continue
  fi

  echo remove Log and comments from $file

  grep -v "call s:log.\(Log\|Debug\)(" plugin/$file |\
  grep -v "^\s*\"" |\
  grep -v "^\s*$" |\
  sed 's/"\s*{{{//; s/"\s*}}}//' > .tmp

  mv .tmp plugin/$file
done


cd $DistDir
# addsvn
# rmsvn
svn ci -m "dist"


cd $ParentDir
rm -rf xpt
svn export dist xpt
cd xpt
tar -czf ../xpt-$v.tgz *
cd -

ls xpt-*.tgz


# vim: set ts=64 :
