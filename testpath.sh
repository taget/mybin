#!/bin/bash

set -e
set -x

PKG_NAME=""
LOCAL_DIR=/home/qiaoliyong/pbuild-
REMOTE=""
REMOTE_DIR=root@kop1.austin.ibm.com:/data/taget/pbuild-
SUPPORT_DIR=$(find $HOME -maxdepth 1 -name "pbuild-*" -print | awk -F \/ '{print $NF}')

function scp_patch()
{
    if [[ $REMOTE == "59" ]]; then
        REMOTE_DIR=taget@9.181.129.59:/home/taget/pbuild5/pbuild-
    else
        REMOTE_DIR=root@kop1.austin.ibm.com:/data/taget/pbuild-
    fi
    scp "${LOCAL_DIR}""${PKG_NAME}"/* "${REMOTE_DIR}${PKG_NAME}/"
}

function support()
{
    for i in ${SUPPORT_DIR}
    do
        if [[ $i = "pbuild-$PKG_NAME" ]];then
            return 0
        fi
    done
    return 1

}
function usage()
{
cat << EOF
    -h print help
    -l push to kop
    -p package name
EOF
}

while getopts "hlp:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         p)
            PKG_NAME=$OPTARG
            ;;
         l)
            REMOTE=59
            ;;
         ?)
             usage
             exit 1
             ;;
     esac
done

if [[ -z ${PKG_NAME} ]]; then
    usage
    exit 1
fi

if ! support ; then
    echo "not support"
    exit 1
fi

scp_patch

echo $?
