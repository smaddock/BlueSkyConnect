#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

IDENTIFIER="com.solarwindsmsp.bluesky.pkg"
APPNAME="BlueSky"

# create folders to work in
# should use mktemp instead
mkdir -p /tmp/pkg
mkdir /tmp/pkg-flat 2> /dev/null
mkdir /tmp/pkg-payload 2> /dev/null
mkdir /tmp/pkg-scripts

# clean up old files
rm -rf /tmp/pkg-flat/*
rm -rf /tmp/pkg-payload/*
rm -rf /tmp/pkg-payload/.* 2> /dev/null
rm -rf /tmp/pkg-scripts/*
rm -rf /tmp/pkg/BlueSky-*.pkg

# copy the files we want to go into the pkg and get info about them
cp -RL /usr/local/bin/BlueSkyConnect/Client/* /tmp/pkg-payload/
cp -R /usr/local/bin/BlueSkyConnect/Client/.ssh /tmp/pkg-payload/
NUM_FILES=$(find /tmp/pkg-payload | wc -l)
INSTALL_KB_SIZE=$(du -k -s /tmp/pkg-payload | awk '{print $1}')

# write out the PackageInfo file to flat pkg location
cat > /tmp/pkg-flat/PackageInfo << EOF
<?xml version="1.0" encoding="utf-8"?>
<pkg-info postinstall-action="none" format-version="2" identifier="$IDENTIFIER" version="$BLUESKY_VERSION" generator-version="InstallCmds-611 (16G1036)" install-location="/var/bluesky" auth="root">
	<atomic-update-bundle/>
	<bundle-version/>
	<payload numberOfFiles="$NUM_FILES" installKBytes="$INSTALL_KB_SIZE"/>
	<relocate/>
	<scripts>
		<preinstall file="./preinstall"/>
		<postinstall file="./postinstall"/>
	</scripts>
	<strict-identifier/>
	<update-bundle/>
	<upgrade-bundle/>
</pkg-info>
EOF

# write out the scripts
cat > /tmp/pkg-scripts/preinstall << EOF
#!/bin/bash
mkdir -p /var/bluesky
exit 0
EOF

cat > /tmp/pkg-scripts/postinstall << EOF
#!/bin/bash
/var/bluesky/helper.sh
exit 0
EOF

# make sure they are executable
chmod +x /tmp/pkg-scripts/*

PKG_LOCATION="/tmp/pkg/$APPNAME-$BLUESKY_VERSION.pkg"

# compress the scripts
(cd /tmp/pkg-scripts && find . | cpio -o --format odc --owner 0:80 | gzip -c) > /tmp/pkg-flat/Scripts
# compress the payload
(cd /tmp/pkg-payload && find . | cpio -o --format odc --owner 0:80 | gzip -c) > /tmp/pkg-flat/Payload
# create BOM file
(cd /tmp/pkg-payload && ls4mkbom -u 0 -g 80 .) > /tmp/pkg/.bom
(cd /tmp/pkg-payload && ls4mkbom -u 0 -g 80 .ssh | sed "s%^\.%\./\.ssh%") >> /tmp/pkg/.bom
mkbom -i /tmp/pkg/.bom /tmp/pkg-flat/Bom
rm -f /tmp/pkg/.bom
# package it up!!
(cd /tmp/pkg-flat && xar --compression none -cf "$PKG_LOCATION" ./*)
echo "macOS package has been built: $PKG_LOCATION"

RANDOM_DIR=$(uuidgen)
mkdir "/var/www/html/$RANDOM_DIR"
ln -s "$PKG_LOCATION" "/var/www/html/$RANDOM_DIR/"
cat >> /var/www/html/hooks/agent-links.php << EOF
<ul class="nav navbar-nav">
  <a href="$RANDOM_DIR/$APPNAME-$BLUESKY_VERSION.pkg" class="btn btn-default navbar-btn visible-sm visible-md visible-lg"><i class="glyphicon glyphicon-download-alt"></i> Download BlueSky Agent</a>
  <a href="$RANDOM_DIR/$APPNAME-$BLUESKY_VERSION.pkg" class="visible-xs btn btn-default navbar-btn btn-lg"><i class="glyphicon glyphicon-download-alt"></i> Download BlueSky Agent</a>
</ul>
EOF
