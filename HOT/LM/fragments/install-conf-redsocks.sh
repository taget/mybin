#cloud-boothook
#!/bin/sh

apt-get update
apt-get install redsocks


cat  > /etc/redsocks.conf << EOF
redsocks {
    local_ip = 127.0.0.1;
    local_port = 6666;
    // child-prc.intel.com proxy server IP
    ip = 10.239.4.160;
    port = 1080;
    type = socks5;
}

redudp {
    local_ip = 127.0.0.1;
    local_port = 8888;
    // child-prc.intel.com proxy server IP
    ip = 10.239.4.160;
    port = 1080;
}
EOF

service redsocks restart

iptables -t nat -N REDSOCKS || true
iptables -t nat -F REDSOCKS
iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 6666
iptables -t nat -A REDSOCKS -p udp -j REDIRECT --to-ports 8888
iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
