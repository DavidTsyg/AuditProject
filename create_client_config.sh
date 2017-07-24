#! /bin/bash

server_ip=$(hostname -I | cut -f1 -d' ')

cd /client-configs
./make_config.sh "client${server_ip}"
