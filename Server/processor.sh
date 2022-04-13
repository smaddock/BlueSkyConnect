#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# This script runs server-side, gets the data from collector.php,
# parses, writes to MySQL, and returns action step.
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

# grab the inputs
SERIAL_NUM="$1"
ACTION_STEP="$2"
HOST_NAME="$3"

# did we get everything?
if [[ -z $SERIAL_NUM ]] || [[ -z $ACTION_STEP ]]; then
  echo "ERROR: badinput"
  exit 1
fi

allGood() {
  echo "OK"
  MY_QRY="UPDATE computers SET status = 'Connection is good', datetime = '$TIME_STAMP' WHERE serialnum = '$SERIAL_NUM';"
  $MY_CMD "$MY_QRY"
  TIME_EPOCH=$(date +%s)
  MY_QRY="UPDATE computers SET timestamp = '$TIME_EPOCH' WHERE serialnum = '$SERIAL_NUM';"
  $MY_CMD "$MY_QRY"
}

snMismatch() {
  echo "Serial mismatch. Returned: $TEST_CONN"
  MY_QRY="UPDATE computers SET status = 'ERROR: serial mismatch returned $TEST_CONN', datetime = '$TIME_STAMP' WHERE serialnum = '$SERIAL_NUM';"
  $MY_CMD "$MY_QRY"
}

MY_CMD="/usr/bin/mysql --defaults-file=/var/local/my.cnf BlueSky -N -B -e"
TIME_STAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
LOGIN_FILE=/usr/local/bin/BlueSkyConnect/Server/defaultLogin.txt

case "$ACTION_STEP" in

  "register")
    # adds the computer to the database
    MY_QRY="SELECT id FROM computers WHERE serialnum = '$SERIAL_NUM';"
    COMP_REC=$($MY_CMD "$MY_QRY")

    # get the default bluesky user name
    if [[ -s $LOGIN_FILE ]]; then
      LOGIN_NAME=$(< "$LOGIN_FILE")
    fi

    if [[ -z $COMP_REC ]]; then

      # fetch unique ID
      MY_QRY="SELECT MIN(t1.blueskyid + 1) AS nextID FROM computers t1 LEFT JOIN computers t2 ON t1.blueskyid + 1 = t2.blueskyid WHERE t2.blueskyid IS NULL;"
      BLU_ID=$($MY_CMD "$MY_QRY")

      if [[ -z $BLU_ID ]] || [[ $BLU_ID = "NULL" ]]; then
        BLU_ID=1
      fi

      # safety check
      if [[ ${BLU_ID:-0} -gt 1949 ]]; then
        echo "ERROR: maximum limit reached"
        exit 1
      fi
      # set insert
      MY_QRY="INSERT INTO computers (serialnum, hostname, sharingname, registered, blueskyid, username) VALUES ('$SERIAL_NUM', '$HOST_NAME', '$HOST_NAME', '$TIME_STAMP', '$BLU_ID', '$LOGIN_NAME');"
    else
      # if we have a default user name, and if the existing field is blank, then set it
      if [[ $LOGIN_NAME ]]; then
        MY_QRY="SELECT username FROM computers WHERE id = '$COMP_REC';"
        EXISTING_USER=$($MY_CMD "$MY_QRY")
        if [[ -z $EXISTING_USER ]] || [[ $EXISTING_USER = "NULL" ]]; then
          MY_QRY="UPDATE computers SET username = '$LOGIN_NAME' WHERE id = '$COMP_REC';"
          $MY_CMD "$MY_QRY"
        fi
      fi
      # set update
      MY_QRY="UPDATE computers SET registered = '$TIME_STAMP', sharingname = '$HOST_NAME' WHERE id = '$COMP_REC';"
    fi
    # above if/then should end in the appropriate query - either insert for new, or update for existing
    if $MY_CMD "$MY_QRY"; then
      echo "Registered"
    fi
    ;;

  "port")
    # looks up the port number and sends it
    MY_QRY="SELECT blueskyid FROM computers WHERE serialnum = '$SERIAL_NUM';"
    MY_PORT=$($MY_CMD "$MY_QRY")
    if [[ $MY_PORT ]]; then
      echo "$MY_PORT"
    fi
    ;;

  "user")
    # looks up the default user if any and sends it
    MY_QRY="SELECT username FROM computers WHERE serialnum = '$SERIAL_NUM';"
    MY_USER=$($MY_CMD "$MY_QRY")
    if [[ $MY_USER ]] && [[ $MY_USER != "NULL" ]]; then
      echo "$MY_USER"
    else
      # TODO: put default login in global table
      if [[ -s $LOGIN_FILE ]]; then
        cat "$LOGIN_FILE"
      fi
    fi
    ;;

  "status")
    # attempts an SSH connection back through the tunnel
    # also sends self destruct, notify mail

    # self destruct
    MY_QRY="SELECT selfdestruct FROM computers WHERE serialnum = '$SERIAL_NUM';"
    SELF_DESTRUCT=$($MY_CMD "$MY_QRY")
    # TODO - read notes and only concat if empty
    if [[ $SELF_DESTRUCT -eq 1 ]]; then
      echo "selfdestruct"
      MY_QRY="UPDATE computers SET status = 'Remote removal initiated', datetime = '$TIME_STAMP' WHERE serialnum = '$SERIAL_NUM';"
      $MY_CMD "$MY_QRY"
      MY_QRY="UPDATE computers SET selfdestruct = 0 WHERE serialnum = '$SERIAL_NUM';"
      $MY_CMD "$MY_QRY"
      exit 0
    fi

    # can we hit it?
    MY_QRY="SELECT blueskyid FROM computers WHERE serialnum = '$SERIAL_NUM';"
    MY_PORT=$($MY_CMD "$MY_QRY")
    SSH_PORT=$((22000 + MY_PORT))
    if TEST_CONN=$(ssh \
      -i /usr/local/bin/BlueSkyConnect/Server/blueskyd \
      -l bluesky \
      -o BatchMode=yes \
      -o ConnectTimeout=10 \
      -o StrictHostKeyChecking=no \
      -p $SSH_PORT \
      localhost \
      "/usr/bin/defaults read /var/bluesky/settings serial"); then
      if [[ $TEST_CONN = "$SERIAL_NUM" ]]; then
        allGood
      else
        snMismatch
      fi
    # either down or defaults is messed up, try using PlistBuddy
    elif TEST_CONN_TWO=$(ssh \
      -i /usr/local/bin/BlueSkyConnect/Server/blueskyd \
      -l bluesky \
      -o BatchMode=yes \
      -o ConnectTimeout=10 \
      -o StrictHostKeyChecking=no \
      -p $SSH_PORT \
      localhost \
      "/usr/libexec/PlistBuddy -c 'Print serial' /var/bluesky/settings.plist" 2>&1); then
      if [[ $TEST_CONN_TWO = "$SERIAL_NUM" ]]; then
        allGood
      else
        snMismatch
      fi
    else # it’s down - let’s find out why
      if [[ $TEST_CONN_TWO = *"ssh_exchange_identification"* ]]; then
        # PKI exchange issue for bluesky user - let’s return OK to keep tunnel up.
        echo "OK"
        MY_QRY="UPDATE computers SET status = 'ERROR: tunnel issue TO client', datetime = '$TIME_STAMP' WHERE serialnum = '$SERIAL_NUM';"
      elif [[ $TEST_CONN_TWO = *"Permission denied"* ]]; then
        # Most likely prompting for password auth - key issue - let’s return OK to keep tunnel up.
        echo "OK"
        MY_QRY="UPDATE computers SET status = 'ERROR: cannot verify serial number', datetime = '$TIME_STAMP' WHERE serialnum = '$SERIAL_NUM';"
      else
        echo "Cannot connect."
        MY_QRY="UPDATE computers SET status = 'ERROR: no tunnel established', datetime = '$TIME_STAMP' WHERE serialnum = '$SERIAL_NUM';"
      fi
      $MY_CMD "$MY_QRY"
    fi

    # notify
    MY_QRY="SELECT notify FROM computers WHERE serialnum = '$SERIAL_NUM';"
    NOTIFY_ME=$($MY_CMD "$MY_QRY")
    if [[ $NOTIFY_ME -eq 1 ]]; then
      MY_QRY="SELECT email FROM computers WHERE serialnum = '$SERIAL_NUM';"
      EMAIL_ADDR=$($MY_CMD "$MY_QRY")
      if [[ -z $EMAIL_ADDR ]] || [[ $EMAIL_ADDR = "NULL" ]]; then
        MY_QRY="SELECT defaultemail FROM computers;"
        EMAIL_ADDR=$($MY_CMD "$MY_QRY")
      fi
      MY_QRY="SELECT hostname FROM computers WHERE serialnum = '$SERIAL_NUM';"
      HOST_NAME=$($MY_CMD "$MY_QRY")
      # MY_QRY="SELECT status FROM computers WHERE serialnum = '$SERIAL_NUM';"
      # CURR_STAT=$($MY_CMD "$MY_QRY")
      MY_QRY="SELECT status FROM username WHERE serialnum = '$SERIAL_NUM';"
      MY_USER=$($MY_CMD "$MY_QRY")

      if [[ -x /usr/local/bin/BlueSkyConnect/Server/emailHelper.sh ]]; then
        SERVER_FQDN=$(< /usr/local/bin/BlueSkyConnect/Server/server.txt)
        EMAIL_BODY=$(
                     cat << EOM
You requested to be notified when we next saw $HOST_NAME with serial number $SERIAL_NUM, ID: $MY_PORT.
https://$SERVER_FQDN/blu=$MY_PORT
SSH bluesky://com.solarwindsmsp.bluesky.admin?blueSkyID=$MY_PORT&user=$MY_USER&action=ssh
VNC bluesky://com.solarwindsmsp.bluesky.admin?blueSkyID=$MY_PORT&user=$MY_USER&action=vnc
SCP bluesky://com.solarwindsmsp.bluesky.admin?blueSkyID=$MY_PORT&user=$MY_USER&action=scp
EOM
        )
        /usr/local/bin/BlueSkyConnect/Server/emailHelper.sh "BlueSky Notification $SERIAL_NUM" "$EMAIL_BODY"
      fi

      MY_QRY="UPDATE computers SET notify = 0 WHERE serialnum = '$SERIAL_NUM';"
      $MY_CMD "$MY_QRY"
    fi

    ;;

esac

exit 0
