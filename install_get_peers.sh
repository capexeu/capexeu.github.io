mkdir /home/cardano/node_exporter/peers 
wget -P /home/cardano/cardano-node/scripts/ https://capexeu.github.io/get_peers.sh

chmod 777 /home/cardano/cardano-node/scripts/get_peers.sh

(crontab -u cardano -l 2>/dev/null; echo "0-59 * * * * /home/cardano/cardano-node/scripts/get_peers.sh") | crontab -

cat >/etc/systemd/system/node_exporter.service <<EOF
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
EOF

systemctl daemon-reload
