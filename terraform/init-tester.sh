#!/bin/bash
set -e

FDB_TYPE=$1
FDB_COUNT=$2
SELF_IP=$3
SEED_IP=$4
TESTER_TYPE=$5


echo "./init-tester.sh $@"

# resolve IP address as host name
echo "$SELF_IP $(hostname)" >> /etc/hosts

# make 1st node the coordinator
echo "Drtu0T4S:i8uQIB9r@$SEED_IP:4500" > /etc/foundationdb/fdb.cluster

# make sure the cluster file is writeable by everybody
chmod ugo+w /etc/foundationdb/fdb.cluster

# print cluster info for the benchmarking purposes
echo "fdb_type: $FDB_TYPE" >> /etc/cluster
echo "fdb_count: $FDB_COUNT" >> /etc/cluster
echo "tester_type: $TESTER_TYPE" >> /etc/cluster

# make cluster info readable by anybody
chmod ugo+r /etc/cluster