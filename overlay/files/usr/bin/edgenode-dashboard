#!/bin/bash

export TEMPFILE=$(mktemp)

while true
do
  echo "" > $TEMPFILE;
  cat /etc/issue | sed 's@\\r@'"$(uname -r)"'@g' | sed 's@\\m@'"$(uname -m)"'@g' | sed 's@\\l@'"$(tty)"'@g' | sed 's@\\n@'"$(hostname)"'@g' >> $TEMPFILE;
  tailscale status >> $TEMPFILE;
  authurl=$(tailscale status --json | jq -r '.AuthURL');
  if [ "$authurl" != "" ]; then
    echo $authurl | qrencode -t ANSIUTF8i >> $TEMPFILE;
  fi;
  date >> $TEMPFILE;
  
  clear;
  cat $TEMPFILE;
  sleep 5;
done