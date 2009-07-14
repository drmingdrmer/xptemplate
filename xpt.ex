#!/bin/bash

Plugin=${PWD##*/}
Dir=${PWD%/*}
Target=xpt

echo export "$Plugin" to "$Dir" "....."


# vim -S genfile.vim


v=`grep VERSION plugin/xptemplate.vim | awk '{print $3}'`


cd $Dir
svn export $Plugin $Target
svn export $Plugin/../xpt.ftp.svn/trunk/ftplugin $Target/ftplugin


cd $Target
rm -rf syntax/vim.vim xpt.ex genfile.vim doc/tags xpt.files.txt bench.vim


# remove 'call Log'
for file in `ls plugin/`;do
  echo remove Log and comments from $file
  grep -v "call \(Fatal\|Error\|Warn\|Info\|Log\|Debug\)(" plugin/$file |\
  grep -v "^\s*\"" |\
  grep -v "^\s*$" |\
  sed 's/"\s*{{{//; s/"\s*}}}//' > .tmp

  mv .tmp plugin/$file
done

cd -

tar -czf $Target-$v.tgz $Target
rm -rdf $Target

ls $Target-*.tgz

