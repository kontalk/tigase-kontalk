#!/bin/bash

# get GPG key fingerprint
FINGERPRINT=$(gpg2 --with-colons --with-fingerprint --list-secret-keys | grep fpr | awk '{print $10}' FS=:)
if [ "${FINGERPRINT}" == "" ]; then
    echo "GPG key not found!"
    exit 1
fi

echo "Using GPG key ${FINGERPRINT}"

sed \
 -e "s/@FINGERPRINT@/${FINGERPRINT}/" \
 -e "s/@HOSTNAME@/$(hostname -f)/" \
 -e "s/@DBNAME@/kontalk/" \
 -e "s/@DBUSER@/kontalk/" \
 -e "s/@DBPASS@/kontalk/" \
 /vagrant/init.properties.dist >$HOME/tigase-kontalk/etc/init.properties
