#!/bin/bash
ST=`nova hypervisor-servers $HOSTNAME | grep $1`
if [[ $? != 0 ]] ; then
    echo "not find $1 on $HOSTNAME"
    nova hypervisor-servers $HOSTNAME
    exit 1
fi

ST=`nova show $1`
if [[ $? != 0 ]] ; then
    nova list
    exit 1
fi

QEMU_NAME=`nova show $1 |grep "OS-EXT-SRV-ATTR:instance_name" | awk '{print $4}'`
if [[ $? != 0 ]] ; then
    exit 1
fi

ST=`sudo virsh domstate $1`
if [[ $? != 0 ]] ; then
    exit 1
fi
if [[ "$ST" =~ "shut off" ]] ; then
    sudo virsh list --all
    echo "$QEMU_NAME is shut off"
    exit 1
fi
echo "vm name is: $QEMU_NAME"

QEMU_CMD=`ps -ef |grep " $QEMU_NAME " |grep -v grep`
# echo $QEMU_CMD
QEMU_PID=`cut -d " " -f2 <<< $QEMU_CMD`
CMD_IFS=""
IF_FD=""
HOST_FD=""
[[ "$QEMU_CMD" =~ "-netdev" ]] && CMD_IFS=${QEMU_CMD#*-netdev}
[[ "$QEMU_CMD" =~ "tap,fd=" ]] && CMD_IFS=${CMD_IFS#*tap,fd=} && IF_FD=${CMD_IFS%%,*}
[[ "$QEMU_CMD" =~ "vhostfd=" ]] && CMD_IFS=${CMD_IFS#*vhostfd=} && HOST_FD=${CMD_IFS%% *}
[[ "$QEMU_CMD" =~ "mac=" ]] && CMD_MAC=${QEMU_CMD#*mac=} && CMD_MAC=${CMD_MAC%%,*}

echo "qemu pid is: $QEMU_PID, iface host fd: $HOST_FD, iface fd: $IF_FD, iface MAC: $CMD_MAC"

# egrep -l iff:.*tap* /proc/*/fdinfo/* 2>/dev/null|cut -d/ -f3
TAPNAME=`sudo cat /proc/$QEMU_PID/fdinfo/$IF_FD | grep "iff:.*tap*"`
TAPNAME=${TAPNAME#iff:[[:space:]]*}
# TAPNAME="${TAPNAME##[[:space:]]}"
# TAPNAME="${TAPNAME//[[:space:]]/}"

# kernel version less than 3.14
if [[ -z $TAPNAME ]];  then
TAPNAME=`ifconfig |grep ${CMD_MAC:2}`
TAPNAME="${TAPNAME%%[[:space:]]*}"
fi

BR=`ls -l /sys/class/net/$TAPNAME/brport/bridge`
BR=${BR##*/}
# BR=""
# for br in `ls /sys/class/net/`; do
#     if [[ -d "/sys/class/net/$br/bridge"  && -d  "/sys/class/net/$br/lower_$TAPNAME" ]]; then
#         BR=$br     
#         break
#     fi   
# done

echo ""
echo "************************************************"
echo "VM:$QEMU_NAME ---> tap: $TAPNAME ---> bridge: $BR"
echo "************************************************"

echo ""
echo "************************************************"
echo "bridge: $BR"
for port in `ls /sys/class/net/$BR/brif/`; do
    echo "           |__ $port"
done
echo "************************************************"

# BR_PORT="qvb${BR:3}"
# OVS_PORT="qvo${BR_PORT:3}"
OVS_BR_INT=""
echo ""
echo "************************************************"
for port in `ls /sys/class/net/$BR/brif/`; do
    PORT_TY=`ethtool -i $port | grep "driver:" |awk '{print $2}'`
    if [[ $PORT_TY == "veth" ]] ; then
        PEER_INDEX=`ethtool -S $port | grep "peer_ifindex:" |awk '{print $2}'`
        for peer in `ls /sys/class/net/`; do
            INDEX=`cat /sys/class/net/$peer/ifindex`
            if [[ $PEER_INDEX == $INDEX ]]; then
                if [[ -d /sys/class/net/$OVS_PORT/brport/bridge ]]; then
                    OVS_BR_INT=`ls /sys/class/net/$OVS_PORT/brport/bridge -l`
                    OVS_BR_INT=${OVS_BR_INT##*/}
                else
                    OVS_BR_INT=`sudo ovs-vsctl port-to-br $peer`
                    # OVS_BR_INT=`sudo ovs-vsctl iface-to-br $peer`
                fi
                echo "bridge: $BR                                  bridge: $OVS_BR_INT"
                echo "           |__ patch: $port <----> patch: $peer __|"
            fi
        done
    fi
done
echo "************************************************"

IS_OVS=`sudo ovs-vsctl list-br | grep $OVS_BR_INT`
OVS_INFOS=`sudo ovs-vsctl show |tr "\n" " "`
ALL=""

echo ""
echo "************************************************"
while [[ "$OVS_INFOS" =~ "{peer=" ]]
do
    PORT=${OVS_INFOS%%\}*}
    PORT=${PORT%[[:space:]]*type*}
    PORT=${PORT##*Interface}
    PORT=`echo $PORT`
    PEER=${OVS_INFOS#*\{peer=}
    PEER=${PEER%%\}*}
    OVS_INFOS=${OVS_INFOS#*\{peer=*\}}
    if [[ ! "$ALL" =~ "$PORT" ]]
    then
        ALL="$ALL $PORT $PEER"
        PEER_BR=`sudo ovs-vsctl iface-to-br $PORT`
        BR=`sudo ovs-vsctl iface-to-br $PEER`
        echo "bridge: $BR                                   bridge: $PEER_BR"
        echo "           |__ veth: $PEER <----> veth: $PORT __|"
        echo ""
    else
        continue
    fi
done
echo "************************************************"

# for port in `sudo ovs-vsctl show |grep "options: {peer=" |cut -d "=" -f2`
# do
#     port=${port%%\}*}
#     THIS_BR=`sudo ovs-vsctl iface-to-br $port`
#     if [[ $THIS_BR == $OVS_BR_INT ]]; then
#          
#         echo "bridge: $THIS_BR                             bridge: $PEER_BR"
#         echo "           |__ veth: $port <----> veth: $peer __|"
#      
#     fi
# done
