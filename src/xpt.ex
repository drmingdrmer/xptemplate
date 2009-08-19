#!/bin/bash

CurrentDir=${PWD##*/}
ParentDir=${PWD%/*}
DistDir=$ParentDir/dist

echo export "$CurrentDir" to "$DistDir" 
# exit


# vim -S genfile.vim


v=`grep VERSION plugin/xptemplate.vim | awk '{print $3}'`


cd $ParentDir
svn export --force $CurrentDir $DistDir
# svn export $CurrentDir/../xpt.ftp.svn/trunk/ftplugin $DistDir/ftplugin


cd $DistDir
rm -rf	\
  plugin/debug.vim	\
  xpt.ex	\
  genfile.vim	\
  doc/tags	\
  xpt.files.txt	\
  bench.vim	\



# remove 'call Log'
# grep -v "call \(Fatal\|Error\|Warn\|Info\|Log\|Debug\)(" plugin/$file |\
for file in `ls plugin/`;do

  echo remove Log and comments from $file

  grep -v "call s:log.\(Log\|Debug\)(" plugin/$file |\
  grep -v "CreateLogger(" |\
  grep -v "^\s*\"" |\
  grep -v "^\s*$" |\
  sed 's/"\s*{{{//; s/"\s*}}}//' > .tmp

  mv .tmp plugin/$file
done

cd -

# tar -czf $DistDir-$v.tgz $DistDir
# rm -rdf $DistDir

# ls $DistDir-*.tgz


# vim: set ts=32 :
