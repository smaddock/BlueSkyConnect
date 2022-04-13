#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# this will do a git pull and ensure files keep your configurations
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

# TODO - ensure this is run by root

# get variables
SERVER_FQDN=$(< /usr/local/bin/BlueSkyConnect/Server/server.txt)
MYSQL_ROOT_PASS=$(awk '/password/ { print $NF }' /var/local/my.cnf)
# TODO test this
MYSQL_COLLECTOR_PASS=$(awk -F , '/localhost/ { gsub(/ |\047/, "", $3); print $3; exit }' /usr/lib/cgi-bin/collector.php)

# error for blank variables
if [[ -z $SERVER_FQDN ]]; then
  echo "This value cannot be empty. Please fix server.txt and try again."
  exit 2
fi
if [[ -z $MYSQL_ROOT_PASS ]]; then
  echo "Something really borked the my.cnf file. May need to reset the MySQL root password everywhere."
  exit 2
fi

# do the pull
if ! cd /usr/local/bin/BlueSkyConnect; then
  exit 1
fi
git fetch
git reset --hard origin/master

MY_CMD="/usr/bin/mysql --defaults-file=/var/local/my.cnf BlueSky -N -B -e"

# if git pull was ran ahead of this script, we lost collector password. need to reset
if [[ -z $MYSQL_COLLECTOR_PASS ]]; then
  echo "Collector creds got trashed. Will reset."
  MYSQL_COLLECTOR_PASS=$(openssl rand -base64 36)
  MY_QRY="DROP USER 'collector'@'localhost';"
  $MY_CMD "$MY_QRY"
  MY_QRY="CREATE USER 'collector'@'localhost' IDENTIFIED BY '$MYSQL_COLLECTOR_PASS';"
  $MY_CMD "$MY_QRY"
  MY_QRY="GRANT SELECT ON BlueSky.computers TO 'collector'@'localhost';"
  $MY_CMD "$MY_QRY"
fi
sed -i "s/CHANGETHIS/$MYSQL_COLLECTOR_PASS/g" /usr/lib/cgi-bin/collector.php

# double-check permissions on uploaded BlueSky files
chown -R root:root /usr/local/bin/BlueSkyConnect/Server
chmod 755 /usr/local/bin/BlueSkyConnect/Server
chown www-data /usr/local/bin/BlueSkyConnect/Server/keymaster.sh
chown www-data /usr/local/bin/BlueSkyConnect/Server/processor.sh
chmod 755 /usr/local/bin/BlueSkyConnect/Server/*.sh
chown -R www-data /usr/local/bin/BlueSkyConnect/Server/html
chown www-data /usr/local/bin/BlueSkyConnect/Server/collector.php
chmod 700 /usr/local/bin/BlueSkyConnect/Server/collector.php
chown www-data /usr/local/bin/BlueSkyConnect/Server/blueskyd

# sets auth.log so admin can read it
chgrp admin /var/log/auth.log

# sets my.cnf so admin can read it to populate connection log
chmod 640 /var/local/my.cnf
chown admin /var/local/my.cnf

# change the keys for 2.1
# this can be removed in future versions, it’s only for trailblazers who took arrows
REMAKE_PLIST=0
# fix the ciphers and MACs
if grep -q arcfour /etc/ssh/sshd_config; then
  sed -i "/Ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,arcfour/d" /etc/ssh/sshd_config
  echo "Ciphers chacha20-poly1305@openssh.com,aes256-ctr" >> /etc/ssh/sshd_config
fi
if grep -q hmac-sha1 /etc/ssh/sshd_config; then
  sed -i "/MACs hmac-sha2-512,hmac-sha1,hmac-ripemd160,hmac-sha2-512-etm@openssh.com/d" /etc/ssh/sshd_config
  echo "MACs hmac-sha2-512-etm@openssh.com,hmac-ripemd160" >> /etc/ssh/sshd_config
fi
# put the ED25519 key back
if ! grep -q ssh_host_ed25519_key /etc/ssh/sshd_config; then
  # trade: ECDSA goes away in favor of ED25519
  sed -i "s%HostKey /etc/ssh/ssh_host_ecdsa_key%HostKey /etc/ssh/ssh_host_ed25519_key%g" /etc/ssh/sshd_config
  service ssh restart
  REMAKE_PLIST=1
fi
# put the RSA key back
if ! grep -q ssh_host_rsa_key /etc/ssh/sshd_config; then
  HOST_LINE=$(awk '/HostKeys for protocol version 2/ { print NR }' /etc/ssh/sshd_config)
  if [[ $HOST_LINE ]]; then
    # put it back into sshd_config
    head -n "$HOST_LINE" /etc/ssh/sshd_config > /tmp/sshd_config
    echo "HostKey /etc/ssh/ssh_host_rsa_key" >> /tmp/sshd_config
    ((HOST_LINE++))
    tail -n "+$HOST_LINE" /etc/ssh/sshd_config >> /tmp/sshd_config
    mv /tmp/sshd_config /etc/ssh/sshd_config
    service ssh restart
    REMAKE_PLIST=1
  else
    echo "Something is really wrong with the sshd_config file"
    exit 2
  fi
fi
if [[ $REMAKE_PLIST -eq 1 ]]; then
  # remake Client/server.plist
  HOST_KEY=$(ssh-keyscan -t ed25519 localhost | awk '{ print $2,$3 }')
  HOST_KEY_RSA=$(ssh-keyscan -t rsa localhost | awk '{ print $2,$3 }')
  IP_ADDRESS=$(curl -s http://ipinfo.io/ip)
  cat > /usr/local/bin/BlueSkyConnect/Client/server.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>address</key>
    <string>$SERVER_FQDN</string>
    <key>serverkey</key>
    <string>[$SERVER_FQDN]:3122,[$IP_ADDRESS]:3122 $HOST_KEY</string>
    <key>serverkeyrsa</key>
    <string>[$SERVER_FQDN]:3122,[$IP_ADDRESS]:3122 $HOST_KEY_RSA</string>
</dict>
</plist>
EOF
fi

# get $EMAIL_ALERT_ADDRESS from MySQL
MY_QRY="SELECT defaultemail FROM global;"
EMAIL_ALERT_ADDRESS=$($MY_CMD "$MY_QRY")

# setup credentials in /usr/local/bin/BlueSkyConnect/Server/html/config.php
sed -i "s/MYSQLROOT/$MYSQL_ROOT_PASS/g" /usr/local/bin/BlueSkyConnect/Server/html/config.php

# fail2ban conf - not making these active but updating our copies
sed -i "s/SERVERFQDN/$SERVER_FQDN/g" /usr/local/bin/BlueSkyConnect/Server/sendEmail-whois-lines.conf
sed -i "s/EMAILADDRESS/$EMAIL_ALERT_ADDRESS/g" /usr/local/bin/BlueSkyConnect/Server/jail.local

# update emailHelper-dist. You still need to enable it.
sed -i "s/EMAILADDRESS/$EMAIL_ALERT_ADDRESS/g" /usr/local/bin/BlueSkyConnect/Server/emailHelper-dist.sh

# put server FQDN into client config.disabled for proxy routing
sed -i "s/SERVER/$SERVER_FQDN/g" /usr/local/bin/BlueSkyConnect/Client/.ssh/config.disabled

# That’s all folks!
echo "All set. You are up to date!"
exit 0
