#!/bin/bash
#warning uid 1000 will be used to run services
#manual changes in some files might get overwriten
#prepare vars
DOCKER_BASE=/opt/docker
DOCKER_SERVICE=oauth2_proxy
USER_FOLDER=.trasba
#get username of uid 1000
varUser=$(id -nu 1000)
varHome=$(eval echo ~$varUser)
mkdir -p ${DOCKER_BASE}/${DOCKER_SERVICE}/container.conf
chown $varUser:$varUser ${DOCKER_BASE}/${DOCKER_SERVICE} -R

### wget github raw
sudo -u \#1000 wget https://raw.githubusercontent.com/trasba/docker-oauth2_proxy/amd64/docker-compose.yml -O ${DOCKER_BASE}/oauth2_proxy/container.conf/docker-compose.yml
#cat > ${DOCKER_BASE}/oauth2_proxy/container.conf/docker-compose.yml <<EOF
# version: '3.7'
# services:
#   oauth2_proxy:
#     image: containrrr/oauth2_proxy
#     labels:
#       com.centurylinklabs.oauth2_proxy.enable: "true"
#     restart: on-failure
#     volumes:
#       - /var/run/docker.sock:/var/run/docker.sock
#       - /etc/localtime:/etc/localtime:ro
#       - /etc/timezone:/etc/timezone:ro
#     command: --interval 3600 --label-enable
# EOF
ln -s container.conf/docker-compose.yml ${DOCKER_BASE}/${DOCKER_SERVICE}/

#cat > ${DOCKER_BASE}/oauth2_proxy/container.conf/production.yml <<EOF
#version: '3.7'
#EOF

sudo -u \#1000 cat > ${DOCKER_BASE}/${DOCKER_SERVICE}/container.conf/${DOCKER_SERVICE}.service <<EOF
[Unit]
Description=${DOCKER_SERVICE} Service
After=network.target docker.service
Requires=docker.service
[Service]
Type=simple
Restart=always
#RemainAfterExit=yes
Environment="WORK_DIR=${DOCKER_BASE}/${DOCKER_SERVICE}/"
WorkingDirectory=${DOCKER_BASE}/${DOCKER_SERVICE}/
ExecStart=/usr/local/bin/docker-compose -f "\${WORK_DIR}/docker-compose.yml" up
ExecStop=/usr/local/bin/docker-compose -f "\${WORK_DIR}/docker-compose.yml" down
User=${varUser}
Group=${varUser}

[Install]
WantedBy=docker.service
EOF
ln -s ${DOCKER_BASE}/${DOCKER_SERVICE}/container.conf/${DOCKER_SERVICE}.service /etc/systemd/system/

#mkdir as user uid:1000 in case it does not exist
[[ ! -d $varHome/${USER_FOLDER}/docker/${DOCKER_SERVICE} ]] && \
    echo -e $ye"\tservice folder not existing ... creating folder"$def && \
    sudo -u \#1000 mkdir -p $varHome/${USER_FOLDER}/docker/${DOCKER_SERVICE}/service

#link 'service' folder from user to service
ln -s $varHome/${USER_FOLDER}/docker/${DOCKER_SERVICE}/service ${DOCKER_BASE}/${DOCKER_SERVICE}/service

#create .env if not existing
[[ ! -f $varHome/${USER_FOLDER}/docker/${DOCKER_SERVICE}/.env ]] && \
    sudo -u \#1000 cat > $varHome/${USER_FOLDER}/docker/${DOCKER_SERVICE}/.env <<EOF
PGID=1000
PUID=1000
TZ=CET-1CEST,M3.5.0/2,M10.5.0/3  
EOF

#link .env file from user
ln -s $varHome/${USER_FOLDER}/docker/${DOCKER_SERVICE}/.env ${DOCKER_BASE}/${DOCKER_SERVICE}/.env

#reload daemons enable service and start service
systemctl daemon-reload && systemctl enable ${DOCKER_SERVICE} && systemctl start ${DOCKER_SERVICE}
