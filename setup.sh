#!/usr/bin/env bash

random_password() {
    cat /dev/urandom | tr -dc 'A-Za-z0-9-_' | fold -w 32 | head -n 1
}

ICECAST_PORT=80
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
STREAMS_DIR='/opt/streams'
ICECAST_SOURCE_PASSWORD="$(random_password)"
ICECAST_RELAY_PASSWORD="$(random_password)"
ICECAST_ADMIN_USERNAME='admin'
ICECAST_ADMIN_PASSWORD="$(random_password)"
ICECAST_HOSTNAME=$(hostname -f)
ICECAST_USER=icecast2
ICECAST_GROUP=icecast
ICECAST_CONFIG=/etc/icecast2/icecast.xml

# install components
apt update
DEBIAN_FRONTEND=noninteractive apt install -y curl ffmpeg icecast2 python3 python-is-python3 python3-pip jq
python -m pip install --upgrade Pillow pytesseract requests youtube-dl

# setup icecast configuration
echo -n > "${ICECAST_CONFIG}"
cat <<EOF >> "${ICECAST_CONFIG}"
<icecast>
    <location>Earth</location>
    <admin>icemaster@localhost</admin>

    <limits>
        <clients>100</clients>
        <sources>2</sources>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>10</source-timeout>
        <burst-on-connect>1</burst-on-connect>
        <burst-size>65535</burst-size>
    </limits>

    <authentication>
        <source-password>$ICECAST_SOURCE_PASSWORD</source-password>
        <relay-password>$ICECAST_RELAY_PASSWORD</relay-password>
        <admin-user>$ICECAST_ADMIN_USERNAME</admin-user>
        <admin-password>$ICECAST_ADMIN_PASSWORD</admin-password>
    </authentication>

    <hostname>$ICECAST_HOSTNAME</hostname>

    <listen-socket>
        <port>$ICECAST_PORT</port>
    </listen-socket>

    <http-headers>
        <header name="Access-Control-Allow-Origin" value="*" />
    </http-headers>

    <fileserve>1</fileserve>
    <paths>
        <logdir>/var/log/icecast2</logdir>
        <webroot>/usr/share/icecast2/web</webroot>
        <adminroot>/usr/share/icecast2/admin</adminroot>
        <alias source="/" destination="/status.xsl"/>
    </paths>

    <logging>
        <accesslog>access.log</accesslog>
        <errorlog>error.log</errorlog>
        <loglevel>3</loglevel>
        <logsize>10000</logsize>
    </logging>

    <security>
        <chroot>0</chroot>

        <changeowner>
            <user>$ICECAST_USER</user>
            <group>$ICECAST_GROUP</group>
        </changeowner>

    </security>
</icecast>
EOF

echo -n > /etc/default/icecast2
cat <<EOF >> /etc/default/icecast2
CONFIGFILE="${ICECAST_CONFIG}"
USERID=root
GROUPID=root
EOF

# enable and start icecast
systemctl enable icecast2
systemctl restart icecast2

# copy scripts into streams directory
if [[ ! -d "${STREAMS_DIR}" ]]; then
    mkdir -p "${STREAMS_DIR}"
fi
cp "${SCRIPT_PATH}"/streams/scrape.py "${STREAMS_DIR}/"
cp "${SCRIPT_PATH}"/streams/stream.sh "${STREAMS_DIR}/"
cp "${SCRIPT_PATH}"/streams/add_stream /usr/local/bin/