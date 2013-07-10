#!/bin/bash

# down rpm (require rpm.lst) from ftp3 server.


USERID="qiaoly@cn.ibm.com"
PASSWD="ltc1234_++"


function download_rpm()
{
    BASEURL="ftp://ftp3.linux.ibm.com/redhat/yum/6/server/updates/x86_64/RPMS/"
    RPM=$1
    wget -q  --user="${USERID}" --password="${PASSWD}" ${BASEURL}${RPM}
}

function main()
{
    RPM_LIST="${1:-rpm.list}"
    DIR="${2:-tmp}"
   
    if [[ ! -d ${DIR} ]]; then
        mkdir ${DIR}
    fi
    local TOTAL=0
    local TOTAL_DOWNLOADS=0
    local NODOWNLOAD_RPM=
    for rpm in $(cat "${RPM_LIST}")
    do
        TOTAL=$((TOTAL+1))
        rpm_file="${rpm}".rpm
        download_rpm "${rpm_file}"
        if [[ $? -eq 0 ]]; then
            TOTAL_DOWNLOADS=$((TOTAL_DOWNLOADS+1))
            mv ${rpm_file} ${DIR}
        else
            NODOWNLOAD_RPM=${NODOWNLOAD_RPM}"\r\n"${rpm}
        fi
    done
    echo "-----"
    echo "${TOTAL_DOWNLOADS}/${TOTAL} file(s) download"
}

main $@
