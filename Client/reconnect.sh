#!/bin/bash

# script that reloads bluesky upon network event in hopes of faster reconnection

ourHome="/var/bluesky"

if [ -e "$ourHome/.debug" ]; then
  set -x
fi

function logMe {
  logMsg="$1"
  logFile="$ourHome/reconnect.txt"
  if [ ! -e "$logFile" ]; then
    touch "$logFile"
  fi
  dateStamp=`date '+%Y-%m-%d %H:%M:%S'`
  echo "$dateStamp - $logMsg" >> "$logFile"
  if [ -e "$ourHome/.debug" ]; then
    echo "$logMsg"
  fi
}

#logMe "Network change detected, waiting..."
#sleep 5
logMe "Reloading bluesky service..."
launchctl unload /Library/LaunchDaemons/com.solarwindsmsp.bluesky.plist
launchctl load -w /Library/LaunchDaemons/com.solarwindsmsp.bluesky.plist

exit 0
