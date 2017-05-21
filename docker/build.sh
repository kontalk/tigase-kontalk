#!/usr/bin/env bash
set -e

DATADIR=data
SSL_TRUSTED=trusted.pem
TIGASE_CONF=init.properties.in
HTTUPLOAD_CONF=config.yml.in

. tigase.properties

# check XMPP service name
if [ "${XMPP_SERVICE}" == "" ]; then
    echo "You must define a XMPP_SERVICE in the tigase.properties file."
    exit 1
fi

# check GPG key
if [ ! -f ${DATADIR}/server-private.key ] || [ ! -f ${DATADIR}/server-public.key ]; then
    echo "Not using provided GPG server key, I'll generate one automatically."
fi

# check GPG key
if [ ! -f ${DATADIR}/privatekey.pem ] || [ ! -f ${DATADIR}/certificate.pem ]; then
    echo "Not using provided X.509 certificate, I'll generate one automatically."
fi

# check trusted.pem
if [ ! -f ${DATADIR}/${SSL_TRUSTED} ];
then
    # copy default trusted certs bundle
    echo "Using default trusted certs bundle"
    cp ${DATADIR}/${SSL_TRUSTED}.dist ${DATADIR}/${SSL_TRUSTED}
fi

# check init.properties
if [ ! -f ${DATADIR}/${TIGASE_CONF} ];
then
    echo "Using default Tigase configuration"
    cp ${DATADIR}/${TIGASE_CONF}.dist ${DATADIR}/${TIGASE_CONF}
fi

# check config.yml (httpupload)
if [ ! -f ${DATADIR}/${TIGASE_CONF} ];
then
    echo "Using default HTTP upload component configuration"
    cp ${DATADIR}/${HTTUPLOAD_CONF}.dist ${DATADIR}/${HTTUPLOAD_CONF}
fi

docker-compose rm -f
docker-compose build
