#!/usr/bin/env bash

/vagrant/packages/sysupgrade.sh
/vagrant/packages/java8.sh
/vagrant/packages/mysql.sh

# install rng for increased entropy
if [ ! -f /etc/default/rng-tools ];
then
    apt-get install -qq -y rng-tools &&
    echo "HRNGDEVICE=/dev/urandom" >>/etc/default/rng-tools
    systemctl restart rng-tools
fi

# global environment variables
cp /vagrant/export.sh /etc/profile.d/vagrant.sh
