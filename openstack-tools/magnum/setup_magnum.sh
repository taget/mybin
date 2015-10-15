#!/bin/bash

#set -x
source /home/taget/devstack/openrc admin admin

ATOMIC_IMAGE=fedora-21-atomic-5-d181.qcow2
KEYPAIR=testkey

sudo iptables-save  | grep "172.24.4.0/24 -o br-ex -j MASQUERADE"
if [[ $? -ne 0 ]]; then
    echo "adding  nat rule"
    sudo iptables -t nat -A POSTROUTING -s 172.24.4.0/24 -o br-ex -j MASQUERADE
fi

nova keypair-list | grep $KEYPAIR
if [[ $? -ne 0 ]]; then
    echo "adding keypair..."
    nova keypair-add --pub-key /home/taget/.ssh/id_rsa.pub $KEYPAIR
fi

image_name=$(echo $ATOMIC_IMAGE | cut -d . -f 1)

glance image-list | grep $image_name

if [[ $? -ne 0 ]]; then
    echo "loading $ATOMIC_IMAGE ..."
    glance image-create --name fedora-21-atomic-5-d181 --visibility public \
                        --disk-format qcow2 \
                        --property os_distro='fedora-atomic' \
                        --container-format bare < /home/taget/Downloads/fedora-21-atomic-5-d181.qcow2
fi

NIC_ID=$(neutron net-show public | awk '/ id /{print $4}')


magnum baymodel-list | grep k8sbaymodel-proxy

if [[ $? -ne 0 ]]; then
    echo "creating k8sbaymodel..."
    magnum baymodel-create --name k8sbaymodel-proxy --image-id $image_name \
                           --keypair-id $KEYPAIR \
                           --external-network-id $NIC_ID \
                           --dns-nameserver 10.248.2.5 \
                           --flavor-id m1.small --docker-volume-size 5 \
                           --coe kubernetes --fixed-network 192.168.0.0/24 \
                           --network-driver flannel \
                           --http-proxy http://10.239.4.160:911/ \
                           --https-proxy https://10.239.4.160:911/ \
                           --no-proxy 192.168.0.1,192.168.0.2,192.168.0.3,192.168.0.4,192.168.0.5,192.168.0.6
fi

magnum baymodel-list | grep swarmmodel
if [[ $? -ne 0 ]]; then
    echo "creating swarmmodel..."
    magnum baymodel-create --name swarmmodel --image-id $image_name \
                           --keypair-id $KEYPAIR \
                           --external-network-id $NIC_ID \
                           --dns-nameserver 10.248.2.5 \
                           --flavor-id m1.small --docker-volume-size 5 \
                           --coe swarm --fixed-network 192.168.0.0/24 \
                           --http-proxy http://10.239.4.160:911/ \
                           --https-proxy https://10.239.4.160:911/ \
                           --no-proxy 192.168.0.1,192.168.0.2,192.168.0.3,192.168.0.4,192.168.0.5
fi

magnum bay-list | grep swarmbay
if [[ $? -ne 0 ]]; then
    echo "creating bay swarmbay ..."
    magnum bay-create --name swarmbay --baymodel swarmmodel --node-count 1
fi

magnum bay-list | grep k8s
if [[ $? -ne 0 ]]; then
    echo "creating bay k8s ..."
    magnum bay-create --name k8s-proxy --baymodel k8sbaymodel-proxy --node-count 1
fi
