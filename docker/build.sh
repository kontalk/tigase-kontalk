#!/usr/bin/env bash
set -e

DATADIR=data
SSL_TRUSTED=trusted.pem

. tigase.properties

# check XMPP service name
if [ "${XMPP_SERVICE}" == "" ]; then
    echo "You must define a XMPP_SERVICE in the tigase.properties file."
    exit 1
fi

# check fingerprint
if [ "${FINGERPRINT}" == "" ]; then
    echo "Not using existing GPG server key, I'll generate one automatically."
fi

# check trusted.pem
if [ ! -f ${DATADIR}/${SSL_TRUSTED} ];
then
    # copy default trusted certs bundle
    echo "Using default trusted certs bundle"
    cp ${DATADIR}/${SSL_TRUSTED}.dist ${DATADIR}/${SSL_TRUSTED}
fi

# TODO check server-[public|private].key

docker-compose rm -f
docker-compose up
