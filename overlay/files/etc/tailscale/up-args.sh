#!/bin/sh
echo "--reset"
echo "--ssh"
# if !(netstat -tnap | grep ":53" > /dev/null)
# then
#   echo "--accept-dns"
# else
#   echo "--accept-dns=false"
# fi
echo "--accept-dns"
echo "--accept-routes"
if [ -d /sys/devices/virtual/net/cni0 ];
then
  echo "--advertise-routes $(ip route | grep src | grep cni0 | awk '{print $1}'),10.43.0.0/16"
fi
if [ -f /oem/tailscale-authkey ];
then
  echo "--auth-key file:/oem/tailscale-authkey"
else
  echo "--qr"
fi