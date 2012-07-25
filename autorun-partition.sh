#!/bin/sh

# This script will partition the remaining space on a SD contaiting the A10 rescue image.
# An ext partition will be created using the maximum available as well as a fixed-size swap parition.

# Note: This script requires parted, which was not included in the 1.0 A10 Recovery System

# Uncomment this to write a log to /sysconfig/log on sucessful partitioning
#LOG_SUCCESS=1

# Target device
DEVICE=mmcblk0

# Set this if your device uses a partitioning prefix (p0, p1, etc)
PARTITION_PREFIX=p

# Swap partition size
SWAP_SIZE=64M

# Minimum drive size required
MIN_DRIVE_SIZE=100


echo "Attempting to create partitions on $DEVICE (swap $SWAP_SIZE)"

LINUX_START=32 # Start 32M in, leaving room for the 1MB embedded uBoot + 31MB sysconfig partition

DRIVE_UOM=`fdisk -l /dev/$DEVICE | grep "Disk /dev/$DEVICE:" | cut -d " " -f 4 | cut -d "," -f 1`
DRIVE_UNITS=`fdisk -l /dev/$DEVICE | grep "Disk /dev/$DEVICE:" | cut -d " " -f 3`

if [ "$DRIVE_UOM" = "MB" ]; then
  if [ $DRIVE_UNITS -lt $MIN_DRIVE_SIZE ]; then
    echo "ERROR: Device $DEVICE is too small: $DRIVE_UNITS $DRIVE_UOM"
    exit 1
  fi
fi

if [ "`fdisk -l /dev/$DEVICE | grep "/dev/$DEVICE$PARTITION_PREFIX[1]"`" = "" ]; then
  echo "ERROR: Device $DEVICE partition 1 missing! Are you sure you've flashed the 10 Rescue image?"
  exit 1
fi

if [ "`fdisk -l /dev/$DEVICE | grep "/dev/$DEVICE$PARTITION_PREFIX[2-9]"`" != "" ]; then
  echo "Device $DEVICE is already partitioned, exiting."
  exit 1
fi

# Create linux partition starting just after the first partition and leaving just enough room for the swap partition
parted -s /dev/$DEVICE "mkpart primary ext3 $LINUX_START -$SWAP_SIZE"
if [ "$?" -ne "0" ]; then
  echo "Error creating ext partition on $DEVICE, exiting."
  exit 1
fi

parted -s /dev/$DEVICE "mkpart primary linux-swap -$SWAP_SIZE -0"
if [ "$?" -ne "0" ]; then
  echo "Error creating $SWAP_SIZE swap partition on $DEVICE, exiting."
  exit 1
fi

if [ "$LOG_SUCCESS" = "1" ]; then
  mount -o remount,rw /mnt/sysconfig
  if [ ! -d /mnt/sysconfig/log ]; then
    mkdir /mnt/sysconfig/log
  fi
  date >> /mnt/sysconfig/log/autopartition.log
  echo "Successfully partitioned $DEVICE" >> /mnt/sysconfig/log/autopartition.log
  fdisk -l $DEVICE >> /mnt/sysconfig/log/autopartition.log
  mount -o remount,ro /mnt/sysconfig
fi

echo "Partitioning complete, rebooting to give kernel access to new partitions"
sleep 5
reboot
