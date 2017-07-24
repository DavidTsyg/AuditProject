#! /bin/bash

server_ip=$(hostname -I)

cd /client-configs
./make_config.sh "client$server_ip"
