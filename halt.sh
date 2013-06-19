#!/bin/bash



set -x

read confirm

if [[ $confirm == 'y' ]]; then
    echo "will halt system  in 20s"
else
    exit 1
fi

sudo virsh shutdown xp11

sleep 20

sudo init 0

