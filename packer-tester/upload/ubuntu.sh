#!/bin/bash
set -e

# from http://unix.stackexchange.com/a/28793
# if we aren't root - elevate. This is useful for AMI
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

export DEBIAN_FRONTEND=noninteractive


# set timezone to UTC
dpkg-reconfigure tzdata

# need to clean since images could have stale metadata
apt-get clean && apt-get update
apt-get -qq -y install build-essential libssl-dev git python curl wget htop screen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


########## Java Runtime
# from here https://github.com/OpenTreeOfLife/germinator/wiki/Debian-upgrade-notes:-jessie-and-openjdk-8
# add jessie backports
# echo "deb http://http.debian.net/debian jessie-backports main" | tee -a /etc/apt/sources.list
# apt-get update
# apt-get -qq -y install openjdk-8-jre-headless && apt-get clean && rm -rf /var/lib/apt/lists/*

######### FDB

cd /tmp

wget https://www.foundationdb.org/downloads/5.1.7/ubuntu/installers/foundationdb-clients_5.1.7-1_amd64.deb
dpkg -i foundationdb-clients_5.1.7-1_amd64.deb

# create the folder if it doesn't exist
mkdir -p /etc/foundationdb

# make the directory and the cluster file writeable
chmod 777 /etc/foundationdb

# write empty cluster file and setup permissions on it
touch /etc/foundationdb/fdb.cluster
chmod 666 /etc/foundationdb/fdb.cluster


# cleanup
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
