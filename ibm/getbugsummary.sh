#!/bin/bash


bin="bzl/bzl-get"
bin_log="bzl/bzl-login"

function usage()
{
    echo "Usage : ./searchbug.sh intranetid password buglistfile"
    echo "for example:"
    echo "./searchbug.sh my@ibm.com mypass a.list"
}

function download_bzl()
{
    git clone git://9.3.189.26/bzl.git 2>&1> /dev/null
    return $?
}

if [ $# -lt 2 ];then
    usage
    exit 1
fi

# check if bzl-login exist

if [ ! -f "${bin_log}" ]; then
   download_bzl
fi

username=$1
password=$2
buglist=${3-"a.list"}
# give a earlier time if date not gaven

./${bin_log} $username $password

if [ $? -ne 0 ]; then
    echo "log failed"
    exit 2
fi

for bug in `cat ${buglist}`; do
    echo ${bug} | egrep -o "[0-9]*" | xargs ./${bin} --format="%i - %S"
done


