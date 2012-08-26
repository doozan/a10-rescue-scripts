#!/bin/sh

if [ ! -f /mnt/sysconfig/system.bin ]; then
  echo "system.bin has not yet been extracted, exiting"
  exit 1
fi

# Options for overriding the default output display

# VGA
#/sbin/a10_display vga mode 2

# TV
#/sbin/a10_display tv mode 0
