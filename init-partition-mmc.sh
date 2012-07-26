#!/bin/sh

# This script will partition the remaining space on a SD contaiting the A10 rescue image.
# An ext partition will be created using the maximum available as well as a fixed-size swap parition.

# Note: This script requires parted, which was not included in the 1.0 A10 Recovery System

# Target device
DEVICE=mmcblk0

# Set this if your device uses a partitioning prefix (p0, p1, etc)
# mmc devices us prefix p (mmcblk0p1, mmcblk0p2, etc)
# sda devices do not use a prefix (sda1, sda2, etc)
PARTITION_PREFIX=p

# Swap partition size
SWAP_SIZE=128M

# Minimum drive size required
MIN_DRIVE_SIZE=500




LOG=/mnt/sysconfig/log/partition.log

log_exit()
{
  echo $1 | tee -a $LOG
  mount -o remount,ro /mnt/sysconfig
  exit 1
}


if [ ! -f /mnt/sysconfig/system.bin ]; then
  echo "system.bin has not yet been extracted, exiting"
  exit 1
fi

DRIVE_UOM=`fdisk -l /dev/$DEVICE | grep "Disk /dev/$DEVICE:" | cut -d " " -f 4 | cut -d "," -f 1`
DRIVE_UNITS=`fdisk -l /dev/$DEVICE | grep "Disk /dev/$DEVICE:" | cut -d " " -f 3`

if [ "`fdisk -l /dev/$DEVICE | grep "/dev/$DEVICE$PARTITION_PREFIX[2-9]"`" != "" ]; then
  echo "Device $DEVICE is already partitioned."
  exit
fi

if [ "`fdisk -l /dev/$DEVICE | grep "/dev/$DEVICE$PARTITION_PREFIX[1]"`" = "" ]; then
  echo "ERROR: Device $DEVICE partition 1 missing! Are you sure you've flashed the 10 Rescue image?"
  exit
fi

mount -o remount,rw /mnt/sysconfig
if [ ! -d /mnt/sysconfig/log ]; then
  mkdir /mnt/sysconfig/log
fi

date > $LOG

if [ "$DRIVE_UOM" = "MB" ]; then
  if [ $DRIVE_UNITS -lt $MIN_DRIVE_SIZE ]; then
    log_exit "ERROR: Device $DEVICE is too small: $DRIVE_UNITS $DRIVE_UOM"
  fi
fi

START_SECTOR=`fdisk -l /dev/$DEVICE | grep $DEVICE${PARTITION_PREFIX}1 | awk '{ print \$3+1"s" }'`

# Create linux partition starting just after the first partition and leaving just enough room for the swap partition
parted -s /dev/$DEVICE -a opt -- mkpart primary ext3 $START_SECTOR -$SWAP_SIZE | tee -a $LOG
if [ "$?" -ne "0" ]; then
  log_exit "Error creating ext partition on $DEVICE, exiting."
fi

parted -s /dev/$DEVICE -a opt -- mkpart primary linux-swap -$SWAP_SIZE -0 | tee -a $LOG
if [ "$?" -ne "0" ]; then
  log_exit "Error creating $SWAP_SIZE swap partition on $DEVICE, exiting."
fi

echo "Successfully partitioned $DEVICE" | tee -a $LOG
fdisk -l /dev/$DEVICE >> /mnt/sysconfig/log/autopartition.log >> $LOG
mount -o remount,ro /mnt/sysconfig

partprobe
