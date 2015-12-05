#!/bin/bash
set -e

# Use this directory as the root.
cd $(dirname $0)
ROOTDIR=$(pwd)

# Define our rsync command with basic options.
RSYNC="rsync -aAX"

# Ensure backup directories exist
mkdir -p backup.{1..0}/{root,boot,home}
mkdir -p backup.new
mkdir -p vol

# Ensure file backing for temporary storage exists.
if [ ! -f snapshot.disk ]
then
    truncate -s 40G snapshot.disk
fi

# Create temporary storage for snapshots.
LOOP_DEV=$(losetup --show -f snapshot.disk)
pvcreate $LOOP_DEV
vgextend fedora $LOOP_DEV

# Create the snapshots.
lvcreate -L 20G --snapshot --name rootsnap fedora/root
lvcreate -L 20G --snapshot --name homesnap fedora/home

# Backup boot (not an lvm volume)
$RSYNC --link-dest=$ROOTDIR/backup.0/boot /boot/ backup.new/boot

# Backup root.
mount /dev/mapper/fedora-rootsnap vol
$RSYNC --link-dest=$ROOTDIR/backup.0/root vol/ backup.new/root
sync
umount vol
lvremove -f fedora/rootsnap

# Backup home.
mount /dev/mapper/fedora-homesnap vol
$RSYNC --link-dest=$ROOTDIR/backup.0/home vol/ backup.new/home
sync
umount vol
lvremove -f fedora/homesnap

# Remove the temporary snapshot storage.
vgreduce fedora $LOOP_DEV
pvremove $LOOP_DEV
losetup -d $LOOP_DEV

sync

# Rotate the backups.
mv backup.{1,old}
mv backup.{0,1}
mv backup.{new,0}

# Remove oldest backup
rm -rf backup.old

# On error:
# umount vol/
# lvremove fedora/rootsnap
# lvremove fedora/homesnap
# vgreduce fedora /dev/loop0
# pvremove /dev/loop0
# losetup -d /dev/loop0
# rm -rf backup.0/
# mv backup.{1,0}
