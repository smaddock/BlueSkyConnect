#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# This wrapper script is called by requiring it in /home/admin/.ssh/authorized_keys
# It prevents admin users from shelling directly into the server with their BlueSky creds
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

MY_CMD="/usr/bin/mysql --defaults-file=/var/local/my.cnf --default-character-set=utf8 BlueSky -N -B -e"

# grab things necessary for all phases
KEY_USED="TBD"
START_TIME=$(date "+%Y-%m-%d %H:%M:%S %Z")
SOURCE_IP=$(awk '/for admin from/ { match($0, /\y([0-9]{1,3}\.){3}[0-9]{1,3}\y/, a) } END { print a[0] }' /var/log/auth.log)
# TODO - use fingerprint from auth.log against authorized_keys to get description for $KEY_USED
# Nov 15 20:45:53 redsky sshd[2728]: Accepted publickey for admin from 38.98.37.19 port 62275 ssh2: ECDSA SHA256:Sahm5Rft8nvUQ5425YgrrSNGosZA4hf/P2NmhRr2NL0
# 256 SHA256:Sahm5Rft8nvUQ5425YgrrSNGosZA4hf/P2NmhRr2NL0 uploaded@1510761187 sysadmin@Sidekick.local (ECDSA)
# FINGER_PRINT=$(ssh-keygen -l -f /home/$targetLoc/newkeys/$tmpFile | awk '{ print $2 }' | cut -d : -f 2)

closeAudit() {
  # closes the previous MySQL record with an exit code and finish time
  # $1 should be exit code
  END_TIME=$(date "+%Y-%m-%d %H:%M:%S %Z")
  MY_QRY="UPDATE connections SET endTime = '$END_TIME', exitStatus = '$1' WHERE id = '$AUDIT_ID';"
  $MY_CMD "$MY_QRY"
}

writeAudit() {
  # creates a record in MySQL for tracking admin activity
  # $1 should be error description, if any
  MY_QRY="INSERT INTO connections (startTime, sourceIP, adminkey, targetPort, notes) VALUES ('$START_TIME', '$SOURCE_IP', '$KEY_USED', '$TARGET_PORT', '$1');"
  $MY_CMD "$MY_QRY"
  MY_QRY="SELECT id FROM connections WHERE startTime = '$START_TIME' AND adminkey = '$KEY_USED';"
  AUDIT_ID=$($MY_CMD "$MY_QRY")
}

# no command equals no access, punk
# could this just be -z $SSH_ORIGINAL_COMMAND ?
if [[ ${SSH_ORIGINAL_COMMAND:=UNSET} = "UNSET" ]]; then
  echo "Remote shell access is not permitted for BlueSky."
  writeAudit "Tried For Shell Access"
  closeAudit 127
  exit 127
fi

command="$SSH_ORIGINAL_COMMAND"
export command # why is this getting exported?
TARGET_PORT_RAW=$(awk 'NR == 1 { print $NF }' <<< "$SSH_ORIGINAL_COMMAND")
TARGET_PORT=$((TARGET_PORT_RAW - 22000))
TEST_CMD[1]="/bin/nc localhost 2...."
TEST_CMD[2]="/usr/bin/ssh localhost -p 2.*"

for THIS_CMD in "${TEST_CMD[@]}"; do
  if awk -v test="$THIS_CMD" '($0 !~ ^test$) || ($0 ~ [;&|]) { exit 1 }' <<< "$command"; then
    MATCH_CMD="false"
  else
    MATCH_CMD="true"
    break
  fi
done

if [[ $MATCH_CMD = "true" ]]; then
  writeAudit "Valid Connection"
  eval $command # is "eval" needed here?
  closeAudit $?
else
  echo "invalid command"
  writeAudit "Invalid Command"
  closeAudit 127
  exit 127
fi
