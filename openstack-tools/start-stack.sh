#!/bin/bash

# setup cinder vg and start devstask service in background

#set -x

OS_DATA=/opt/stack/data
DEVSTACK_DIR=~/devstack

source $DEVSTACK_DIR/functions
source $DEVSTACK_DIR/stackrc



function mound_vg {
    ARR=($(\ls -m $OS_DATA/stack-volumes-* |tr "," " "| tr ":" " "))
    for i in ${ARR[@]}; do
        echo "losetup "$i
        sudo losetup -f $i
    done

}


echo "mounting volume vg"
mound_vg

echo "start openstack.."

if screen -ls | egrep -q "[0-9].stack"; then
    echo "swift service is already started!"
    exit 0
else
    screen -d -m -c $DEVSTACK_DIR/stack-screenrc
fi
echo "openstack started"
