#!/bin/sh

# This script can be used to script any Debian post-installation config changes

ROOT=/tmp/debian

mount /dev/mmcblk0p2 $ROOT


# Example: configure custom hostname
# echo mysystem > $ROOT/etc/hostname


umount /tmp/debian
reboot
