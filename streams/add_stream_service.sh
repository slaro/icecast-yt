#!/usr/bin/env bash

URL="${1}"
MOUNT="${2}"

echo "[Unit]
Description=${MOUNT} daemon
After=network.target
After=icecast2.service

[Service]
Type=simple
ExecStart=/opt/streams/stream.sh ${URL} ${MOUNT}
Restart=always

[Install]
WantedBy=multi-user.target" > "/etc/systemd/system/${MOUNT/\//_}.service"

systemctl enable "${MOUNT/\//_}"
systemctl start "${MOUNT/\//_}"