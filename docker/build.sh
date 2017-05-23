#!/usr/bin/env bash
set -e

MODE=$1

if [ "${MODE}" != "dev" ] && [ "${MODE}" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

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
    if [ "$MODE" == "dev" ]; then
        echo "Not using provided GPG server key, I'll generate one automatically."
    else
        echo "You must provide an existing GPG key for the server."
        echo "Please export it into ${DATADIR}/server-private.key and ${DATADIR}/server-public.key"
        exit 1
    fi
fi

# check GPG key
if [ ! -f ${DATADIR}/privatekey.pem ] || [ ! -f ${DATADIR}/certificate.pem ]; then
    if [ "$MODE" == "dev" ]; then
        echo "Not using provided X.509 certificate, I'll generate one automatically."
    else
        echo "You must provide an existing X.509 certificate for the server."
        echo "Please copy it into ${DATADIR}/privatekey.pem and ${DATADIR}/certificate.pem"
        echo "An optional CA chain can be provided into ${DATADIR}/cachain.pem"
        exit 1
    fi
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

echo "Building images"
$(dirname $0)/tigase/build.sh >/dev/null
$(dirname $0)/httpupload/build.sh >/dev/null

echo "Resetting containers"
docker-compose rm -f
docker-compose build
