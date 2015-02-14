#!/bin/sh

rsync --progress --delete --specials --exclude=/{mnt,proc,dev,sys,run,media,tmp} -HEXaq / /mnt/backup
