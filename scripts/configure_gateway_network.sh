#!/bin/sh

interface=enp0s8

echo "Configuring $interface interface"


grep -q -F "auto $interface" /etc/network/interfaces \
|| printf "\n\
auto $interface\n\
iface $interface inet static\n\
      address 192.168.0.1\n\
      netmask 255.255.0.0\n\
      dns-nameservers 192.168.0.5\n\
      dns-search ferrari.home\n\
      gateway 192.168.0.1\n" >> /etc/network/interfaces

echo "Bringing down $interface"
ifdown $interface

echo "Bringing $interface back up"
ifup $interface

# The first nameserver is the one that the host queries.
# The others are considered only if the first one times out
echo "Put ferrari.home DNS server on top in /etc/resolv.conf"

nameserver_line="nameserver 192.168.0.5"
sed -i "/$nameserver_line/d" /etc/resolv.conf
sed -i "/nameserver/c\\$nameserver_line" /etc/resolv.conf

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface enp0s3 -j MASQUERADE
# Add a line like this for each eth* LAN
iptables --append FORWARD --in-interface $interface -j ACCEPT
