#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# find SSH keys from temp app and purge them if too old
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

TEMP_LIST=$(awk -F "-" '/tmp-/ { print $NF }' /home/bluesky/.ssh/authorized_keys)
if [[ $TEMP_LIST ]]; then
  MY_EPOCH=$(date +%s)
  EXPIR_EPOCH=$((MY_EPOCH - 14400))
  for THIS_LINE in $TEMP_LIST; do
    if [[ $THIS_LINE -lt $EXPIR_EPOCH ]]; then
      sed -i "/$THIS_LINE/d" /home/bluesky/.ssh/authorized_keys
    fi
  done
fi
exit 0
