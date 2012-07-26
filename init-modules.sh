#!/bin/sh

if [ ! -f /mnt/sysconfig/system.bin ]; then
  echo "system.bin has not yet been extracted, exiting"
  exit 1
fi

WIRED=`fexc -I bin -O fex /mnt/sysconfig/system.bin | grep emac_used | cut -d " " -f 3`

if [ $WIRED = 1 ]; then
  echo "Loading wired ethernet module"
  modprobe sun4i_wemac
fi

echo "Loading wireless module"
modprobe 8192cu
