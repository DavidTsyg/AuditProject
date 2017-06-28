#!/bin/bash
echo "This script is intended for dedicated openvpn servers."
echo "Be careful, as it can mess up your existing servers."
echo "Type in 'yes' if you want to proceed with the installation."
echo '\n'

read answer

if [$answer == "yes"]
then
   ip = 'hostname -I'
   # Here we are getting the packages we need
   sudo apt-get update
   sudo apt-get install openvpn easy-rsa
   sudo apt-get install ssh-server ssh-client
   make-cadir ~/openvpn-ca
   cp vars ~/openvpn-ca
   source ~/openvpn-ca/vars
   ~/openvpn-ca/clean-all
   ~/openvpn-ca/build-ca
   ~/openvpn-ca/build-key-server server
   ~/openvpn-ca/build-dh
   openvpn --genkey --secret ~/openvpn-ca/keys/ta.key
   source ~/openvpn-ca/vars
   ~/openvpn-ca/build-key-pass client1
   cd ~/openvpn-ca/keys
   sudo cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn
   cd -
   sudo cp server.conf /etc/openvpn/server.conf
   sudo cp sysctl.conf /etc/sysctl.conf
   sudo sysctl -p
   sudo cp before.rules /etc/ufw/before.rules
   sudo cp ufw /etc/default/ufw
   sudo systemctl start openvpn@server
   sudo systemctl status openvpn@server
   sudo systemctl enable openvpn@server
   sed '42s/.*/remote $ip 1194/' base.conf #find out the ip
   mkdir -p ~/client-configs/files
   chmod 700 ~/client-configs/files
   cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf
   cp make_config.sh ~/client-configs/make_config.sh
   chmod 700 ~/client-configs/make_config.sh
   ~/client-configs/make_config.sh client1
fi
