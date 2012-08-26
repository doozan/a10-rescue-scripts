#!/bin/sh

if [ ! -f /mnt/sysconfig/system.bin ]; then
  echo "Could not find /system.bin on sysconfig partition"
  echo "Searching NAND for usable system.bin files..."

  mkdir /tmp/nand
  mount /dev/nanda /tmp/nand

  if [ -f /tmp/nand/script.bin ]; then
    # Decompile script.bin
    /sbin/fexc -I bin -O fex /tmp/nand/script.bin /tmp/system.fex

    # Attempt to extract the MAC address from known locations for uboot uboot environments
    dd if=/dev/nandb of=/tmp/env bs=1024 count=128
    MAC=`strings /tmp/env | grep "^mac=" | cut -d "=" -f 2 | sed -e 's/://g'`

    if [ ! $MAC ]; then
      dd if=/dev/nandh of=/tmp/env bs=1024 count=128
      MAC=`strings /tmp/env | grep "^mac=" | cut -d "=" -f 2 | sed -e 's/://g'`
    fi

    # If we've found a MAC address, use it
    if [ ! $MAC ]; then
      sed -i -e"s/^MAC = \"000000000000\"/MAC = \"$MAC\"/" /tmp/system.fex
    fi

    # save system.bin on sysconfig
    mount -o remount,rw /mnt/sysconfig
    /sbin/fexc -I fex -O bin /tmp/system.fex /mnt/sysconfig/system.bin
    mount -o remount,ro /mnt/sysconfig

    umount /tmp/nand
    echo "Created system.bin from nanda/script.bin, MAC Address = $MAC"
    echo "Rebooting system to use new system.bin"
    sleep 5
    reboot
  else
    echo "Could not find /script.bin on nanda"
  fi
else
  echo "/mnt/sysconfig/system.bin already installed, exiting"
fi
