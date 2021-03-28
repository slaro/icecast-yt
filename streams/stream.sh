#!/usr/bin/env bash

URL="${1}"
STREAM_MOUNT="${2}"

CLEAN_CONFIG=$(cat /etc/icecast2/icecast.xml | sed '/<!--.*-->/ d' | sed '/<!--/,/-->/ d')
ICECAST_SOURCE_PASSWORD=$(echo $CLEAN_CONFIG | grep -oP '(?<=<source-password>).*?(?=</source-password>)')
ICECAST_PORT=$(echo $CLEAN_CONFIG | grep -oP '(?<=<port>).*?(?=</port>)')

trap "exit" INT

youtube-dl -o - "${URL}" 2>/dev/null |
    ffmpeg -i pipe:0 -f mp3 icecast://source:$ICECAST_SOURCE_PASSWORD@localhost:$ICECAST_PORT/$STREAM_MOUNT