#!/bin/sh
echo "--reset"
echo "--ssh"
echo "--accept-dns"
echo "--accept-routes"
if [ -d /sys/devices/virtual/net/cni0 ];
then
  echo "--advertise-routes $(ip route | grep src | grep cni0 | awk '{print $1}'),10.43.0.0/16"
fi
if [ -f /boot/firmware/tailscale-authkey ];
then
  echo "--auth-key file:/boot/firmware/tailscale-authkey"
else
  echo "--qr"
fi