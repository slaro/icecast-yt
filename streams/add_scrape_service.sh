#!/usr/bin/env bash

URL="${1}"
MOUNT="${2}"

UPLOADER=$(youtube-dl -s -j 'https://www.youtube.com/watch?v=5qap5aO4i9A' | jq -r '.uploader')
if [[ "${UPLOADER^^}" != "LOFI GIRL" ]]; then
    exit 0
fi

echo "[Unit]
Description=${MOUNT}-scrape daemon
After=network.target
After=icecast2.service

[Service]
Type=simple
ExecStart=/opt/streams/scrape.py ${URL} ${MOUNT}
Restart=always

[Install]
WantedBy=multi-user.target" > "/etc/systemd/system/${MOUNT/\//_}-scrape.service"

systemctl enable "${MOUNT/\//_}-scrape"
systemctl start "${MOUNT/\//_}-scrape"