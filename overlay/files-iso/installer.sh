#!/bin/sh

# Find the first disk in the system
device=$(lsblk --json | jq -r '[.blockdevices[] | select(.type == "disk") | .name][0]')

/usr/bin/elemental install --eject-cd --reboot $device