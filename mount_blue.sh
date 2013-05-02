#Mount an rhevh blue iso
#
#author: Eli Qiao
#!/bin/bash
set -x
if [ -z $1 ]; then 
	echo "uasge $0 [rhevh blue iso]"
fi
DIR_1="/mnt/1"
DIR_2="/mnt/2"
DIR_3="/mnt/3"
mkdir -p $DIR_1
mkdir -p $DIR_2
mkdir -p $DIR_3 

mount -o loop $1 $DIR_1
mount -o loop $DIR_1/LiveOS/squashfs.img $DIR_2
mount -o loop $DIR_2/LiveOS/ext3fs.img $DIR_3

