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
echo ""
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

FLOATING_IP=`nova floating-ip-list |grep $1`
FIX_IP=`awk '{print $8}' <<< $FLOATING_IP`
FLOATING_IP=`awk '{print $4}' <<< $FLOATING_IP`
NETINFO=`nova show $1 |grep "network  *|"`
NETINFO=="${NETINFO##network[[:space:]]*|}"
NET_NAME="${NETINFO%[[:space:]]*network*}"
NET_NAME="${NET_NAME#*[[:space:]]*}"
NET_ID=`nova network-show $NET_NAME |grep "| *id *|" |awk '{print $4}'`
echo " fix ip is: $FIX_IP, floating ip is: $FLOATING_IP"
echo "network id is: $NET_ID" 
echo "and info please run: sudo ip netns exec qdhcp-$NET_ID"
# echo `cat /opt/stack/data/neutron/dhcp/$NET_ID/opts |grep "router"`

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
echo "================================================================================"
echo "The follow are L2 info:"
echo "************************************************"
echo "VM:$QEMU_NAME ---> tap: $TAPNAME ---> bridge: $BR"
echo "************************************************"

echo ""
echo "************************************************"
echo "bridge: $BR"
for port in `ls /sys/class/net/$BR/brif/`; do
    echo "           |__ port: $port"
done
echo "************************************************"

# BR_PORT="qvb${BR:3}"
# OVS_PORT="qvo${BR_PORT:3}"
function br_connetion_brs_by_veth()
{
    echo ""
    echo "************************************************"
    OVS_BR_INT=""
    BR=$1
    for port in `ls /sys/class/net/$BR/brif/`; do
        PORT_TY=`ethtool -i $port | grep "driver:" |awk '{print $2}'`
        if [[ $PORT_TY == "veth" ]] ; then
            PEER_INDEX=`ethtool -S $port | grep "peer_ifindex:" |awk '{print $2}'`
            for peer in `ls /sys/class/net/`; do
                INDEX=`cat /sys/class/net/$peer/ifindex`
                BR_TYPE="linux_br"
                if [[ $PEER_INDEX == $INDEX ]]; then
                    if [[ -d /sys/class/net/$OVS_PORT/brport/bridge ]]; then
                        BR_TYPE="linux_br"
                        OVS_BR_INT=`ls /sys/class/net/$OVS_PORT/brport/bridge -l`
                        OVS_BR_INT=${OVS_BR_INT##*/}
                    else
                        BR_TYPE="ovs_br"
                        OVS_BR_INT=`sudo ovs-vsctl port-to-br $peer`
                        # OVS_BR_INT=`sudo ovs-vsctl iface-to-br $peer`
                    fi
                    echo "bridge: $BR                                  $BR_TYPE: $OVS_BR_INT"
                    echo "           |__ veth: $port <----> veth: $peer __|"
                fi
            done
        fi
    done
    echo "************************************************"
}
br_connetion_brs_by_veth $BR

# IS_OVS=`sudo ovs-vsctl list-br | grep $OVS_BR_INT`

echo ""
echo "************************************************"
function connetion_between_brs_by_peer()
{
    OVS_INFOS=`sudo ovs-vsctl show |tr "\n" " "`
    ALL=""
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
            echo "ovs_br: $BR                                   ovs_br: $PEER_BR"
            echo "           |__ patch: $PEER <----> patch: $PORT __|"
            echo ""
        else
            continue
        fi
    done
}
connetion_between_brs_by_peer
echo "************************************************"


echo ""
echo "================================================================================"
echo "The follow are L3 info in namesapce:"
echo ""
echo "in name space qdhcp-$NET_ID:"
function ns_info()
{
    NS=$1
    LOCAL_IFS=`sudo ip netns exec $NS ip link |egrep "[0-9]+: " | awk '{print $2}'`
    for i in $LOCAL_IFS
    do
        if [[ ${i%%:} == lo ]]
        then 
            continue 
        fi
        echo "interface: ${i%%:}"
        sudo ip netns exec $NS ip a show ${i%%:} |grep "global ${i%%:}"
        DVR=`sudo ip netns exec $NS ethtool  -i ${i%%:}|grep "driver:" |awk '{print $2}'`
        if [[ $DVR ==  "openvswitch" ]]
        then
            OVS_BR=`sudo ip netns exec $NS ovs-vsctl iface-to-br ${i%%:}`
            echo "ovs-bridge: $OVS_BR" 
            echo "             |__ port: ${i%%:}"
        else
            echo "unknow iface type $DVR" 
        fi
        echo ""
    done
    return $((0+0));
    # return $($NS);
}

ns_info qdhcp-$NET_ID
echo "Get route info by:"
echo "sudo ip netns exec qdhcp-$NET_ID route"
echo "Get iptable info by:"
echo "sudo ip netns exec qdhcp-$NET_ID iptables -nv -t nat -L"

echo ""
echo  "namespace router is: "
for i in `sudo ip netns |grep qrouter-`
do
    echo "*****************************"
    NAME_S=$i
    ns_info $i
    echo "Get route info by:"
    echo "sudo ip netns exec $NAME_S route"
    echo "Get iptable info by:"
    echo "sudo ip netns exec $NAME_S iptables -nv -t nat -L"
    echo ""
done

function filter_link_by_ip()
{
    for i in `ip netns`;
    do
        L_IP=`sudo ip netns exec $i ip addr |grep $1`;
        if [[ ! -z $L_IP ]]; then
            L_PORT=${L_IP##*[[:space:]]}
            echo "sudo ip netns exec $i ip a show $L_PORT"
            sudo ip netns exec $i ip a show $L_PORT 
            break
        fi
    done
}
# filter_link_by_ip $FLOATING_IP

#something wrong with this logic
function ovs_br_2_ovs_br()
{
    for port in `sudo ovs-vsctl show |grep "options: {peer=" |cut -d "=" -f1`
    do
        port=${port%%\}*}
        echo $port
        THIS_BR=`sudo ovs-vsctl iface-to-br $port`
        if [[ $THIS_BR == $OVS_BR_INT ]]; then
             
            echo "bridge: $THIS_BR                             bridge: $PEER_BR"
            echo "           |__ veth: $port <----> veth: $peer __|"
         
        fi
    done
}

# ovs_br_2_ovs_br


# we can use this logic to find which VM attach to br_int
function connetion_between_brs()
{
    echo ""
    echo "************************************************"
    IS_OVS=`sudo ovs-vsctl list-br | grep $OVS_BR_INT`
    if [[ $IS_OVS == $OVS_BR_INT ]]; then
        for port in `sudo ovs-vsctl list-ifaces $OVS_BR_INT`; do
            PORT_TY=`ethtool -i $port 2>&- | grep "driver:" |awk '{print $2}'`
            if [[ $PORT_TY == "veth" ]] ; then
                PEER_INDEX=`ethtool -S $port | grep "peer_ifindex:" |awk '{print $2}'`
                for peer in `ls /sys/class/net/`; do
                    INDEX=`cat /sys/class/net/$peer/ifindex`
                    if [[ $PEER_INDEX == $INDEX ]]; then
                        PEER_INT=""
                        if [[ -d /sys/class/net/$peer/brport/bridge ]]; then
                            PEER_INT=`ls /sys/class/net/$peer/brport/bridge -l`
                            PEER_INT=${PEER_INT##*/}
                        else
                            PEER_INT=`sudo ovs-vsctl port-to-br $peer`
                            # PEER_INT=`sudo ovs-vsctl iface-to-br $peer`
                        fi
                        if [[ "x$PEER_INT" == "x" ]]; then
                            continue
                        fi
                        echo "bridge: $OVS_BR_INT                               bridge: $PEER_INT"
                        echo "           |__ veth: $port <----> veth: $peer __|"
                        echo ""
                    fi
                done
            fi
        done
    fi
    echo "************************************************"
}
# connetion_between_brs "br_int"

NETINFO=`nova show $1 |grep "network  *|"`
function find_nova_net_id()
{
     NETINFO=$1
     NETINFO="${NETINFO##network[[:space:]]*|}"
     NET_NAME="${NETINFO%[[:space:]]*network*}"
     NET_NAME="${NET_NAME#*[[:space:]]*}"
     ID=`nova network-show $NET_NAME |grep "| *id *|" |awk '{print $4}'`
     echo "$ID"
}
NET_ID=`find_nova_net_id "$NETINFO"`

function find_nova_net_ips()
{
    NETINFO=$1
    IPS="${NETINFO#*network[[:space:]]*|}"
    IPS="${IPS%[[:space:]]*|*}"
    IPS="${IPS%[[:space:]]*}"
    IPS=`tr "," " " <<<  ${IPS#*[[:space:]]}`
    for i in $IPS; do echo $i; done
}
# NET_ID=`find_nova_net_ips "$NETINFO"`

# ps ww `pgrep dnsmasq` |grep $NET_ID
