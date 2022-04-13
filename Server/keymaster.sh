#!/bin/bash

# BlueSkyConnect macOS SSH tunnel
#
# receives what should be a public key for addition to BlueSky
# checks it and then hands it off to gatekeeper by way of inoticoming
#
# See https://github.com/BlueSkyTools/BlueSkyConnect
# Licensed under the Apache License, Version 2.0

DATA_UP="$1"
TMP_NAME=$(uuidgen)

# Attempt to decrypt the client and admin keys. Whichever one passes, note the type. If both fail, reject it.
if openssl smime -decrypt -inform PEM -inkey /usr/local/bin/BlueSkyConnect/Server/blueskyclient.key -out "/tmp/$TMP_NAME.pub" <<< "$DATA_UP"; then
  TARGET_LOC="bluesky"
elif openssl smime -decrypt -inform PEM -inkey /usr/local/bin/BlueSkyConnect/Server/blueskyadmin.key -out "/tmp/$TMP_NAME.pub" <<< "$DATA_UP"; then
  TARGET_LOC="admin"
else
  echo "Invalid"
  exit 0 # should this be a non-zero exit code?
fi

KEY_VALID=$(ssh-keygen -l -f "/tmp/$TMP_NAME.pub")
# $KEY_VALID contains the hash that will appear in auth.log
# 256 SHA256:Sahm5Rft8nvUQ5425YgrrSNGosZA4hf/P2NmhRr2NL0 uploaded@1510761187 sysadmin@Sidekick.local (ECDSA)
# FINGER_PRINT=$(awk '{ print $2 }' <<< "$KEY_VALID" | cut -d : -f 2)
if [[ $KEY_VALID = *"ED25519"* ]] || [[ $KEY_VALID = *"RSA"* ]]; then
  mv "/tmp/$TMP_NAME.pub" "/home/$TARGET_LOC/newkeys/$TMP_NAME.pub"
  echo "Installed"
  if [[ $TARGET_LOC = "admin" ]] && [[ -x /usr/local/bin/BlueSkyConnect/Server/emailHelper.sh ]]; then
    # email the subscriber about it
    KEY_ID=$(awk '{ print $NF }' "/tmp/$TMP_NAME.pub")
    /usr/local/bin/BlueSkyConnect/Server/emailHelper.sh \
      "BlueSky Admin Key Registered" \
      "A new admin key with identifier $KEY_ID was registered in your server. If you did not expect this, please invoke Emergency Stop."
  fi
else
  # rm -f /tmp/$TMP_NAME.pub
  echo "Invalid"
fi

exit 0
