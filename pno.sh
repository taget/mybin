#!/bin/bash

APPLIST=(
	"thunderbird"
	"pidgin"
	"goldendict"
        "google-chrome"
)

SRC_LIST=(
         "/home/qiaoliyong/sda/code/libvirt"
         "/home/qiaoliyong/sda/code/qemu"
         )

usage() {
cat << EOF
usage: $0 [options]

    -s Show the apps run list.
    -l List the app lists.
    -r Restart all apps.
    -k Kill all apps.
    -m Maintain all apps.
Example:
$0 
EOF
}
# pull git
function pull_git()
{
    cd $1
    git pull
    cd -
}

# pull all git in SRC_LIST
function pull_all_git()
{
    for src in "${SRC_LIST[@]}"; do
         pull_git ${src}
    done
}
function extr_app()
{
    sudo libvirtd -d
    sudo virsh start xp
}
# kill $1
function kill_bin()
{ 
  APP=$1
  ps -ef | grep ${APP} | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1
  return $?
}

function run_bin()
{
  APP=$1
  /usr/bin/${APP} &
  return $?
}

function show_app()
{
  echo "App Running list .... "
  for app in "${APPLIST[@]}"; do
    ps -ef | grep ${app} | grep -v "grep" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo $app is running...
    fi
  done 
}

function restart_app()
{
  echo ""
  for app in "${APPLIST[@]}"; do
    kill_bin $app
    run_bin $app
  done
}

function list_app()
{
  for app in "${APPLIST[@]}"; do
    echo $app
  done
}

function maintain_app()
{
  for app in "${APPLIST[@]}"; do
    ps -ef | grep ${app} | grep -v "grep" >/dev/null 2>&1
    if [[ ! $? -eq 0 ]]; then
        echo "starting ${app}"
        run_bin ${app}
    fi
  done
}

function kill_all()
{
  for app in "${APPLIST[@]}"; do
    echo "killing ${app}"
    kill_bin $app
  done

}

while getopts "hsrlmk" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         s)
            show_app
             ;;
         r)
            restart_app
            ;;
         l)
            list_app
            ;;
         m)
            maintain_app
            ;;
         k)
            kill_all
            ;;
         ?)
             usage
             exit 1
             ;;
     esac
done

if [[ $# -eq 0 ]]; then
  echo "Maintain ..."
  maintain_app
fi

pull_all_git


/home/qiaoliyong/mybin/bso.sh ltcphx.austin.ibm.com
/home/qiaoliyong/mybin/bso.sh 9.181.129.110
sleep 10
ssh -qTfnN -D 8080 qiaoly@ltcphx.austin.ibm.com 
python /home/qiaoliyong/Downloads/goagent-goagent-6287469/local/proxy.py
#extr_app
