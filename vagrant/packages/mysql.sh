#!/bin/bash

debconf-set-selections <<< 'mysql-server mysql-server/root_password password root' &&
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root' &&
apt-get install -qq -y mysql-server
