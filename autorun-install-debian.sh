#!/bin/sh

# This script will install debian on mmcblk0p2

LOG=/mnt/sysconfig/log/debian.log
INSTALLER=http://projects.doozan.com/debian/sun4i.debian-wheezy.sh

log_exit()
{
  echo $1 | tee -a $LOG
  mount -o remount,ro /mnt/sysconfig
  exit 1
}

mount -o remount,rw /mnt/sysconfig
if [ ! -d /mnt/sysconfig/log ]; then
  mkdir /mnt/sysconfig/log 
fi

date > $LOG

if [ ! -f /mnt/sysconfig/system.bin ]; then
  log_exit "system.bin has not yet been extracted, exiting"
fi

if [ "`fdisk -l /dev/mmcblk0 | grep /dev/mmcblk0p2`" = "" ]; then
  log_exit "ERROR: partition mmcblk0p2 not found"
fi

mkdir /tmp/debian-filecheck
mount /dev/mmcblk0p2 /tmp/debian-filecheck
if [ "$?" = "0" ]; then
  # ls will error if there are no files in the directory
  ls /tmp/debian-filecheck/* > /dev/null
  RESULT=$?
  umount /tmp/debian-filecheck
  rmdir /tmp/debian-filecheck
  if [ "$RESULT" = "0" ]; then
    log_exit "Files exist on mmcblk0p2, cannot continue"
  fi
fi

cd /tmp
wget $INSTALLER -O /tmp/install-debian.sh
if [ "$?" -ne "0" ]; then
  log_exit "Could not download Debian installer"
fi
  
chmod +x install-debian.sh
set -o pipefail  # capture return status of command and not of tee

./install-debian.sh --noprompt | tee -a $LOG

if [ "$?" -ne "0" ]; then
 log_exit "Debian installation failed, check debootstrap.log for details"
fi
  
if [ -f  /mnt/debian/debootstrap/debootstrap.log ]; then
 cp /mnt/debian/debootstrap/debootstrap.log /mnt/sysconfig/log
 log_exit "Debian installation failed, check debootstrap.log for details"
fi

# Success
mount -o remount,ro /mnt/sysconfig

reboot
