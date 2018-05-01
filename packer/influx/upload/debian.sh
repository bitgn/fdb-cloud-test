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
apt-get -qq -y python curl wget htop \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# We recommend using two SSD volumes. One for the influxdb/wal and one for the influxdb/data.
# Depending on your load each volume should have around 1k-3k provisioned IOPS.
# The influxdb/data volume should have more disk space with lower IOPS and the influxdb/wal
# volume should have less disk space with higher IOPS.
# wget https://dl.influxdata.com/influxdb/releases/influxdb_0.13.0_amd64.deb
dpkg -i influxdb_0.13.0_amd64.deb


# install grafana
# wget https://grafanarel.s3.amazonaws.com/builds/grafana_3.1.1-1470047149_amd64.deb
apt-get install -y adduser libfontconfig
dpkg -i grafana_3.1.1-1470047149_amd64.deb
# enable grafana to launch on boot
systemctl enable grafana-server.service


# cleanup
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
