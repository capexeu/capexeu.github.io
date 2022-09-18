mkdir /home/cardano/node_exporter/peers 

cat >/home/cardano/cardano-node/scripts/get_peers.sh <<EOL2
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
EOL2

chmod 777 /home/cardano/cardano-node/scripts/get_peers.sh

(crontab -u cardano -l 2>/dev/null; echo "*/5 * * * * /home/cardano/cardano-node/scripts/get_peers.sh") | crontab -

cat >/etc/systemd/system/node_exporter.service <<EOL3
[Unit]
Description=Prometheus
After=syslog.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=5
User=cardano
LimitNOFILE=131072
WorkingDirectory=/home/cardano/
ExecStart=/home/cardano/node_exporter/node_exporter --collector.textfile.directory=/home/cardano/node_exporter/peers --collector.textfile
KillSignal=SIGINT
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=node_exporter

[Install]
WantedBy=multi-user.target
EOL3

systemctl daemon-reload
systemctl restart node_exporter