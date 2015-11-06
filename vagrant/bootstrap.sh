#!/usr/bin/env bash

/vagrant/packages/sysupgrade.sh &&
/vagrant/packages/java8.sh &&
/vagrant/packages/mysql.sh &&

echo "source /vagrant/export.sh" >> /home/vagrant/.bashrc
