#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# sets up a base install of Ubuntu Server with configuration needed for BlueSky
# DO NOT RUN this on migrated BlueSky 1.x servers
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

# get variables
# you can fill these in here or the script will ask for them
SERVER_FQDN=""
WEB_ADMIN_PASSWORD=""
MYSQL_ROOT_PASS=""
EMAIL_ALERT_ADDRESS=""

# --------- DO NOT EDIT BELOW ------------------------------------------------------

if [[ -z $USE_HTTP ]]; then
  USE_HTTP=0
fi

if [[ $USE_HTTP -eq 1 ]]; then
  APACHE_CONF="000-default"
else
  APACHE_CONF="default-ssl"
fi

if [[ $IN_DOCKER ]]; then
  SERVER_FQDN=$SERVERFQDN
  WEB_ADMIN_PASSWORD=$WEBADMINPASS
  EMAIL_ALERT_ADDRESS=$EMAILALERT

  # Take provided MySQL root password if we have been provided it.
  # If not, use the password from the linked container, or set to admin.
  if [[ $MYSQLROOTPASS ]]; then
    MYSQL_ROOT_PASS=$MYSQLROOTPASS
    echo "Setting MYSQL_ROOT_PASS to what was provided"
  elif [[ $DB_ENV_MYSQL_ROOT_PASSWORD ]]; then
    # let’s check for the linked containers password
    MYSQL_ROOT_PASS=$DB_ENV_MYSQL_ROOT_PASSWORD
    echo "Setting MYSQL_ROOT_PASS to that of the linked container"
  else
    MYSQL_ROOT_PASS="admin"
    echo "Setting MYSQL_ROOT_PASS to default"
  fi

  if [[ $TIMEZONE ]]; then
    # set timezone
    rm /etc/localtime
    echo "$TIMEZONE" > /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata
  fi
fi

# ask for blank variables
if [[ -z $SERVER_FQDN ]]; then
  echo "Please enter a fully qualified domain name for this server."
  read -r SERVER_FQDN
  if [[ -z $SERVER_FQDN ]]; then
    echo "This value cannot be empty. Please try again."
    exit 2
  fi
fi
if [[ -z $WEB_ADMIN_PASSWORD ]]; then
  echo "Please enter a password for logging into the web admin."
  read -r WEB_ADMIN_PASSWORD
  if [[ -z $WEB_ADMIN_PASSWORD ]]; then
    echo "This value cannot be empty. Please try again."
    exit 2
  fi
  echo "Please enter the password again."
  read -r WEB_PASS_CONF
  if [[ $WEB_PASS_CONF != "$WEB_ADMIN_PASSWORD" ]]; then
    echo "Sorry the passwords do not match. Please try again."
    exit 2
  fi
fi
if [[ -z $EMAIL_ALERT_ADDRESS ]]; then
  echo "Please enter an email address where you will receive alerts."
  read -r EMAIL_ALERT_ADDRESS
  if [[ -z $EMAIL_ALERT_ADDRESS ]]; then
    echo "This value cannot be empty. Please try again."
    exit 2
  fi
fi
if [[ -z $MYSQL_ROOT_PASS ]]; then
  echo "Please enter a root password for MySQL. Leave it blank and we will generate one."
  read -r MYSQL_ROOT_PASS
  if [[ -z $MYSQL_ROOT_PASS ]]; then
    MYSQL_ROOT_PASS=$(openssl rand -base64 36)
  fi
fi

# variables no one will care about
MYSQL_COLLECTOR_PASS=$(openssl rand -base64 36)

# double-check permissions on uploaded BlueSky files
chown -R root:root /usr/local/bin/BlueSkyConnect/Server
chmod 755 /usr/local/bin/BlueSkyConnect/Server
chown www-data /usr/local/bin/BlueSkyConnect/Server/keymaster.sh
chown www-data /usr/local/bin/BlueSkyConnect/Server/processor.sh
chmod 755 /usr/local/bin/BlueSkyConnect/Server/*.sh

# write server FQDN to a file for easy reference in case hostname changes
echo "$SERVER_FQDN" > /usr/local/bin/BlueSkyConnect/Server/server.txt
echo "$SERVER_FQDN" > "/usr/local/bin/BlueSkyConnect/Admin Tools/server.txt"

# reconfigure sshd_config to meet our specifications
echo "Ciphers chacha20-poly1305@openssh.com,aes256-ctr" >> /etc/ssh/sshd_config
echo "MACs hmac-sha2-512-etm@openssh.com" >> /etc/ssh/sshd_config
sed -i "\%HostKey /etc/ssh/ssh_host_dsa_key%d" /etc/ssh/sshd_config
sed -i "\%HostKey /etc/ssh/ssh_host_ecdsa_key%d" /etc/ssh/sshd_config
sed -i "s/#Port 22/Port 3122/g" /etc/ssh/sshd_config
service sshd restart
if [[ $IN_DOCKER ]]; then
  # disable password authentication for SSH in Docker
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
  echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
fi
# set shorter tunnel timeouts
echo "ClientAliveInterval 10" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config

# setup local firewall
if [[ -z $IN_DOCKER ]]; then
  ufw allow 3122
  ufw enable
  ufw allow 80
  ufw allow 443
fi

# install software
if [[ -z $IN_DOCKER ]]; then
  apt-get update
  debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASS"
  debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASS"
  apt-get -y install apache2 fail2ban mysql-server php-mysql php libapache2-mod-php php-mysql inoticoming swaks curl
fi

# setup user accounts/folders
groupadd admin 2> /dev/null # will already be there on DO
useradd -m -g admin admin
useradd -m bluesky
passwd -d admin
passwd -d bluesky
usermod -s /bin/bash admin
usermod -s /bin/bash bluesky
mkdir -p /home/admin/.ssh
mkdir -p /home/bluesky/.ssh
mkdir -p /home/admin/newkeys
mkdir -p /home/bluesky/newkeys
chown www-data /home/admin/newkeys
chown www-data /home/bluesky/newkeys
chown -R admin /home/admin/.ssh
chown -R bluesky /home/bluesky/.ssh
chmod -R go-rwx /home/admin/.ssh
chmod -R go-rwx /home/bluesky/.ssh
# sets auth.log so admin can read it
touch /var/log/auth.log
chgrp admin /var/log/auth.log

# configure Apache
if [[ $USE_HTTP -ne 1 ]]; then
  if [[ $IN_DOCKER ]]; then
    if [[ -f "/certs/$SSL_CERT" ]] && [[ -f "/certs/$SSL_KEY" ]]; then
      # we have an SSL cert coming in
      echo "We are using the SSL cert provided."
      ln -fs "/certs/$SSL_CERT" /etc/ssl/certs/ssl-cert-snakeoil.pem
      ln -fs "/certs/$SSL_KEY" /etc/ssl/private/ssl-cert-snakeoil.key
    else
      # throw in self signed cert
      echo "Generating self-signed SSL cert."
      openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem -subj "/C=US/ST=Somewhere/L=Somewhere/O=BlueSky/OU=Development/CN=$SERVERFQDN"
    fi
    sed -i "s/CHANGETHIS/$SERVER_FQDN/g" /etc/apache2/apache2.conf
  fi
  a2enmod ssl
  a2ensite default-ssl
fi
a2enmod cgi
sed -i "s/ServerAdmin webmaster@localhost/ServerAdmin $EMAIL_ALERT_ADDRESS/g" "/etc/apache2/sites-enabled/$APACHE_CONF.conf"

# read the top half
# should use mktemp for this
head -n 5 "/etc/apache2/sites-enabled/$APACHE_CONF.conf" > "/tmp/$APACHE_CONF.conf"
# put this in
echo "    ServerName $SERVER_FQDN" >> "/tmp/$APACHE_CONF.conf"
if [[ $USE_HTTP -ne 1 ]]; then
  echo "        SSLProtocol All -SSLv2 -SSLv3" >> "/tmp/$APACHE_CONF.conf"
fi
# write the bottom half
tail -n +6 "/etc/apache2/sites-enabled/$APACHE_CONF.conf" >> "/tmp/$APACHE_CONF.conf"
# make backup and move it in place
mv "/etc/apache2/sites-enabled/$APACHE_CONF.conf" "/tmp/$APACHE_CONF.conf.backup"
mv "/tmp/$APACHE_CONF.conf" "/etc/apache2/sites-enabled/$APACHE_CONF.conf"

if [[ $USE_HTTP -ne 1 ]]; then
  # setup port 80 redirect to 443
  cat > /tmp/000-default.conf << EOF
<VirtualHost *:80>
Redirect permanent / https://$SERVER_FQDN/
ServerName $SERVER_FQDN
EOF
  tail -n +2 /etc/apache2/sites-enabled/000-default.conf >> /tmp/000-default.conf
  mv /etc/apache2/sites-enabled/000-default.conf /tmp/000-default.conf.backup
  mv /tmp/000-default.conf /etc/apache2/sites-enabled/000-default.conf
fi

if [[ -z $IN_DOCKER ]]; then
  service apache2 restart
fi

# move web site to /var/www/html
mv /var/www/html /var/www/html.old
ln -s /usr/local/bin/BlueSkyConnect/Server/html /var/www/html
chown -R www-data /usr/local/bin/BlueSkyConnect/Server/html

# configure cron jobs
cat > /tmp/mycron << EOF
@reboot /usr/local/bin/BlueSkyConnect/Server/startGozer.sh
*/30 * * * * /usr/local/bin/BlueSkyConnect/Server/purgeTemp.sh
*/5 * * * * /usr/local/bin/BlueSkyConnect/Server/serverup.sh
EOF
crontab /tmp/mycron
/usr/local/bin/BlueSkyConnect/Server/startGozer.sh

# setup collector.php
ln -fs /usr/local/bin/BlueSkyConnect/Server/collector.php /usr/lib/cgi-bin/collector.php
chown www-data /usr/local/bin/BlueSkyConnect/Server/collector.php
chmod 700 /usr/local/bin/BlueSkyConnect/Server/collector.php
sed -i "s/CHANGETHIS/$MYSQL_COLLECTOR_PASS/g" /usr/lib/cgi-bin/collector.php
if [[ $IN_DOCKER ]]; then
  sed -i "s/localhost/$MYSQLSERVER/g" /usr/lib/cgi-bin/collector.php
fi

# setup my.cnf
cat > /var/local/my.cnf << EOF
[client]
user = root
password = $MYSQL_ROOT_PASS
EOF
if [[ $IN_DOCKER ]]; then
  echo "host = $MYSQLSERVER" >> /var/local/my.cnf
else
  echo "host = 127.0.0.1" >> /var/local/my.cnf
fi
chown admin:www-data /var/local/my.cnf
chmod 640 /var/local/my.cnf

# setup database
# test if database already exists
DB_EXISTS=$(/usr/bin/mysql --defaults-file=/var/local/my.cnf information_schema -N -B -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'BlueSky';")
if [[ -z $DB_EXISTS ]]; then
  # does not exist
  /usr/bin/mysql --defaults-file=/var/local/my.cnf -N -B -e "CREATE DATABASE BlueSky;"
  /usr/bin/mysql --defaults-file=/var/local/my.cnf BlueSky < /usr/local/bin/BlueSkyConnect/Server/myBlueSQL.sql
fi

MY_CMD="/usr/bin/mysql --defaults-file=/var/local/my.cnf BlueSky -N -B -e"

# setup credentials in /var/www/html/config.php
sed -i "s/MYSQLROOT/$MYSQL_ROOT_PASS/g" /var/www/html/config.php
if [[ $IN_DOCKER ]]; then
  sed -i "s/localhost/$MYSQLSERVER/g" /var/www/html/config.php
fi

if [[ -z $IN_DOCKER ]] || [[ -z $DB_EXISTS ]]; then
  # setup credentials in membership_users table only if we are being run outside of docker OR the database was just created
  MY_QRY="UPDATE membership_users SET passMD5 = MD5('$WEB_ADMIN_PASSWORD'), email = '$EMAIL_ALERT_ADDRESS' WHERE memberID = 'admin';"
  $MY_CMD "$MY_QRY"
fi

# set collector MySQL perms
# set variable to refer to what host(s) can connect to MySQL
MYSQL_HOST_SECURITY="localhost"
if [[ $IN_DOCKER ]]; then
  MYSQL_HOST_SECURITY="%"
  # let’s make sure the collector MySQL user doesn’t exist as we will be recreating it
  MY_QRY="DROP USER 'collector'@'$MYSQL_HOST_SECURITY';"
  $MY_CMD "$MY_QRY"
fi
# create user
MY_QRY="CREATE USER 'collector'@'$MYSQL_HOST_SECURITY' IDENTIFIED BY '$MYSQL_COLLECTOR_PASS';"
$MY_CMD "$MY_QRY"
MY_QRY="GRANT SELECT ON BlueSky.computers TO 'collector'@'$MYSQL_HOST_SECURITY';"
$MY_CMD "$MY_QRY"

# fail2ban conf
sed -i "s/SERVERFQDN/$SERVER_FQDN/g" /usr/local/bin/BlueSkyConnect/Server/sendEmail-whois-lines.conf
cp /usr/local/bin/BlueSkyConnect/Server/sendEmail-whois-lines.conf /etc/fail2ban/action.d/sendEmail-whois-lines.conf
sed -i "s/EMAILADDRESS/$EMAIL_ALERT_ADDRESS/g" /usr/local/bin/BlueSkyConnect/Server/jail.local
cp /usr/local/bin/BlueSkyConnect/Server/jail.local /etc/fail2ban
if [[ -z $IN_DOCKER ]]; then
  service fail2ban start
fi

# add $EMAIL_ALERT_ADDRESS to MySQL for alerting
MY_QRY="UPDATE global SET defaultemail = '$EMAIL_ALERT_ADDRESS';"
$MY_CMD "$MY_QRY"

# update emailHelper-dist. You still need to enable it.
sed -i "s/EMAILADDRESS/$EMAIL_ALERT_ADDRESS/g" /usr/local/bin/BlueSkyConnect/Server/emailHelper-dist.sh 2> /dev/null

# put server FQDN into client config.disabled for proxy routing
sed -i "s/SERVER/$SERVER_FQDN/g" /usr/local/bin/BlueSkyConnect/Client/.ssh/config.disabled

# Run setup for client files
/usr/local/bin/BlueSkyConnect/Server/client-config.sh

# That’s all folks!
if [[ -z $IN_DOCKER ]]; then
  cat << EOM
All set. Please be sure to generate a CSR and/or install a verifiable SSL certificate
in Apache by editing SSL paths in /etc/apache2/sites-enabled/default-ssl.conf
BlueSky will not connect to servers with self-signed or invalid certificates.
And configure /usr/local/bin/BlueSkyConnect/Server/emailHelper.sh with your preferred SMTP setup.
EOM
else
  if [[ $SMTP_SERVER ]] && [[ $SMTP_AUTH ]] && [[ $SMTP_PASS ]]; then
    # enable email alerts
    mv /usr/local/bin/BlueSkyConnect/Server/emailHelper-dist.sh /usr/local/bin/BlueSkyConnect/Server/emailHelper.sh 2> /dev/null
  fi
fi
exit 0
