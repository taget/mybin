#!/bin/bash


#set -x 

PKG_NAME=""
PBUILD=""
SPEC_FILE_TMP=""
SPEC_FILE=""
#REPO=delete_mcp8_0
REPO=pkvm2_1
ARCH=ppc64
MAILER=qiaoly@cn.ibm.com
COPY=N

KOJI_DIR=/mnt/koji/scratch/simonjin/task_
COPY_DIR=root@9.3.189.26:/scratch/frobisher/

# log to mail_temp
function log()
{
   echo "$(date) $@" | tee -a mail_temp
}  

# username $1
# passwd $2
# exp  $3
# url $4
function wget_tgz()
{
    username=$1
    passwd=$2
    exp=$3
    url=$4
    wget --user=${username} --password=${passwd} -r -nd -np -A ${exp} ${url}
}

# usage
function usage()
{
   cat << EOF
   -p package name
   -r Release number default is 0
   -t Type , release or update
   -b git branch
   -u git url
   -v rpm version
   -c copy rpms to location
EOF
}

# clean srpm and mail_temp
function clean()
{
    log "cleaning..."
rm -rm *.tgz
rm -rf ${DIR}/DIRPMS
rm -rf ${DIR}/RMPS

}

while getopts "hr:t:c:mp:b:u:d:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         r)
            Release=$OPTARG
            ;;
         t)
            Type=$OPTARG
            ;;
         c)
            COPY_DIR=$OPTARG
            ;;
         m)
            Mailer=$OPTARG
            ;;
         p)
            PKG_NAME=$OPTARG
            ;;
         b)
            BRANCH=$OPTARG
            ;;
         u)
            URL=$OPTARG
            ;;
         d)
            DIR=$OPTARG
            ;;
         ?)
             usage
             exit 1
             ;;
     esac
done


# replace ${SPEC_FILE_TMP}  with git url,branch,and rpmversion
function replace_spec()
{
   awk \
   -v inputfile=${SPEC_FILE_TMP} \
   -v git_url=${GIT_URL} \
   -v branch=${BRANCH} \
   -v version=${RPM_VERSION} \
'
BEGIN {
    FS = " ";
    OFS = " ";
    while(getline < inputfile) {
        for (i = 1; i <= NF; ++i) {
            if ($i == "git" && $(1+i) == "clone") {
                $(2+i) = git_url;
            }
            if ($i == "git" && $(1+i) == "checkout") {
                $(2+i) = "remotes/origin/"branch;
            }
        }
        if($2 == "frobisher_release") {
            $(1+2) = "."version;
        }
    output[++count] = $0;
    }
    for(j = 1; j <= count; ++j) {
        print output[j];
    }
}

'>${SPEC_FILE}

}


if [ -z $COPY_DIR ]; then
    UPDATE_DIR=new
fi

if [ -z $URL ]; then
    usage
    exit 1
fi

if [ -z ${DIR} ];then
    DIR="/tmp"
fi

wget_tgz qiaoly mygsapassw0rd *-rpms.tar.gz ${URL}

for i in $(ls *.tar.gz); do
    tar -xf ${i} -C ${DIR}
done

if [ ! -d ${COPY_DIR} ];then
     mkdir ${COPY_DIR}
fi

# copy kernel

if [ -d ${DIR}/RMPS ]; then
    echo "copy rpms ..."
    cp ${DIR}/RMPS/ppc64/kernel* ${COPY_DIR}
    cp ${DIR}/RMPS/ppc64/SLOF* ${COPY_DIR}
    cp ${DIR}/RMPS/ppc64/kimchi-* ${COPY_DIR}
    cp ${DIR}/RMPS/ppc64/ksm* ${COPY_DIR}
    cp ${DIR}/RMPS/ppc64/libvirt-* ${COPY_DIR}
    cp ${DIR}/RMPS/ppc64/perf-* ${COPY_DIR}
    cp ${DIR}/RMPS/ppc64/python-perf-* ${COPY_DIR}
    cp ${DIR}/RMPS/ppc64/qemu* ${COPY_DIR}
fi


if [ -d ${DIR}/DIRPMS ]; then
    echo "copy debuginfo rpms ..."
    cp ${DIR}/DIRPMS/ppc64/kernel* ${COPY_DIR}
    cp ${DIR}/DIRPMS/ppc64/libvirt* ${COPY_DIR}
    cp ${DIR}/DIRPMS/ppc64/qemu-* ${COPY_DIR}
fi

clean
