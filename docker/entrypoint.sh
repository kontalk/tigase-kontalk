#!/usr/bin/env bash
set -e

# create database if needed
if [ ! -f ${HOME}/.databasesetup ];
then
    echo "Creating database"

    # create tigase database objects
    cd ${HOME}/kontalk/tigase-server &&
    rm -f jars/*.jar &&
    cp ../tigase-kontalk/jars/*.jar jars/ &&
    scripts/db-create-mysql.sh -y ${MYSQL_USER} ${MYSQL_PASSWORD} ${MYSQL_DATABASE}
    cd - >/dev/null

    # create kontalk database objects
    for SCRIPT in ${HOME}/kontalk/tigase-kontalk/docker/data/cleanup.sql ${HOME}/kontalk/tigase-extension/data/*.sql;
    do
        mysql -h db --port 3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < ${SCRIPT}
    done

    touch ${HOME}/.databasesetup
fi

dockerize \
 -template /tmp/init.properties.dist:/home/kontalk/kontalk/tigase-kontalk/etc/init.properties \
 -stdout /home/kontalk/kontalk/tigase-kontalk/logs/tigase-console.log \
 -stderr /home/kontalk/kontalk/tigase-kontalk/logs/tigase.log.0 \
 -wait tcp://db:3306 \
 /home/kontalk/kontalk/tigase-kontalk/scripts/tigase.sh run /home/kontalk/kontalk/tigase-kontalk/etc/tigase.conf
