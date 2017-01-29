#!/usr/bin/env bash
set -e

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

    touch ${HOME}/.databasesetup
fi

dockerize \
 -template /tmp/init.properties.dist:${HOME}/kontalk/tigase-kontalk/etc/init.properties \
 -stdout ${HOME}/kontalk/tigase-kontalk/logs/tigase-console.log \
 -stderr ${HOME}/kontalk/tigase-kontalk/logs/tigase.log.0 \
 -wait tcp://db:3306 \
 ${HOME}/kontalk/tigase-kontalk/scripts/tigase.sh run ${HOME}/kontalk/tigase-kontalk/etc/tigase.conf
