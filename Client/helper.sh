#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# helper script performs privileged tasks for BlueSky, does initial client setup
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

OUR_HOME="/var/bluesky"
B_VER="2.3.2"

if [[ -f "$OUR_HOME/.debug" ]]; then
  set -x
fi

killShells() {
  if AUTOSSH_PID=$(pgrep -af "$OUR_HOME/autossh"); then
    kill -9 "$AUTOSSH_PID"
  fi
  SHELL_LIST=$(pgrep -af "ssh.*bluesky\@")
  for SHELL_PID in $SHELL_LIST; do
    kill -9 "$SHELL_PID"
    logMe "Killed stale shell on $SHELL_PID"
  done
}

logMe() {
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

# if server.plist is not present, error and exit
if [[ ! -e "$OUR_HOME/server.plist" ]]; then
  echo "server.plist is not installed. Please double-check your setup."
  exit 2
fi

# if BlueSky 1.5 is present, get rid of it
if [[ -e /Library/Mac-MSP/BlueSky/helper.sh ]] || [[ $(pkgutil --pkgs) = *"com.mac-msp.bluesky"* ]]; then
  killShells
  killall autossh
  echo "picardAlphaTango" > /Library/Mac-MSP/BlueSky/.getHelp
  sleep 5
  # let’s really make sure the old bluesky is gone...
  dscl . -delete /Users/mac-msp-bluesky
  # let’s clear out old package receipts so we dont cause a phantom loop
  for RECEIPT in $(pkgutil --pkgs | grep com.mac-msp.bluesky); do
    pkgutil --forget "$RECEIPT"
  done
  launchctl unload /Library/LaunchDaemons/com.mac-msp.bluesky* && rm -f /Library/LaunchDaemons/com.mac-msp.bluesky*
fi

if [[ -f "$OUR_HOME/.getHelp" ]]; then
  HELP_WITH_WHAT=$(< "$OUR_HOME/.getHelp")
  rm -f "$OUR_HOME/.getHelp"
fi

# initiate self-destruct
if [[ $HELP_WITH_WHAT = "selfdestruct" ]]; then
  killShells
  rm -rf "$OUR_HOME"
  dscl . -delete /Users/bluesky
  pkgutil --forget com.solarwindsmsp.bluesky.pkg
  launchctl unload /Library/LaunchDaemons/com.solarwindsmsp.bluesky* && rm -f /Library/LaunchDaemons/com.solarwindsmsp.bluesky*
  exit 0
fi

# get the version of the OS so we can ensure compatiblity
OS_RAW=$(sw_vers -productVersion)
OS_VERSION_MAJOR=$(awk -F . '{ print $1 }' <<< "$OS_RAW")
OS_VERSION_MINOR=$(awk -F . '{ print $2 }' <<< "$OS_RAW")

# check if user exists and create if necessary
if ! dscl . -read /Users/bluesky 2> /dev/null; then
  # user doesn’t exist, let’s try to set it up
  logMe "Creating our user account"
  dscl . -create /Users/bluesky

  # Pick a good UID. We prefer 491 but it could conceivably be in use by someone else
  UID_TEST=491
  while :; do
    UID_CHECK=$(dscl . -search /Users UniqueID $UID_TEST)
    if [[ -z $UID_CHECK ]]; then
      dscl . -create /Users/bluesky UniqueID $UID_TEST
      break
    else
      UID_TEST=$(jot -r 1 400 490)
    fi
  done
  logMe "Created on UID $UID_TEST"

  dscl . -create /Users/bluesky IsHidden 1
  dscl . -create /Users/bluesky NFSHomeDirectory "$OUR_HOME"
  dscl . -create /Users/bluesky Password "*"
  dscl . -create /Users/bluesky PrimaryGroupID 20
  dscl . -create /Users/bluesky RealName "BlueSky"
  dscl . -create /Users/bluesky UserShell /bin/bash
  dseditgroup -o edit -a bluesky -t user com.apple.access_ssh 2> /dev/null # duplicate with line 118?
  # kill any autossh and shells that may have belonged to the old user
  killShells
  # defaults may not be able to validate the serial number until cfprefsd restarts
  killall cfprefsd
  # is there any reason this user needs to be tokenized?
fi
# ensure the permissions are correct on our home
chown -R bluesky "$OUR_HOME"
chflags hidden "$OUR_HOME"

# help me help you. help me... help you.
dseditgroup -o edit -a bluesky -t user com.apple.access_ssh 2> /dev/null # duplicate with line 107?
systemsetup -setremotelogin on &> /dev/null # duplicate with line 121?
if [[ ${OS_VERSION_MAJOR:-10} -eq 10 ]] && [[ ${OS_VERSION_MINOR:-0} -lt 15 ]]; then
  systemsetup -setremotelogin on &> /dev/null # duplicate with line 119?
elif ! /bin/launchctl print system/com.openssh.sshd &>/dev/null; then
  launchctl load -w /System/Library/LaunchDaemons/ssh.plist
fi

# commenting out on 1.12
# re-intro when we can test a more reliable method of determining a VNC server
# if ! pgrep -afq "ARDAgent"; then
#   logMe "Starting ARD agent"
#   /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -activate -access -on -privs -ControlObserve -allowAccessFor -allUsers -quiet
# fi

# if permissions are wrong on the home folder, this will fix
if [[ $HELP_WITH_WHAT = "fixPerms" ]]; then
  logMe "Fixing permissions on our directory"
  chown -R bluesky "$OUR_HOME"
fi

# GSS API config lines mess up client connections in 10.12+
GSS_CHECK=$(grep -e ^"GSSAPIKeyExchange" -e ^"GSSAPITrustDNS" -e ^"GSSAPIDelegateCredentials" /etc/ssh/ssh_config)
if [[ $GSS_CHECK ]] && {
    { [[ ${OS_VERSION_MAJOR:-10} -eq 10 ]] && [[ ${OS_VERSION_MINOR:-0} -ge 12 ]]; } \
    || [[ ${OS_VERSION_MAJOR:-10} -gt 10 ]]
}; then
  grep -v ^"GSSAPIKeyExchange" /etc/ssh/ssh_config | grep -v ^"GSSAPITrustDNS" | grep -v ^"GSSAPIDelegateCredentials" > /tmp/ssh_config && mv /tmp/ssh_config /etc/ssh/ssh_config
fi

# sometimes BlueSky user can’t kill shells
if [[ $HELP_WITH_WHAT = "contractKiller" ]]; then
  logMe "Helper was asked to kill connections"
  killShells
fi

# workaround for bug that is creating empty settings file
if [[ ! -f $OUR_HOME/settings.plist ]] || ! grep -q keytime "$OUR_HOME/settings.plist"; then
  logMe "Helper is resetting the settings property list"
  rm -f "$OUR_HOME/settings.plist"
  touch "$OUR_HOME/settings.plist"
  /usr/libexec/PlistBuddy -c "Add :keytime integer 0" "$OUR_HOME/settings.plist"
  # commenting these out for 1.5, creation of variables should be more robust now
  # /usr/libexec/PlistBuddy -c "Add :portcache integer -1" "$OUR_HOME/settings.plist"
  # /usr/libexec/PlistBuddy -c "Add :serial string 0" "$OUR_HOME/settings.plist"
  chown bluesky "$OUR_HOME/settings.plist"
fi

# ensure proper version in settings file
SET_CHECK=$(/usr/libexec/PlistBuddy -c "Print :version" "$OUR_HOME/settings.plist" 2> /dev/null)
if [[ -z $SET_CHECK ]]; then
  logMe "Adding version to the settings property list"
  /usr/libexec/PlistBuddy -c "Add :version string $B_VER" "$OUR_HOME/settings.plist"
elif [[ $SET_CHECK != "$B_VER" ]]; then
  logMe "Setting version in the settings property list"
  /usr/libexec/PlistBuddy -c "Set :version $B_VER" "$OUR_HOME/settings.plist"
fi

# ensure OpenSSL path links for older OS/our cURL
if [[ ${OS_VERSION_MAJOR:-10} -eq 10 ]] && [[ ${OS_VERSION_MINOR} -lt 14 ]]; then
  if [[ ! -e /usr/local/opt/openssl@1.1 ]]; then
    mkdir -p "/usr/local/opt"
    ln -s "$OUR_HOME/openssl" "/usr/local/opt/openssl@1.1"
  fi
  if [[ ! -e /usr/local/Cellar/openssl@1.1/1.1.1n ]]; then
    mkdir -p "/usr/local/Cellar/openssl@1.1"
    ln -s "$OUR_HOME/openssl" "/usr/local/Cellar/openssl@1.1/1.1.1n"
  fi
fi

# make sure we stay executable - helps with initial install if someone isn’t packaging
chmod a+x /var/bluesky/helper.sh \
  /var/bluesky/bluesky.sh \
  /var/bluesky/autossh \
  /var/bluesky/corkscrew \
  /var/bluesky/proxy-config \
  /var/bluesky/.ssh/wrapper.sh

# babysit the BlueSky process
PREV_PID=$(/usr/libexec/PlistBuddy -c "Print :pid" "$OUR_HOME/settings.plist" 2> /dev/null)
CURR_PID=$(pgrep -afo "$OUR_HOME/bluesky.sh"$)
if [[ $CURR_PID ]]; then
  if [[ $CURR_PID -eq $PREV_PID ]]; then
    # bluesky.sh must be stuck if it’s still there 5 min later. kill it.
    kill -9 "$CURR_PID"
    logMe "Killed stale BlueSky process on $CURR_PID"
  else
    /usr/libexec/PlistBuddy -c "Add :pid integer" "$OUR_HOME/settings.plist" 2> /dev/null
    /usr/libexec/PlistBuddy -c "Set :pid $CURR_PID" "$OUR_HOME/settings.plist"
  fi
fi

# if main launchd is not running, let’s check perms and start it
WE_LAUNCHED=$(launchctl list | grep -c com.solarwindsmsp.bluesky)
if [[ ${WE_LAUNCHED:-0} -lt 4 ]]; then
  logMe "LaunchDaemons do not appear to be loaded. Fixing."
  if [[ ! -e /Library/LaunchDaemons/com.solarwindsmsp.bluesky.plist ]]; then
    cp /var/bluesky/com.solarwindsmsp.bluesky.plist /Library/LaunchDaemons/com.solarwindsmsp.bluesky.plist
  fi
  if [[ ! -e /Library/LaunchDaemons/com.solarwindsmsp.bluesky.helper.plist ]]; then
    cp /var/bluesky/com.solarwindsmsp.bluesky.helper.plist /Library/LaunchDaemons/com.solarwindsmsp.bluesky.helper.plist
  fi
  if [[ ! -e /Library/LaunchDaemons/com.solarwindsmsp.bluesky.reconnect.plist ]]; then
    cp /var/bluesky/com.solarwindsmsp.bluesky.reconnect.plist /Library/LaunchDaemons/com.solarwindsmsp.bluesky.reconnect.plist
  fi
  if [[ ! -e /Library/LaunchDaemons/com.solarwindsmsp.bluesky.sleepwatcher.plist ]]; then
    cp /var/bluesky/com.solarwindsmsp.bluesky.sleepwatcher.plist /Library/LaunchDaemons/com.solarwindsmsp.bluesky.sleepwatcher.plist
  fi
  chmod 644 /Library/LaunchDaemons/com.solarwindsmsp.bluesky.*
  chown root:wheel /Library/LaunchDaemons/com.solarwindsmsp.bluesky.*
  launchctl load -w /Library/LaunchDaemons/com.solarwindsmsp.bluesky.*
fi

exit 0
