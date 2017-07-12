#! /bin/bash

#Flushing tables
iptables -t filter -F
iptables -t filter -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t filter -P INPUT ACCEPT
iptables -t filter -P OUTPUT ACCEPT
iptables -t filter -P FORWARD ACCEPT


#Creating iptables for VPN tunnels
ip route flush table VPN1
ip route flush table VPN2
ip route flush table VPN3
ip route flush table VPN4

ip route add default dev tun0 via 10.8.1.5 table VPN1
ip route add 10.8.1.1/32 via 10.8.1.5 table VPN1
ip route add default dev tun1 via 10.8.2.5 table VPN2
ip route add 10.8.2.1/32 via 10.8.2.5 table VPN2
ip route add default dev tun2 via 10.8.3.5 table VPN3
ip route add 10.8.3.1/32 via 10.8.3.5 table VPN3
ip route add default dev tun3 via 10.8.4.5 table VPN4
ip route add 10.8.4.1/32 via 10.8.4.5 table VPN4

#Marking the tunnels
iprule del from all fwmark 1 2>/dev/null
iprule del from all fwmark 2 2>/dev/null
iprule del from all fwmark 3 2>/dev/null
iprule del from all fwmark 4 2>/dev/null
ip rule add fwmark 1 table VPN1 prio 10
ip rule add fwmark 2 table VPN2 prio 20
ip rule add fwmark 3 table VPN3 prio 30
ip rule add fwmark 4 table VPN4 prio 40
ip route flush cache
for i in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > "$i"; done
#echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
#echo 0 > /proc/sys/net/ipv4/conf/tun0/rp_filter
#echo 0 > /proc/sys/net/ipv4/conf/tun1/rp_filter
#echo 0 > /proc/sys/net/ipv4/conf/tun2/rp_filter
#echo 0 > /proc/sys/net/ipv4/conf/tun3/rp_filter

#Initializing the 4 chains to mark traffic 
iptables -t mangle -N CONNMARK1
iptables -t mangle -A CONNMARK1 -j MARK --set-mark 1
iptables -t mangle -A CONNMARK1 -j CONNMARK --save-mark

iptables -t mangle -N CONNMARK2
iptables -t mangle -A CONNMARK2 -j MARK --set-mark 2
iptables -t mangle -A CONNMARK2 -j CONNMARK --save-mark

iptables -t mangle -N CONNMARK3
iptables -t mangle -A CONNMARK3 -j MARK --set-mark 3
iptables -t mangle -A CONNMARK3 -j CONNMARK --save-mark

iptables -t mangle -N CONNMARK4
iptables -t mangle -A CONNMARK4 -j MARK --set-mark 4
iptables -t mangle -A CONNMARK4 -j CONNMARK --save-mark

#Allow LAN trafic
#iptables -t mangle -A PREROUTING -i tun0 -s 10.8.1.0/24 -d 10.8.1.0/24 -j ACCEPT
#iptables -t mangle -A PREROUTING -i tun1 -s 10.8.2.0/24 -d 10.8.2.0/24 -j ACCEPT
#iptables -t mangle -A PREROUTING -i tun2 -s 10.8.3.0/24 -d 10.8.3.0/24 -j ACCEPT
#iptables -t mangle -A PREROUTING -i tun3 -s 10.8.4.0/24 -d 10.8.4.0/24 -j ACCEPT

#This is for established connections
iptables -t mangle -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
#iptables -t mangle -A INPUT -m state --state ESTABLISHED,RELATED -j CONNMARK --restore-mark

#This is for new connections
iptables -t mangle -A OUTPUT -m conntrack --ctstate NEW \
         -m statistic --mode nth --every 4 --packet 0 -j CONNMARK1
iptables -t mangle -A OUTPUT -m conntrack --ctstate NEW \
         -m statistic --mode nth --every 4 --packet 1 -j CONNMARK2
iptables -t mangle -A OUTPUT -m conntrack --ctstate NEW \
         -m statistic --mode nth --every 4 --packet 2 -j CONNMARK3
iptables -t mangle -A OUTPUT -m conntrack --ctstate NEW \
         -m statistic --mode nth --every 4 --packet 3 -j CONNMARK4
#iptables -t mangle -A INPUT -m state --state NEW \
#         -m statistic --mode nth --every 4 --packet 0 -j CONNMARK1
#iptables -t mangle -A INPUT -m state --state NEW \
#         -m statistic --mode nth --every 4 --packet 1 -j CONNMARK2
#iptables -t mangle -A INPUT -m state --state NEW \
#         -m statistic --mode nth --every 4 --packet 2 -j CONNMARK3
#iptables -t mangle -A INPUT -m state --state NEW \
#         -m statistic --mode nth --every 4 --packet 3 -j CONNMARK4

#iptables -t nat -A POSTROUTING -o tun0 -j SNAT --to-source 10.8.1.6
#iptables -t nat -A POSTROUTING -o tun1 -j SNAT --to-source 10.8.2.6
#iptables -t nat -A POSTROUTING -o tun2 -j SNAT --to-source 10.8.3.6
#iptables -t nat -A POSTROUTING -o tun3 -j SNAT --to-source 10.8.4.6

#iptables -t mangle -A OUTPUT -j CONNMARK --restore-mark
#iptables -t mangle -A OUTPUT -m mark ! --mark 0 -j ACCEPT
#iptables -t mangle -A OUTPUT -j MARK --set-mark 10
#iptables -t mangle -A OUTPUT -m statistic --mode random --probability 0.5 -j MARK --set-mark 20
#iptables -t mangle -A OUTPUT -m statistic --mode random --probability 0.333 -j MARK --set-mark 30
#iptables -t mangle -A OUTPUT -m statistic --mode random --probability 0.25 -j MARK --set-mark 40
#iptables -t mangle -A OUTPUT -j CONNMARK --save-mark

iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun2 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun3 -j MASQUERADE

#ip route del default via 192.168.17.2 dev ens33 proto static metric 100 table main
