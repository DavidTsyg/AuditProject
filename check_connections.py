#! /usr/bin/python

#Imports
import subprocess
import os


print "Flushing all rules" 
#Flushing all rules
subprocess.call(["iptables -F"], shell=True)
subprocess.call(["iptables -t filter -F"], shell=True)
subprocess.call(["iptables -t filter -X"], shell=True)
subprocess.call(["iptables -t nat -F"], shell=True)
subprocess.call(["iptables -t nat -X"], shell=True)
subprocess.call(["iptables -t mangle -F"], shell=True)
subprocess.call(["iptables -t mangle -X"], shell=True)
subprocess.call(["iptables -t filter -P INPUT ACCEPT"], shell=True)
subprocess.call(["iptables -t filter -P OUTPUT ACCEPT"], shell=True)
subprocess.call(["iptables -t filter -P FORWARD ACCEPT"], shell=True)
subprocess.call(["iptables -- flush"], shell=True)


print "Getting the attempted connections" 
#Getting the attempted connections
buf = "temp"
ip_addresses = []
result = 0
log = open("/etc/ansible/ps_ax_result", 'w')
subprocess.call(["ps ax"], stdout=log, shell=True)
log.close()
for file in os.listdir("/home/david/ovpn_files"):
	buf = file[:20]
	buf = buf[6:]
	subprocess.call(["ip rule del from all fwmark " + buf[11:]], shell=True)
	log = open("/etc/ansible/ps_ax_result", 'r')
	for line in log:
		result = line.find(buf)
		if result != -1:
			ip_addresses.append(buf)
			print buf
			break
	log.close()
subprocess.call(["ip rule sh "], shell=True)
print "Getting the working connections" 
ping_buf = 0
print "These are working connections:"
for item in ip_addresses:
	network_log = open("/etc/ansible/ping_result", 'w')
	subprocess.call(["ping -w 2 10.8." + item[11:] + ".1"], stdout=network_log, shell=True)
	network_log.close()
	network_log = open("/etc/ansible/ping_result", 'r')
	ping_buf = 0
	for line in network_log:
		ping_buf+=1
		print line
	if ping_buf == 5:
		ip_addresses.remove(item)
	else:
		print item
	network_log.close()

print "Adding the needed tables"
#Adding the needed tables
tables_file = open("/etc/iproute2/rt_tables", "r+")
contents = tables_file.readlines()
tables_file.seek(0)
for table in contents:
	result = table.find("VPN")
	if result == -1:
		tables_file.write(table)
for item in ip_addresses:
	tables_file.write(item[11:] + "     VPN" + item + "\n")
tables_file.truncate()
tables_file.close()

print "Adding defalt routes"
#Adding defalt routes
working_hosts_num = 0
for item in ip_addresses:
	subprocess.call(["ip route add default via 10.8." + item[11:] + ".5 table VPN" + item], shell=True)
	working_hosts_num += 1
print "Marking the tunnels"
#Marking the tunnels
for item in ip_addresses:
	subprocess.call(["ip rule add fwmark " + item[11:] +" table VPN" + item + " prio " + item[11:]], shell=True)
subprocess.call(["ip route flush cache"], shell=True)
subprocess.call(["/etc/ansible/rp_filter_zero.sh"], shell=True)

print "Initializing CONNMARKS"
#Initializing CONNMARKS
for item in ip_addresses:
	subprocess.call(["iptables -t mangle -N  CONNMARK" + item], shell=True)
	subprocess.call(["iptables -t mangle -A  CONNMARK" + item + " -j MARK --set-mark " + item[11:]], shell=True)
	subprocess.call(["iptables -t mangle -A  CONNMARK" + item + " -j CONNMARK --save-mark"], shell=True)

print "This is for established connections"
#This is for established connections
subprocess.call(["iptables -t mangle -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark"], shell=True)

print "This is for new connections"
#This is for new connections
for i in range(working_hosts_num):
	subprocess.call(["iptables -t mangle -A OUTPUT -m conntrack --ctstate NEW -m statistic --mode nth --every " + str(working_hosts_num) +" --packet " + str(i) + " -j CONNMARK" + (ip_addresses[i])], shell=True)

print "Masquerading"
#Masquerading
for i in range(working_hosts_num):
	subprocess.call(["iptables -t nat -A POSTROUTING -o tun" + str(i) + " -j MASQUERADE"], shell=True)
