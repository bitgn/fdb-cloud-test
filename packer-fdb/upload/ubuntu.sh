#!/bin/bash
set -e

# Let's build FDB cluster machine


# from http://unix.stackexchange.com/a/28793
# if we aren't root - elevate. This is useful for AMI
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi


# https://groups.google.com/forum/#!msg/foundationdb-user/BtJf-1Mlx4I/fxXZClLpnOUJ
# sources: https://github.com/ripple/docker-fdb-server/blob/master/Dockerfile
# https://hub.docker.com/r/arypurnomoz/fdb-server/~/dockerfile/


export DEBIAN_FRONTEND=noninteractive
apt-get clean && apt-get update
apt-get install -y -qq python lsb wget

# fix policies (applies to docker)
mv policy-rc.d /usr/sbin

cd /tmp

#download the dependencies
wget https://www.foundationdb.org/downloads/5.1.7/ubuntu/installers/foundationdb-clients_5.1.7-1_amd64.deb
wget https://www.foundationdb.org/downloads/5.1.7/ubuntu/installers/foundationdb-server_5.1.7-1_amd64.deb

#server depends on the client packages
dpkg -i foundationdb-clients_5.1.7-1_amd64.deb
dpkg -i  foundationdb-server_5.1.7-1_amd64.deb

# stop the service
service foundationdb stop

#chown -R foundationdb:foundationdb /etc/foundationdb

# stop the service
service foundationdb stop

# peeked from here
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
