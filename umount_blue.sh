#UnMount an rhevh blue iso
#
#author: Eli Qiao
#!/bin/bash
set -x
DIR_1="/mnt/1"
DIR_2="/mnt/2"
DIR_3="/mnt/3"

umount $DIR_3
umount $DIR_2
umount $DIR_1

rm -rf $DIR_3 $DIR_2 $DIR_1


