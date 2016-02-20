#!/bin/bash

source setup/functions.sh

echo "Installing MySQL"
debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}" &&
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" &&
apt_install mysql-server
