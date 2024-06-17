#!/bin/bash

sudo cat << 'EOF' /etc/systemd/system/isu-node.service >
[Unit]
Description=isu-node
After=syslog.target
[Service]
WorkingDirectory=/home/isucon/private_isu/webapp/node
EnvironmentFile=/home/isucon/env.sh
Environment=NODE_ENV=production
PIDFile=/home/isucon/private_isu/webapp/node/server.pid
User=isucon
Group=isucon
ExecStart=node app.js
ExecStop=/bin/kill -s QUIT $MAINPID
[Install]
WantedBy=multi-user.target
EOF

cd /home/isucon/private_isu/webapp/node
npm install
sudo daemon-reload
sudo systemctl disable isu-ruby
sudo systemctl stop isu-ruby
sudo systemctl enable isu-node
sudo systemctl start isu-node