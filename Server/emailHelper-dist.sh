#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# if you want any kind of email alerting, please configure this script
# it will receive a subject as "$1" and a body as "$2"
# it has been configured to pull the "To:" address from the global settings in the web admin
# RENAME to emailHelper.sh to activate after configuring the variables below
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

FROM_ADDRESS="EMAILADDRESS"        # replace EMAILADDRESS with the email address
SUBJECT_LINE="$1"
MESSAGE_BODY="$2"
SMTP_SERVER="${SMTP_SERVER:-}"     # enter the SMTP server address after the hyphen
SMTP_AUTH="${SMTP_AUTH:-USERNAME}" # replace USERNAME with the SMTP username
SMTP_PASS="${SMTP_PASS:-PASSWORD}" # replace PASSWORD with the SMTP password

# bail on this is if the server variable isn’t set
if [[ -z $SMTP_SERVER ]]; then
  echo "No server set up. Please edit emailHelper and try again."
  exit 2
fi

# get the To address from MySQL
MY_CMD="/usr/bin/mysql --defaults-file=/var/local/my.cnf BlueSky -N -B -e"
MY_QRY="SELECT defaultemail FROM global;"
TO_ADDRESS=$($MY_CMD "$MY_QRY")

# substitute in your preferred email method
/usr/bin/swaks -tls -a -au "$SMTP_AUTH" -ap "$SMTP_PASS" --server "$SMTP_SERVER" -f "$FROM_ADDRESS" -t "$TO_ADDRESS" --h-Subject "$SUBJECT_LINE" --body "$MESSAGE_BODY"
