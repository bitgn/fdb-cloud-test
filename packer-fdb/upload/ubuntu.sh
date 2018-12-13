#!/bin/bash
set -e
set -x

# from http://unix.stackexchange.com/a/28793
# if we aren't root - elevate. This is useful for AMI
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

export DEBIAN_FRONTEND=noninteractive

# set timezone to UTC
dpkg-reconfigure tzdata

# https://groups.google.com/forum/#!msg/foundationdb-user/BtJf-1Mlx4I/fxXZClLpnOUJ
# sources: https://github.com/ripple/docker-fdb-server/blob/master/Dockerfile
# https://hub.docker.com/r/arypurnomoz/fdb-server/~/dockerfile/

# linux-aws - https://forums.aws.amazon.com/thread.jspa?messageID=769521&tstart=0

# need to clean since images could have stale metadata
apt-get clean && apt-get update
apt-get install -y -qq build-essential python linux-aws sysstat iftop htop iotop ne

# install fdbtop
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
apt-get install -y -qq nodejs
npm install -g fdbtop

######### FDB

cd /tmp

# download the dependencies
wget https://www.foundationdb.org/downloads/6.0.15/ubuntu/installers/foundationdb-clients_6.0.15-1_amd64.deb
wget https://www.foundationdb.org/downloads/6.0.15/ubuntu/installers/foundationdb-server_6.0.15-1_amd64.deb

# server depends on the client packages
dpkg -i foundationdb-clients_6.0.15-1_amd64.deb foundationdb-server_6.0.15-1_amd64.deb
# stop the service
service foundationdb stop

# add default user to foundationdb group
sudo usermod -a -G foundationdb ubuntu

# ensure correct permissions
chown -R foundationdb:foundationdb /etc/foundationdb
chmod -R ug+w /etc/foundationdb

######### Cleanup

apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
