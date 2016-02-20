#!/bin/bash

# get GPG key fingerprint
FINGERPRINT=$(gpg2 --with-colons --with-fingerprint --list-secret-keys | grep fpr | awk '{print $10}' FS=:)
if [ "${FINGERPRINT}" == "" ]; then
    echo "GPG key not found!"
    exit 1
fi

echo "Using GPG key ${FINGERPRINT}"

# export keys to file
gpg2 --export ${FINGERPRINT} >${HOME}/tigase-kontalk/server-public.key
gpg2 --export-secret-key ${FINGERPRINT} >${HOME}/tigase-kontalk/server-private.key

# fill the servers table
sql_as_user <<EOF
REPLACE INTO servers (fingerprint, host, enabled) VALUES('${FINGERPRINT}', '$(hostname -f)', 1);
EOF

# create configuration
sed \
 -e "s/@FINGERPRINT@/${FINGERPRINT}/" \
 -e "s/@HOSTNAME@/$(hostname -f)/" \
 -e "s/@DBNAME@/${MYSQL_USER_NAME}/" \
 -e "s/@DBUSER@/${MYSQL_USER_NAME}/" \
 -e "s/@DBPASS@/${MYSQL_USER_PASSWORD}/" \
 conf/init.properties.dist >${HOME}/tigase-kontalk/etc/init.properties
