#!/bin/bash
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
CNODE_PID=$(pgrep -a cardano-node | awk '{print $1}')
CNODE_PORT=$(cat /home/cardano/cardano-node/relay.environment | awk -F "=" '$1 == "PORT" {print $2}')
EKG_PORT=12789
PROM_PORT=12799
peers_in=$(lsof -Pnl +M | grep ESTABLISHED | awk -v pid="${CNODE_PID}" -v port=":${CNODE_PORT}->" '$2 == pid && $9 ~ port {print $9}' | awk -F "->" '{print $2}')
peers_out=$(lsof -Pnl +M | grep ESTABLISHED | awk -v pid="${CNODE_PID}" -v port=":(${CNODE_PORT}|${EKG_PORT}|${PROM_PORT})->" '$2 == pid && $9 !~ port {print $9}' | awk -F "->" '{print $2}')
peers_out_nr=$(echo "$peers_out" | wc -l)
peers_in_nr=$(echo "$peers_in" | wc -l)
cat >/home/cardano/node_exporter/peers/peers.prom <<EOL
peers_in $peers_in_nr
peers_out $peers_out_nr
EOL
