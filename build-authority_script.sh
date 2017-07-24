#! /bin/bash

server_ip=$(hostname -I)

cd /openvpn-ca
source /openvpn-ca/vars
/openvpn-ca/clean-all
/openvpn-ca/build-ca < /openvpn-ca/build-ca_input
/openvpn-ca/build-key-server server < /openvpn-ca/build-key-server_input
/openvpn-ca/build-dh
openvpn --genkey --secret /openvpn-ca/keys/ta.key
source /openvpn-ca/vars
/openvpn-ca/build-key "client$server_ip" < /openvpn-ca/build-key-server_input
