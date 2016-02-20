#!/bin/bash

# create database if needed
if [ ! -f ${HOME}/.databasesetup ];
then
    echo "Creating database"
    sql_as_root <<EOF
CREATE USER '${MYSQL_USER_NAME}'@'localhost' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
CREATE DATABASE ${MYSQL_USER_NAME} /*!40100 DEFAULT CHARACTER SET utf8mb4 */;
GRANT ALL ON ${MYSQL_USER_NAME}.* TO '${MYSQL_USER_NAME}'@'localhost';
GRANT SELECT, INSERT, UPDATE ON mysql.proc TO ${MYSQL_USER_NAME}@'localhost';
FLUSH PRIVILEGES;
EOF

    # create tigase database objects
    cd ${HOME}/tigase-server &&
    rm -f jars/*.jar &&
    cp ../tigase-kontalk/jars/*.jar jars/ &&
    hide_output scripts/db-create-mysql.sh -y ${MYSQL_USER_NAME} ${MYSQL_USER_PASSWORD} ${MYSQL_USER_NAME}
    cd - >/dev/null

    # create kontalk database objects
    for SCRIPT in ${HOME}/tigase-extension/data/*.sql;
    do
        sql_as_user < ${SCRIPT}
    done

    touch ${HOME}/.databasesetup
fi
