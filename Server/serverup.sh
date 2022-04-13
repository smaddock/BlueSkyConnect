#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# This script handles the sending of down or up alerts for computers marked with the Alert checkbox
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

sendAlert() {
  MY_QRY="SELECT hostname FROM computers WHERE serialnum = '$SERIAL_NUM';"
  HOST_NAME=$($MY_CMD "$MY_QRY")

  LAST_DATE=$(date -d @"$LAST_CONN" "+%Y-%m-%d %H:%M:%S %Z")

  ALERT_STAT="$1"
  if [[ $ALERT_STAT = "Down" ]]; then
    MESS_BODY="You requested to be notified when $HOST_NAME with serial number $SERIAL_NUM has been offline for more than 15 minutes. Last time we saw it was $LAST_DATE"
  elif [[ $ALERT_STAT = "Up" ]]; then
    MESS_BODY="The computer $HOST_NAME with serial number $SERIAL_NUM is now back online."
  else
    return
  fi

  if [[ -x /usr/local/bin/BlueSkyConnect/Server/emailHelper.sh ]]; then
    /usr/local/bin/BlueSkyConnect/Server/emailHelper.sh "BlueSky $ALERT_STAT Alert $SERIAL_NUM" "$MESS_BODY"
  fi
}

MY_CMD="/usr/bin/mysql --defaults-file=/var/local/my.cnf BlueSky -N -B -e"

MY_QRY="SELECT serialnum FROM computers WHERE alert = '1';"
ALERT_LIST=$($MY_CMD "$MY_QRY")

for SERIAL_NUM in $ALERT_LIST; do

  MY_QRY="SELECT downup FROM computers WHERE serialnum = '$SERIAL_NUM';"
  FIRST_STAT=$($MY_CMD "$MY_QRY")
  if [[ -z $FIRST_STAT ]] || [[ $FIRST_STAT = "NULL" ]]; then
    FIRST_STAT=1
  fi
  # 1 is up, <=0 is down, negative number is how many times this script has seen it as down

  # timestamp is an epoch populated by processor when it confirms a good connection
  MY_QRY="SELECT timestamp FROM computers WHERE serialnum = '$SERIAL_NUM';"
  LAST_CONN=$($MY_CMD "$MY_QRY")
  if [[ -z $LAST_CONN ]] || [[ $LAST_CONN = "NULL" ]]; then
    LAST_CONN=0
  fi

  CHECK_THRESH=$(date -d "10 minutes ago" "+%s")

  if [[ ${LAST_CONN:-0} -lt $CHECK_THRESH ]]; then
    # it’s been quiet for more than 10 min, might be down
    # first do our own spot check to see if server is really down
    MY_QRY="SELECT blueskyid FROM computers WHERE serialnum = '$SERIAL_NUM';"
    MY_PORT=$($MY_CMD "$MY_QRY")
    SSH_PORT=$((22000 + MY_PORT))
    if ! ssh \
      -i /usr/local/bin/BlueSkyConnect/Server/blueskyd \
      -l bluesky \
      -o ConnectionAttempts=5 \
      -o ConnectTimeout=5 \
      -o StrictHostKeyChecking=no \
      -p $SSH_PORT \
      localhost \
      "/usr/bin/defaults read /var/bluesky/settings serial"; then
      # we did not connect, mark down the counter
      ((FIRST_STAT--))
      MY_QRY="UPDATE computers SET downup = '$FIRST_STAT' WHERE serialnum = '$SERIAL_NUM';"
      $MY_CMD "$MY_QRY"
      if [[ $FIRST_STAT -eq -2 ]]; then
        # this is the third time we have seen it as down - up to 10 min on checkin, 3 times with this script every 5 (0, -1, -2), time to alert
        sendAlert Down
        TIME_STAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
        MY_QRY="UPDATE computers SET status = 'Alert sent for offline', datetime = '$TIME_STAMP' WHERE serialnum = '$SERIAL_NUM';"
        $MY_CMD "$MY_QRY"
      fi
      # TODO - send an extended down at larger interval?
    fi
  else
    # server was last contacted in acceptable threshold
    if [[ $FIRST_STAT -lt 1 ]]; then
      # server was down last time, mark up
      MY_QRY="UPDATE computers SET downup = '1' WHERE serialnum = '$SERIAL_NUM';"
      $MY_CMD "$MY_QRY"
      if [[ $FIRST_STAT -lt -1 ]]; then
        # down alert has been sent, follow up
        sendAlert Up
        TIME_STAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
        MY_QRY="UPDATE computers SET status = 'Recovered from alert', datetime = '$TIME_STAMP' WHERE serialnum = '$SERIAL_NUM';"
        $MY_CMD "$MY_QRY"
      fi
    fi
  fi

done

# look for disconnected computers and mark offline
MY_QRY="SELECT id FROM computers WHERE datetime < (NOW() - INTERVAL 12 MINUTE) AND status = 'Connection is good';"
OFFLINE_LIST=$($MY_CMD "$MY_QRY")
for THIS_ID in $OFFLINE_LIST; do
  TIME_STAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
  MY_QRY="UPDATE computers SET status = 'Offline', datetime = '$TIME_STAMP' WHERE id = '$THIS_ID';"
  $MY_CMD "$MY_QRY"
done

exit 0
