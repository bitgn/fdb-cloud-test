#!/bin/bash
set -e

VM_TYPE=$1
VM_COUNT=$2
SELF_IP=$3
SEED_IP=$4


echo "./init-fdb.sh $@"

# avoid confusing FoundationDB
service foundationdb stop

# resolve IP address as host name
echo "$SELF_IP $(hostname)" >> /etc/hosts

# wipe the data from the image
rm -rf /var/lib/foundationdb/data/4500/

# make 1st node the coordinator
echo "Drtu0T4S:i8uQIB9r@$SEED_IP:4500" > /etc/foundationdb/fdb.cluster

# make sure the cluster file is writeable by everybody
chmod ugo+w /etc/foundationdb/fdb.cluster


# NVME disks aren't formatted. Mounting them in fstab - no good
# mounting NVME disk: https://stackoverflow.com/questions/45167717/mounting-a-nvme-disk-on-aws-ec2


case $VM_TYPE in
"m3.large" | "m3.medium" )
    echo use local instance store
    mount /dev/xvdb /var/lib/foundationdb
    echo /dev/xvdb  /var/lib/foundationdb ext3 defaults,nofail 0 2 >> /etc/fstab
    mkdir -p /var/lib/foundationdb/data
    chown -R foundationdb:foundationdb /var/lib/foundationdb
    ;;
"i3.large" )
    echo SSD optimized
    mkfs.ext4 -E nodiscard /dev/nvme0n1
    mount /dev/nvme0n1 /var/lib/foundationdb
    mkdir -p /var/lib/foundationdb/data
    chown -R foundationdb:foundationdb /var/lib/foundationdb
    ;;
esac



if [ "$SELF_IP" == "$SEED_IP" ]; then
    echo "Seed setup"
    service foundationdb start
    sleep 60
    fdbcli --exec "configure new ssd double" --timeout 60
    fdbcli --exec "coordinators auto; status" --timeout 60
else
    echo "Follower setup"
    # start the service
    service foundationdb start
fi