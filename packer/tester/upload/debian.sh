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


######### MONO
# Mono Project GPG signing key
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

# required for Debian
echo "deb http://download.mono-project.com/repo/debian wheezy main" | tee /etc/apt/sources.list.d/mono-xamarin.list
echo "deb http://download.mono-project.com/repo/debian wheezy-apache24-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list
echo "deb http://download.mono-project.com/repo/debian wheezy-libjpeg62-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list

apt-get update

# grabbed from here: https://genielabs.github.io/HomeGenie/install.html
apt-get install -qq -y mono-runtime libmono-corlib2.0-cil libmono-system-web4.0-cil \
    libmono-system-numerics4.0-cil libmono-system-serviceprocess4.0-cil \
    libmono-system-data4.0-cil libmono-system-core4.0-cil libmono-system-servicemodel4.0a-cil \
    libmono-windowsbase4.0-cil libmono-system-runtime-serialization-formatters-soap4.0-cil \
    libmono-system-runtime-serialization4.0-cil libmono-system-xml-linq4.0-cil mono-dmcs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

########## Java Runtime
# from here https://github.com/OpenTreeOfLife/germinator/wiki/Debian-upgrade-notes:-jessie-and-openjdk-8
# add jessie backports
echo "deb http://http.debian.net/debian jessie-backports main" | tee -a /etc/apt/sources.list
apt-get update
apt-get -qq -y install openjdk-8-jre-headless && apt-get clean && rm -rf /var/lib/apt/lists/*

######### FDB

# foundationdb clients
dpkg -i foundationdb-clients_3.0.7-1_amd64.deb

# create the folder if it doesn't exist
mkdir -p /etc/foundationdb

# make the directory and the cluster file writeable
chmod 777 /etc/foundationdb

# write empty cluster file and setup permissions on it
touch /etc/foundationdb/fdb.cluster
chmod 666 /etc/foundationdb/fdb.cluster

########## wrk2
git clone https://github.com/giltene/wrk2.git
cd wrk2
make
cp wrk /usr/local/bin
cd ..


# cleanup
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
