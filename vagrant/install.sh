#!/bin/sh

/vagrant/packages/tigase-kontalk.sh &&
/vagrant/packages/kontalk-database.sh &&
/vagrant/packages/kontalk-keys.sh &&
/vagrant/packages/kontalk-config.sh
