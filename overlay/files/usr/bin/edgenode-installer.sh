#!/bin/sh

# Find the first disk in the system
device="/dev/$(lsblk --json | jq -r '[.blockdevices[] | select(.type == "disk") | .name][0]')"

/usr/bin/elemental install $device && eject && reboot