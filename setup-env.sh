#!/bin/bash

sudo ip tuntap add name tap0 mode tap user ${LOGNAME}
sudo ip addr add 192.168.10.254/24 dev tap0
sudo ip link set up dev tap0
sudo firewall-cmd --zone=trusted --change-interface=tap0

wget https://github.com/ubccr/grendel/releases/download/v0.0.8/grendel-0.0.8-linux-x86_64.tar.gz
tar xvzf grendel-0.0.8-linux-x86_64.tar.gz
mv grendel-0.0.8-linux-x86_64/* ./