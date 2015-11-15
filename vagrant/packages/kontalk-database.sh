#!/bin/bash

# create database if needed
if [ ! -f $HOME/.databasesetup ];
then
    echo "Creating database"
    echo "CREATE USER 'kontalk'@'localhost' IDENTIFIED BY 'kontalk'" | mysql -uroot -proot
    echo "CREATE DATABASE kontalk /*!40100 DEFAULT CHARACTER SET utf8mb4 */" | mysql -uroot -proot
    echo "GRANT ALL ON kontalk.* TO 'kontalk'@'localhost'" | mysql -uroot -proot
    echo "FLUSH PRIVILEGES" | mysql -uroot -proot

    touch $HOME/.databasesetup
fi
