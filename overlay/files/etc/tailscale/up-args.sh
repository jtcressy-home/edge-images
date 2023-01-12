#!/bin/sh
TAGS=""
ROUTES=""
echo "--reset"
echo "--ssh"

# if !(netstat -tnap | grep ":53" > /dev/null)
# then
#   echo "--accept-dns"
# else
#   echo "--accept-dns=false"
# fi
echo "--accept-dns=false" # prevent collisions with local coredns

if (netstat -tna | grep ":6443" 2>&1 > /dev/null)
then # we're a kubernetes server!
  TAGS="${TAGS},tag:dnslb-kubernetes"
fi

echo "--accept-routes=true"

if [ -d /sys/devices/virtual/net/cni0 ];
then # we're a kubernetes node with configured CNI!
  # advertise the pod network route for the node (usually a dynamically assigned /24)
  ROUTES="${ROUTES},$(ip route | grep src | grep cni0 | awk '{print $1}')"
  # also advertise the default service IP range
  ROUTES="${ROUTES},10.43.0.0/16"
fi

echo "--advertise-routes='${ROUTES}'"
echo "--advertise-tags='${TAGS}'"
if [ -f /oem/tailscale-authkey ];
then
  echo "--auth-key file:/oem/tailscale-authkey"
else
  echo "--json"
fi