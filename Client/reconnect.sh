#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# script that reloads BlueSky upon network event in hopes of faster reconnection
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

OUR_HOME="/var/bluesky"

if [[ -f "$OUR_HOME/.debug" ]]; then
  set -x
fi

logMe() {
  LOG_MSG="$1"
  LOG_FILE="$OUR_HOME/reconnect.txt"
  if [[ ! -e $LOG_FILE ]]; then
    touch "$LOG_FILE"
  fi
  DATE_STAMP=$(date "+%Y-%m-%d %H:%M:%S")
  echo "$DATE_STAMP - $LOG_MSG" >> "$LOG_FILE"
  if [[ -f "$OUR_HOME/.debug" ]]; then
    echo "$LOG_MSG"
  fi
}

if [[ $1 = "wake" ]]; then
  logMe "System wake detected, Reloading bluesky service..."
else
  logMe "Network state change detected, Reloading bluesky service..."
fi
sleep 3
launchctl unload /Library/LaunchDaemons/com.solarwindsmsp.bluesky.plist
launchctl load -w /Library/LaunchDaemons/com.solarwindsmsp.bluesky.plist

exit 0
