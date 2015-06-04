#!/bin/bash

source config.sh

compileall=
remote=
fastArgs=""

function usage
{
  echo "usage: build.sh [-a -r -f]"
  echo "  -a (Re)Compile all diagrams, kindle versions etc (slow!)"
  echo "  -r Compile on a remote server"
  echo "  -f Compile quickly (maybe taking shortcuts along the way)"
}

while [ "$1" != "" ]; do
    case $1 in
        -a | --compileall )     compileall=1
                                ;;
        -r | --remote )         remote=1
                                ;;
        -f | --fast )           fastArgs="\def\fastCompile{1} "
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     exit 1
    esac
    shift
done

for i in `ls *.tex`; do
    aspell -t check $i;
done;

if [ "$remote" = 1 ]; then
  zip -r content.zip ./ -x *.git*
  ssh -p $hostport $remoteuser@$hostname 'rm -rf ~/tmp/latex_build; mkdir -p ~/tmp/latex_build;'
  scp -P $hostport content.zip $remoteuser@$hostname:~/tmp/latex_build
  ssh -p $hostport $remoteuser@$hostname "cd ~/tmp/latex_build/;unzip content.zip;rm content.zip;./build.sh -n;zip content.zip ./*.pdf;"
  rm content.zip
  scp -P $hostport $remoteuser@$hostname:~/tmp/latex_build/content.zip ./content.zip
  unzip -o content.zip
  rm content.zip
else
  if [ "$compileall" = "1" ]; then
    for dir in "${directories[@]%*/}"; do
      cd $dir;
      for i in `ls *.tex`; do
        if [ $parallelCompile -eq "true" ]; then
          pdflatex $i &
        else 
          pdflatex $i;
        fi
      done;
      cd ..
    done;
    if [ $parallelCompile -eq "true" ]; then
      wait;
    fi
  fi
  if [ $parallelCompile -eq "true" ]; then
    pdflatex "$fastArgs\input{notes.tex}" &
  else
    pdflatex "$fastArgs\input{notes.tex}";
  fi
  if [ "$compileall" = "1" ]; then
    if [ $parallelCompile -eq "true" ]; then
      pdflatex "$fastArgs\input{kindle.tex}" &
    else
      pdflatex "$fastArgs\input{kindle.tex}";
    fi
  fi
  wait;
  # In case the Author field isn't set
  exiftool notes.pdf -Author="$authorName"
fi
