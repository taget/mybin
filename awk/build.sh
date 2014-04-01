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
URL=http://mcpkjhub1.austin.ibm.com/koji/taskinfo?taskID=

# log to mail_temp
function log()
{
   echo "$(date) $@" | tee -a mail_temp
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
    rm -rf ./${PKG_NAME}/*.src.rpm
    rm -rf ~/rpmbuild/SRPMS/*.src.rpm
    rm -rf mail_temp
}

# build rpm by a gaven srpm as $1
function build_rpm()
{
    SRPM=$1
    koji build --scratch --arch-override=${ARCH} ${REPO} ${SRPM}

}

function build_srpm()
{
  SPECFILE=$1
  if [ ! -f "${SPECFILE}" ];then
    log "no spec file found"
    exit 1
  fi

  if [ -f "${PKG_NAME}/Makefile" ]; then
    log "make srpm"
    make -C "${PKG_NAME}" REPO=mcp8_0-base srpm
  else
    log "rpmbuild srpm"
    rpmbuild -bs "${SPECFILE}"
 fi
 if [ $? -ne 0 ]; then
    log "build srpm error , please check it manually!"
    exit 1
 fi
}


# scp rpsm to ltcphx
# $1 taskid
# $2 pbuildx
function copy_rpms()
{
    TASKID=$1
    scp "${KOJI_DIR}${TASKID}"/*.rpm "${COPY_DIR}"
    return $?
}

function copy_logs()
{
    TASKID=$1
    LOGDIR=$2
    scp -r "${KOJI_DIR}${TASKID}"/logs "${COPY_DIR}/${LOGDIR}"
    return $?
}

while getopts "hr:t:cmp:b:u:v:" OPTION
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
            COPY='Y'
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
            GIT_URL=$OPTARG
            ;;
         v)
            RPM_VERSION=$OPTARG
            ;;
         ?)
             usage
             exit 1
             ;;
     esac
done


function pars_arg()
{
    if [[ -z ${PKG_NAME} ]]; then
        usage
        exit 1
    fi
    SPEC_FILE_TMP=./${PKG_NAME}/${PKG_NAME}.spec.tmp
    SPEC_FILE=./${PKG_NAME}/${PKG_NAME}.spec
    if [[ $Type == "r" ]]; then
        COPY_DIR="${COPY_DIR}/extra-packages/${ARCH}/build${Release}/"
    elif [[ $Type == "b" ]]; then
        COPY_DIR="${COPY_DIR}/extra-packages/${ARCH}/beta{Release}/"
    else
        COPY_DIR="${COPY_DIR}/PowerKVM/updates/0.${Release}/"
    fi
}

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

pars_arg

replace_spec

clean

#build srpm

build_srpm "${SPEC_FILE}"

# find srpm

SRPM=$(ls ./${PKG_NAME}/*.src.rpm)
if [ -z ${SRPM} ]; then
    SRPM=$(ls ~/rpmbuild/SRPMS/*.src.rpm)
fi

# build rpm
buildres=
copyres="NO require copy"

out=$(build_rpm ${SRPM})
buildres=$?
taskid=$(echo $out | egrep -o "ID=[0-9]*")
taskid=${taskid#ID=}

URL="${URL}${taskid}"
log "${URL}"

SRPM_NAME=$(echo $SRPM | awk -F "/" '{print $NF}')
LOG_DIR=${SRPM_NAME%%.src.rpm}-log

if [ ${COPY} == 'Y' ]; then
    copy_rpms ${taskid}
    copyres=$?
    copy_logs ${taskid} ${LOG_DIR}
fi
#log "copy status ${copyres}"

if [ $buildres -eq 0 ]; then
    cat mail_temp | mail -s "build ${PKG_NAME} sueecssfully" ${MAILER}
    exit 0
else
    cat mail_temp | mail -s "build ${PKG_NAME} failed" ${MAILER}
    exit 1
fi
