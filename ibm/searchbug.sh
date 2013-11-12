#!/bin/bash


bin="bzl/bzl-search"
bin_log="bzl/bzl-login"

function usage()
{
    echo "Usage : ./searchbug.sh intranetid password [productname] [createdate] \
 [other option...]"
    echo "for example:"
    echo "./searchbug.sh my@ibm.com mypass (defult is pkvm and 2000-1-1)"
    echo "./searchbug.sh my@ibm.com mypass pkvm 2013-11-11"
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
product=${3-"pkvm"}
# give a earlier time if date not gaven
date=${4-"2000-1-1"}
other_option=${5}

./${bin_log} $username $password

if [ $? -ne 0 ]; then
    echo "log failed"
    exit 2
fi

echo "Product is ${product}"
echo "From date is ${date}"

status=(open
	assigned
	reopened
	FIXEDAWAITINGTEST
	REJECTED
	NEEDINFO
	closed
	)

for stat in ${status[@]}; do

	echo "------ Get [${stat}] status for ${product} from ${date} ------"
	./${bin} --product=${product} --format="%i-%s" --status=${stat}\
        --creation-time ${date} ${other_option}

done


