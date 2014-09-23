#!/bin/bash

#set -x


function orig_dir()
{
  cd $1
  for i in $(ls)
  do
    # .bz2
    dir=$(echo $i | sed 's/[-][0-9.]*\.[a-z.2]*$//')
    echo $dir | grep py2
    # for py2.py3 or py27
    if [ $? -eq 0 ]; then
        dir=$(echo $dir | awk -F'-' '{print $1}')
    fi
    if [ -d $dir ]; then
        echo 'YES'
        continue
    else
        mkdir $dir
    fi
    mv $i $dir/$i
  done

  for i in $(ls)
  do
    if [ ! -d ${i} ]; then
        echo "$i"
    fi
  done
  cd -
}

function download_pypi()
{
 # pip install --download=/var/www/tmp/ -r /opt/stack/heat/test-requirements.txt
    tmp_dir=$1
    require=$2
    pip install --download=$tmp_dir -r $2
    return $?
}

function main()
{
    tmp_dir="/tmp/tmp"
    proj=$1
    if [ -d $tmp_dir ]; then
        rm -rf $tmp_dir
    fi
    mkdir $tmp_dir

    download_pypi $tmp_dir "/opt/stack/$proj/requirements.txt"
    download_pypi $tmp_dir "/opt/stack/$proj/test-requirements.txt"
    orig_dir $tmp_dir

    echo "please copy $tmp_dir to your http server" 

}


function usage()
{
    echo "please use $1 [project]"
    echo "for example:"
    echo "./$1 nova"
    exit 1
}
if [ -z $1 ]; then
    usage $0
fi
main $1
