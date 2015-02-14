==============
Backup Scripts
==============

My rsync backup scripts.

My currently used script is `scripts/make_backups.sh`. This script:

- Makes incremental backups using rsync.

- Adds temporary storage for LVM snapshots using a loopback device in the
  backup location.
