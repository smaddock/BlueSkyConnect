#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# called by inoticoming when a good public key is copied to /home/*/newkeys by the keymaster
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

TMP_FILE="$1"

FILE_LOC=$(ls "/home/admin/newkeys/$1" 2> /dev/null)

if [[ $FILE_LOC ]]; then
  TARGET_LOC="admin"
  PREFIX_CODE="command=\"/usr/local/bin/BlueSkyConnect/Server/$TARGET_LOC-wrapper.sh\""
else
  TARGET_LOC="bluesky"
  PREFIX_CODE="command=\"/usr/local/bin/BlueSkyConnect/Server/$TARGET_LOC-wrapper.sh\",no-X11-forwarding,no-agent-forwarding,no-pty"
fi

PUB_KEY=$(< "/home/$TARGET_LOC/newkeys/$TMP_FILE")
SERIAL_NUM=$(awk '{ print $NF }' <<< "$PUB_KEY")
# 256 SHA256:Sahm5Rft8nvUQ5425YgrrSNGosZA4hf/P2NmhRr2NL0 uploaded@1510761187 sysadmin@Sidekick.local (ECDSA)
# FINGER_PRINT=$(ssh-keygen -l -f /home/$TARGET_LOC/newkeys/$TMP_FILE | awk '{ print $2 }' | cut -d : -f 2)

# remove previous keys with same serial
if [[ $SERIAL_NUM ]]; then
  sed -i "/$SERIAL_NUM/d" /home/$TARGET_LOC/.ssh/authorized_keys
fi
# install it
echo "$PREFIX_CODE $PUB_KEY" >> /home/$TARGET_LOC/.ssh/authorized_keys

rm -f "/home/$TARGET_LOC/newkeys/$TMP_FILE"

# add to admin keys table
if [[ $TARGET_LOC = "admin" ]]; then
  ADMIN_KEYS=$(awk '{ print $NF }' /home/admin/.ssh/authorized_keys)
  MY_CMD="/usr/bin/mysql --defaults-file=/var/local/my.cnf BlueSky -N -B -e"
  MY_QRY="UPDATE global SET adminkeys = '$ADMIN_KEYS';"
  $MY_CMD "$MY_QRY"
fi

exit 0
