#!/usr/bin/env bash
set -e

# create SSL certificate if needed
SSL_CERT="${HOME}/kontalk/tigase-kontalk/certs/${XMPP_SERVICE}.pem"
if [ ! -f ${SSL_CERT} ];
then
    echo "Generating SSL certificate"
    openssl req -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${XMPP_SERVICE}" -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
    mkdir -p $(dirname ${SSL_CERT})
    cat cert.pem key.pem >${SSL_CERT} &&
    rm cert.pem key.pem
fi

# create GPG key if needed
if [ ! -f ${HOME}/.gpgsetup ];
then
    echo "Generating GPG key pair"
    KEY_USERID="kontalk-${RANDOM}@${XMPP_SERVICE}"
    gpg2 --batch --gen-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 2048
Subkey-Type: 1
Subkey-Length: 2048
Name-Real: Kontalk server
Name-Email: ${KEY_USERID}
Expire-Date: 0
EOF

    # get GPG key fingerprint
    export FINGERPRINT=$(gpg2 --with-colons --with-fingerprint --list-secret-keys ${KEY_USERID} | grep fpr | head -n 1 | awk '{print $10}' FS=:)
    if [ "${FINGERPRINT}" == "" ]; then
        echo "GPG key not found!"
        exit 1
    fi

    touch ${HOME}/.gpgsetup
fi

# create database if needed
if [ ! -f ${HOME}/.databasesetup ];
then
    echo "Waiting for database"
    wait-for-it db:3306 -q -t 0
    echo "Creating database"

    # create tigase database objects
    cd ${HOME}/kontalk/tigase-server &&
    rm -f jars/*.jar &&
    cp ../tigase-kontalk/jars/*.jar jars/ &&
    java -cp "jars/*" tigase.util.DBSchemaLoader -dbHostname db -dbType mysql -schemaVersion 7-1 \
        -dbName ${MYSQL_DATABASE} -dbUser ${MYSQL_USER} -dbPass ${MYSQL_PASSWORD} \
        -logLevel ALL -useSSL false
    java -cp "jars/*" tigase.util.DBSchemaLoader -dbHostname db -dbType mysql -schemaVersion 7-1 \
        -dbName ${MYSQL_DATABASE} -dbUser ${MYSQL_USER} -dbPass ${MYSQL_PASSWORD} \
        -logLevel ALL -useSSL false \
        database/mysql-pubsub-schema-3.0.0.sql
    cd - >/dev/null

    # create kontalk database objects
    for SCRIPT in ${HOME}/kontalk/tigase-kontalk/docker/data/cleanup.sql ${HOME}/kontalk/tigase-extension/data/*.sql;
    do
        mysql -h db --port 3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < ${SCRIPT}
    done

    # replace our server entry
    mysql -h db --port 3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} <<EOF
REPLACE INTO servers (fingerprint, host, enabled) VALUES('${FINGERPRINT}', '${XMPP_SERVICE}', 1);
EOF

    touch ${HOME}/.databasesetup
fi

# export keys to file
gpg2 --export ${FINGERPRINT} >${HOME}/kontalk/tigase-kontalk/server-public.key
gpg2 --export-secret-key ${FINGERPRINT} >${HOME}/kontalk/tigase-kontalk/server-private.key

dockerize \
 -template /tmp/init.properties.dist:${HOME}/kontalk/tigase-kontalk/etc/init.properties \
 -stdout ${HOME}/kontalk/tigase-kontalk/logs/tigase-console.log \
 -stderr ${HOME}/kontalk/tigase-kontalk/logs/tigase.log.0 \
 -wait tcp://db:3306 \
 ${HOME}/kontalk/tigase-kontalk/scripts/tigase.sh run ${HOME}/kontalk/tigase-kontalk/etc/tigase.conf
