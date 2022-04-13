#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

onDie() {
  fail2ban-client stop
  exit 0
}

trap onDie TERM

if [[ $FAIL2BAN -eq 1 ]]; then
  # This simulates the normal startup, only in the foreground
  # Not using fail2ban-client to ensure supervisor catches any exits
  /usr/bin/python3 /usr/bin/fail2ban-server -s /var/run/fail2ban/fail2ban.sock -p /var/run/fail2ban/fail2ban.pid -f &
  sleep 5
  /usr/bin/fail2ban-client reload
  wait
fi
