#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# This script is called by launchd every 5 minutes.
# Ensures that the connection to BlueSky is up and running, attempts repair if there is a problem.
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

# Set this to a different location if you’d prefer it live somewhere else
OUR_HOME="/var/bluesky"

B_VER="2.3.2"

# planting a debug flag runs bash in -x so you get all the output
if [[ -f "$OUR_HOME/.debug" ]]; then
  set -x
fi

callApi() {
  PAYLOAD=""
  for DATUM in "$@"; do
    PAYLOAD="$PAYLOAD --data-urlencode $DATUM"
  done
  "$CURL" \
    "$CA_CERT" \
    "$PAYLOAD" \
    --max-time 60 \
    "$CURL_PROXY" \
    --request POST \
    --retry 4 \
    --show-error \
    --silent \
    --tlsv1 \
    "https://$BLUESKY_SERVER/cgi-bin/collector.php"
}

getAutoPid() {
  AUTO_PID=$(head -n 1 "$OUR_HOME/autossh.pid")
  if [[ -z $AUTO_PID ]] || ! ps -ax "$AUTO_PID" &> /dev/null; then
    # not running on advertised pid
    rm -f "$OUR_HOME/autossh.pid"
    logMe "autossh not present on saved PID"
    AUTO_PID=""
    # see if it’s running rogue
    AUTO_PROC=$(pgrep -af "$OUR_HOME/autossh")
    if [[ $AUTO_PROC ]]; then
      AUTO_PID=$AUTO_PROC
      echo "$AUTO_PID" > "$OUR_HOME/autossh.pid"
      logMe "found autossh rogue on $AUTO_PID"
    fi
  else
    logMe "found autossh running on $AUTO_PID"
  fi
}

killShells() {
  # start by taking down autossh
  getAutoPid
  if [[ $AUTO_PID ]]; then
    kill -9 "$AUTO_PID"
  fi
  # now go after any rogue SSH processes
  SHELL_LIST=$(pgrep -af "ssh.*bluesky\@")
  for SHELL_PID in $SHELL_LIST; do
    kill -9 "$SHELL_PID"
  done
  # if they are still alive, ask for help
  getAutoPid
  SHELL_LIST=$(pgrep -af "ssh.*bluesky\@")
  if [[ $SHELL_LIST ]] || [[ $AUTO_PID ]]; then
    echo "contractKiller" > "$OUR_HOME/.getHelp"
    sleep 1
  fi
}

logMe() {
  # gets message from first argument attaches date stamp and puts it in our log file
  # if debug flag is present, echo the log message to stdout
  LOG_MSG="$1"
  LOG_FILE="$OUR_HOME/activity.txt"
  if [[ ! -e $LOG_FILE ]]; then
    touch "$LOG_FILE"
  fi
  DATE_STAMP=$(date "+%Y-%m-%d %H:%M:%S")
  echo "$DATE_STAMP - v$B_VER - $LOG_MSG" >> "$LOG_FILE"
  if [[ -f "$OUR_HOME/.debug" ]]; then
    echo "$LOG_MSG"
  fi
}

reKey() {
  logMe "Running reKey sequence"
  # make unique SSH key pair
  rm -f "$OUR_HOME/.ssh/bluesky_client"
  rm -f "$OUR_HOME/.ssh/bluesky_client.pub"
  ssh-keygen -q -t "$KEY_ALG" -N "" -f "$OUR_HOME/.ssh/bluesky_client" -C "$SERIAL_NUM"
  PUB_KEY=$(< "$OUR_HOME/.ssh/bluesky_client.pub")
  if [[ -z $PUB_KEY ]]; then
    logMe "ERROR - reKey failed and we are broken. Please reinstall."
    exit 1
  fi
  chown bluesky "$OUR_HOME/.ssh/bluesky_client"
  chmod 600 "$OUR_HOME/.ssh/bluesky_client"
  chown bluesky "$OUR_HOME/.ssh/bluesky_client.pub"
  chmod 600 "$OUR_HOME/.ssh/bluesky_client.pub"

  # server will require encryption
  PUB_KEY=$(openssl smime -encrypt -aes256 -in ~/.ssh/bluesky_client.pub -outform PEM "$OUR_HOME/blueskyclient.pub")
  if [[ -z $PUB_KEY ]]; then
    logMe "ERROR - reKey failed and we are broken. Please reinstall."
    exit 1
  fi

  # upload pubkey
  if ! INSTALL_RESULT=$(callApi "newpub=$PUB_KEY") || [[ $INSTALL_RESULT != "Installed" ]]; then
    logMe "ERROR - Upload of new public key failed. Exiting."
    exit 1
  fi

  # get sharing name and Watchman Monitoring client group if present
  HOST_NAME=$(scutil --get ComputerName)
  if [[ -z $HOST_NAME ]]; then
    HOST_NAME=$(hostname)
  fi
  WM_CG=$(defaults read /Library/MonitoringClient/ClientSettings ClientGroup)
  if [[ $WM_CG ]]; then
    HOST_NAME="$WM_CG - $HOST_NAME"
  fi

  # upload info to get registered

  if ! UPLOAD_RESULT=$(callApi "serialNum=$SERIAL_NUM" "actionStep=register" "hostName=$HOST_NAME") \
    || [[ $UPLOAD_RESULT != "Registered" ]]; then
    logMe "ERROR - Registration with server failed. Exiting."
    exit 1
  fi

  /usr/libexec/PlistBuddy -c "Add :keytime integer $(date +%s)" "$OUR_HOME/settings.plist" 2> /dev/null
  /usr/libexec/PlistBuddy -c "Set :keytime $(date +%s)" "$OUR_HOME/settings.plist"
}

restartConnection() {
  killShells
  startMeUp
}

rollLog() {
  LOG_NAME="$1"
  if [[ -f "$OUR_HOME/$LOG_NAME" ]]; then
    ROLL_COUNT=5
    rm -f "$OUR_HOME/$LOG_NAME.$ROLL_COUNT" &> /dev/null
    while [[ $ROLL_COUNT -gt 0 ]]; do
      PREV_COUNT=$((ROLL_COUNT - 1))
      if [[ -f "$OUR_HOME/$LOG_NAME.$PREV_COUNT" ]]; then
        mv "$OUR_HOME/$LOG_NAME.$PREV_COUNT" "$OUR_HOME/$LOG_NAME.$ROLL_COUNT"
      fi
      if [[ $PREV_COUNT -eq 0 ]]; then
        mv "$OUR_HOME/$LOG_NAME" "$OUR_HOME/$LOG_NAME.$ROLL_COUNT"
      fi
      ROLL_COUNT=$PREV_COUNT
    done
    TIME_STAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "Log file created at $TIME_STAMP" > "$OUR_HOME/$LOG_NAME"
  fi
}

serialMonster() {
  # reads serial number in settings and checks it against hardware - helpful if we are cloned or blank logic board
  # sets $SERIAL_NUM for rest of script
  SAVED_NUM=$(/usr/libexec/PlistBuddy -c "Print :serial" "$OUR_HOME/settings.plist" 2> /dev/null)
  HW_NUM=$(/usr/libexec/PlistBuddy -c "Print :IORegistryEntryChildren:0:IOPlatformSerialNumber" /dev/stdin <<< "$(ioreg -a -d 2 -k IOPlatformSerialNumber)")
  if [[ -z $HW_NUM ]]; then
    HW_NUM=$(system_profiler SPHardwareDataType | awk -F ": " '/Serial Number/ {print $2}')
  fi
  # is hardware serial a blank logic board
  if [[ -z $HW_NUM ]] \
    || [[ $HW_NUM = *"Available"* ]] \
    || [[ $HW_NUM = *"Serial"* ]] \
    || [[ $HW_NUM = *"Number"* ]]; then
    BLANK_BOARD=1
  fi

  # do we match?
  if [[ $HW_NUM ]] && [[ $SAVED_NUM = "$HW_NUM" ]]; then
    # that was easy
    SERIAL_NUM="$SAVED_NUM"
  else
    if [[ ${BLANK_BOARD:-0} -eq 1 ]] && [[ $SAVED_NUM = *"MacMSP"* ]]; then
      # using the old generated hash
      SERIAL_NUM="$SAVED_NUM"
    else
      # must be first run or cloned so reset
      if [[ ${BLANK_BOARD:-0} -eq 1 ]]; then
        # generate a random hash, but check Gruntwork first
        # can this go away?
        HW_NUM=$(/usr/libexec/PlistBuddy -c "Print :serial" /Library/Mac-MSP/Gruntwork/settings.plist 2> /dev/null)
        if [[ -z $HW_NUM ]] || [[ $HW_NUM != *"MacMSP"* ]]; then
          HW_NUM="MacMSP$(uuidgen | tr -d '-')"
        fi
      fi
      # this may be a first run or first after a clone
      /usr/libexec/PlistBuddy -c "Add :serial string $HW_NUM" "$OUR_HOME/settings.plist" 2> /dev/null
      /usr/libexec/PlistBuddy -c "Set :serial $HW_NUM" "$OUR_HOME/settings.plist"
      SERIAL_NUM="$HW_NUM"
      reKey
      # do any other first run steps here
    fi
  fi
}

startMeUp() {
  export AUTOSSH_PIDFILE="$OUR_HOME/autossh.pid"
  export AUTOSSH_LOGFILE="$OUR_HOME/autossh.log"
  #rollLog autossh.log
  TIME_STAMP=$(date "+%Y-%m-%d %H:%M:%S")
  echo "$TIME_STAMP BlueSky starting autossh"
  # check for alternate SSH port
  ALT_PORT=$(/usr/libexec/PlistBuddy -c "Print :altport" "$OUR_HOME/settings.plist" 2> /dev/null)
  if [[ -z $ALT_PORT ]]; then
    ALT_PORT=22
  else
    logMe "SSH port is set to $ALT_PORT per settings"
  fi
  # is this 10.6 which doesn’t support UseRoaming or 10.12+ which doesn’t need the flag?
  if [[ ${OS_VERSION_MAJOR:-0} -eq 10 ]] \
    && [[ ${OS_VERSION_MINOR:-0} -ne 6 ]] \
    && [[ ${OS_VERSION_MINOR:-0} -lt 12 ]]; then
    NO_ROAM="-o UseRoaming=no"
  fi
  # main command right here
  $OUR_HOME/autossh -M "$MON_PORT" -f \
    -NnT \
    -c "$PREF_CIPHER" \
    -i "$OUR_HOME/.ssh/bluesky_client" \
    -m "$MSG_AUTH" \
    -o "HostKeyAlgorithms=$KEY_ALG" \
    "$KEX_ALG" \
    "$NO_ROAM" \
    -p 3122 \
    -R "$SSH_PORT:127.0.0.1:$ALT_PORT" \
    -R "$VNC_PORT:127.0.0.1:5900" \
    "bluesky@$BLUESKY_SERVER"
  # echo "$!" > "$OUR_HOME/autossh.pid"
  # are we live?
  sleep 5
  while [[ ${AUTO_TIMER:-0} -lt 35 ]]; do
    SSH_PROC=$(pgrep -af "ssh.*bluesky\@")
    if [[ $SSH_PROC ]]; then
      break
    fi
    sleep 1
    ((AUTO_TIMER++))
  done
  # looks like it started up, let’s check
  getAutoPid
  if [[ -z $AUTO_PID ]]; then
    logMe "ERROR - autossh will not start, check logs. Exiting."
    exit 1
  else
    SSH_PROC=$(pgrep -af "ssh.*bluesky\@")
    if [[ $SSH_PROC ]]; then
      logMe "autossh started successfully"
    else
      logMe "ERROR - autossh is running but no tunnel, check logs. Exiting."
      exit 1
    fi
  fi
}

# make me a sandwich? make it yourself
if [[ $(id -un) != "bluesky" ]]; then
  logMe "ERROR - Script called by wrong user."
  exit 2
fi

# are our perms screwed up?
SCRIPT_PERM=$(stat -f "%Su" "$OUR_HOME/bluesky.sh")
if [[ $SCRIPT_PERM != "bluesky" ]]; then
  echo "fixPerms" > "$OUR_HOME/.getHelp"
  sleep 5
fi

# get server address
BLUESKY_SERVER=$(/usr/libexec/PlistBuddy -c "Print :address" "$OUR_HOME/server.plist" 2> /dev/null)
# sanity check
if [[ -z $BLUESKY_SERVER ]]; then
  logMe "ERROR - Fix the server address."
  exit 1
fi

# get the version of the OS so we can ensure compatiblity
OS_RAW=$(sw_vers -productVersion)
OS_VERSION_MAJOR=$(awk -F . '{ print $1 }' <<< "$OS_RAW")
OS_VERSION_MINOR=$(awk -F . '{ print $2 }' <<< "$OS_RAW")

# select all of our algorithms - treating OS X 10.10 and below as insecure, defaulting to secure
if [[ ${OS_VERSION_MAJOR:-0} -eq 10 ]] \
  && [[ ${OS_VERSION_MINOR:-0} -lt 11 ]]; then
  KEY_ALG="ssh-rsa"
  SERVER_KEY="serverkeyrsa"
  PREF_CIPHER="aes256-ctr"
  KEX_ALG=""
  MSG_AUTH="hmac-ripemd160"
else
  KEY_ALG="ssh-ed25519"
  SERVER_KEY="serverkey"
  PREF_CIPHER="chacha20-poly1305@openssh.com"
  KEX_ALG="-o KexAlgorithms=curve25519-sha256@libssh.org"
  MSG_AUTH="hmac-sha2-512-etm@openssh.com"
fi

# server key will be pre-populated in the installer - put it into known hosts
SERVER_KEY=$(/usr/libexec/PlistBuddy -c "Print :$SERVER_KEY" "$OUR_HOME/server.plist" 2> /dev/null)
if [[ -z $SERVER_KEY ]]; then
  logMe "ERROR - Cannot get server key. Please reinstall."
  exit 1
else
  echo "$SERVER_KEY" > "$OUR_HOME/.ssh/known_hosts"
fi

# are there any live network ports?
# no network connections means we are most certainly down; wait up to 2 min for live network
while [[ $(ifconfig) != *"status: active"* ]]; do
  sleep 5
  ((NET_COUNTER++))
  if [[ ${NET_COUNTER:-0} -gt 25 ]]; then
    killShells
    logMe "No active network connections. Exiting."
    exit 0
  fi
done

# get proxy info from System Preferences
PROXY_INFO=$("$OUR_HOME/proxy-config" -s)
if [[ $PROXY_INFO ]]; then
  CURL_PROXY="--proxy $PROXY_INFO"
else
  CURL_PROXY=""
fi

# set cURL location for older OS
if [[ ${OS_VERSION_MAJOR:-0} -eq 10 ]] \
  && [[ ${OS_VERSION_MINOR:-0} -lt 14 ]] \
  && [[ -x $OUR_HOME/curl/bin/curl ]]; then
  CURL="$OUR_HOME/curl/bin/curl"
else
  CURL="curl"
fi

# set CA certificates for older OS
CA_CERT=""
if [[ ${OS_VERSION_MAJOR:-0} -eq 10 ]] \
  && [[ ${OS_VERSION_MINOR:-0} -lt 15 ]]; then
  CA_CERT="--cacert $OUR_HOME/cacert.pem"
fi

# get serial number
serialMonster

# Attempt to get our port
# Is the server up?
if ! PORT=$(callApi "serialNum=$SERIAL_NUM" "actionStep=port"); then
  # can’t get to the server, we might be down, try again on next cycle
  killShells
  logMe "ERROR - Cannot get to server. Exiting."
  exit 0
fi

# Is collector returning a database connection error?
if [[ $PORT = "ERROR: cant get dbc" ]]; then
  logMe "ERROR - Server has a database problem. Exiting."
  exit 2
fi

# Did port check pass?
if [[ -z $PORT ]]; then
  # try running off cached copy
  PORT=$(/usr/libexec/PlistBuddy -c "Print :portcache" "$OUR_HOME/settings.plist" 2> /dev/null)
  if [[ -z $PORT ]]; then
    # no cached copy either, try reKey
    reKey
    sleep 5
    if ! PORT=$(callApi "serialNum=$SERIAL_NUM" "actionStep=port") || [[ -z $PORT ]]; then
      logMe "ERROR - Cannot reach server and have no port. Exiting."
      exit 2
    else
      # plant port cache for next time
      /usr/libexec/PlistBuddy -c "Add :portcache integer $PORT" "$OUR_HOME/settings.plist" 2> /dev/null
      /usr/libexec/PlistBuddy -c "Set :portcache $PORT" "$OUR_HOME/settings.plist"
    fi
  fi
else
  # plant port cache for next time
  /usr/libexec/PlistBuddy -c "Add :portcache integer $PORT" "$OUR_HOME/settings.plist" 2> /dev/null
  /usr/libexec/PlistBuddy -c "Set :portcache $PORT" "$OUR_HOME/settings.plist"
fi

SSH_PORT=$((22000 + PORT))
VNC_PORT=$((24000 + PORT))
MON_PORT=$((26000 + PORT))

# greysky:
MANUAL_PROXY=$(/usr/libexec/PlistBuddy -c "Print :proxy" "$OUR_HOME/settings.plist" 2> /dev/null)
if [[ $MANUAL_PROXY ]]; then
  # if there is a manual proxy string in settings.plist, go with it
  CONF_PROXY="$MANUAL_PROXY"
else
  # parse cURL proxy output into format for corkscrew
  if [[ $PROXY_INFO ]]; then
    CONF_PROXY=$(awk -F ":" '{ gsub(/\//, ""); print $2,$3 }' <<< "$PROXY_INFO")
  else
    CONF_PROXY=""
  fi
fi

if [[ $CONF_PROXY ]] && [[ ! -e "$OUR_HOME/.ssh/config" ]]; then
  # if proxy exists, and config is disabled, enable it, restart autossh
  sed "s/proxyaddress proxyport/$CONF_PROXY/g" "$OUR_HOME/.ssh/config.disabled" > "$OUR_HOME/.ssh/config"
  # TODO - populate SERVER and OURHOME too
  restartConnection
elif [[ -z $CONF_PROXY ]] && [[ -f "$OUR_HOME/.ssh/config" ]]; then
  # if proxy gone, and config enabled, disable it, restart autossh
  rm -f "$OUR_HOME/.ssh/config"
  restartConnection
fi

# if the keys aren’t made at this point, we should make them
if [[ ! -e "$OUR_HOME/.ssh/bluesky_client" ]]; then
  reKey
fi

# ensure autossh is alive and restart if not
getAutoPid
if [[ -z $AUTO_PID ]]; then
  restartConnection
fi

# ask server for the default username so we can pass on to Watchman
DEFAULT_USER=$(callApi "serialNum=$SERIAL_NUM" "actionStep=user")
if [[ $DEFAULT_USER ]]; then
  /usr/libexec/PlistBuddy -c "Add :defaultuser string $DEFAULT_USER" "$OUR_HOME/settings.plist" 2> /dev/null
  /usr/libexec/PlistBuddy -c "Set :defaultuser $DEFAULT_USER" "$OUR_HOME/settings.plist"
fi

# autossh is running - check against server
CONN_STAT=$(callApi "serialNum=$SERIAL_NUM" "actionStep=status")
if [[ $CONN_STAT != "OK" ]]; then
  if [[ $CONN_STAT = "selfdestruct" ]]; then
    killShells
    echo "selfdestruct" > "$OUR_HOME/.getHelp"
    exit 0
  fi
  logMe "Server says we are down. Restarting tunnels. Server said $CONN_STAT"
  restartConnection
  sleep 5
  CONN_STAT_RETRY=$(callApi "serialNum=$SERIAL_NUM" "actionStep=status")
  if [[ $CONN_STAT_RETRY != "OK" ]]; then
    logMe "Server still says we are down. Trying reKey. Server said $CONN_STAT"
    reKey
    sleep 5
    restartConnection
    sleep 5
    CONN_STAT_LAST_TRY=$(callApi "serialNum=$SERIAL_NUM" "actionStep=status")
    if [[ $CONN_STAT_LAST_TRY != "OK" ]]; then
      logMe "ERROR - Server still says we are down. Needs manual intervention. Server said $CONN_STAT"
      exit 1
    else
      logMe "reKey worked. All good!"
    fi
  else
    logMe "Reconnect worked. All good!"
  fi
else
  logMe "Server sees our connection. All good!"
fi

exit 0
