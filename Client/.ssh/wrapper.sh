#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# This script ensures that all incoming SSH connections originated by the
# server are only allowed to read the expected serial number from the generated
# hash in settings.plist
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

# could this just be -z $SSH_ORIGINAL_COMMAND ?
if [[ ${SSH_ORIGINAL_COMMAND:=UNSET} = "UNSET" ]]; then
  echo "Remote shell access is not permitted for BlueSky."
  exit 127
fi

command="$SSH_ORIGINAL_COMMAND"
export command # why is this getting exported?
TEST_CMD[1]="/usr/bin/defaults read /var/bluesky/settings serial"
TEST_CMD[2]="/usr/libexec/PlistBuddy -c 'Print serial' /var/bluesky/settings.plist"

for THIS_CMD in "${TEST_CMD[@]}"; do
  if [[ $command = "$THIS_CMD" ]]; then
    MATCH_CMD="true"
    break
  else
    MATCH_CMD="false"
  fi
done

if [[ $MATCH_CMD = "true" ]]; then
  eval $command # is "eval" needed here?
else
  echo "invalid command"
  exit 127
fi
