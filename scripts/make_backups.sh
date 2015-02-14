#!/bin/bash
set -e

# Use this directory as the root.
cd $(dirname $0)
ROOTDIR=$(pwd)

# Define our rsync command with basic options.
RSYNC="rsync -aAX"

# Rotate the backups.
mv backup.{1,2}
mv backup.{0,1}
mkdir backup.0

# Create temporary storage for snapshots.
THINPOOL_DEV=$(losetup --show -f thinpool.disk)
pvcreate $THINPOOL_DEV
vgextend fedora $THINPOOL_DEV

# Create the snapshots.
lvcreate -L 20G --snapshot --name rootsnap fedora/root
lvcreate -L 20G --snapshot --name homesnap fedora/home

# Backup root.
mount /dev/mapper/fedora-rootsnap vol
$RSYNC --link-dest=$ROOTDIR/backup.1/root vol/ backup.0/root
sync
umount vol
lvremove -f fedora/rootsnap

# Backup home.
mount /dev/mapper/fedora-homesnap vol
$RSYNC --link-dest=$ROOTDIR/backup.1/home vol/ backup.0/home
sync
umount vol
lvremove -f fedora/homesnap

# Remove the temporary snapshot storage.
vgreduce fedora $THINPOOL_DEV
pvremove $THINPOOL_DEV
losetup -d $THINPOOL_DEV

# On error:
# umount vol/
# lvremove fedora/rootsnap
# lvremove fedora/homesnap
# vgreduce fedora /dev/loop0
# pvremove /dev/loop0
# losetup -d /dev/loop0
# rm -rf backup.0/
# mv backup.{1,0}
