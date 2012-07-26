#!/bin/sh

# This script will dump diagnostic information to /sysconfig/log/deviceinfo.log

LOG=/mnt/sysconfig/log/deviceinfo.log

if [ -f $LOG ]; then
  echo "$LOG already exists, exiting"
  exit
fi

mount -o remount,rw /mnt/sysconfig
if [ ! -d /mnt/sysconfig/log ]; then
  mkdir /mnt/sysconfig/log
fi

date > $LOG
echo "================== /proc/partitions =================" >> $LOG
cat /proc/partitions >> $LOG
echo "" >> $LOG

echo "================== /proc/devices =================" >> $LOG
cat /proc/devices >> $LOG
echo "" >> $LOG

mkdir /tmp/nand
for dev in nanda
do
  echo "================== $dev =================" >> $LOG
  mount /dev/$dev /tmp/nand
  cd /tmp/nand
  find >> $LOG
  cd /
  umount /tmp/nand
  echo "" >> $LOG
done

echo "================== /nandh strings =================" >> $LOG
dd if=/dev/nandh of=/tmp/env bs=1024 count=128
strings /tmp/env >> $LOG
echo "" >> $LOG

echo "================== ifconfig =================" >> $LOG
ifconfig >> $LOG
echo "" >> $LOG

echo "================== dmesg =================" >> $LOG
dmesg >> $LOG
echo "" >> $LOG

mount -o remount,rw /mnt/sysconfig
