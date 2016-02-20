#!/usr/bin/env bash

source setup/functions.sh

if [ ! -f local.properties ]; then
  echo "local.properties not found!"
  exit 1
fi

source local.properties

# save our primary and only host name
export PRIMARY_HOSTNAME=$(get_default_hostname)
echo "Using primary hostname: ${PRIMARY_HOSTNAME}"

# install system stuff
source setup/system.sh

# install Java 8
source setup/java8.sh

# install MySQL
source setup/mysql.sh

# install rng for increased entropy
if [ ! -f /etc/default/rng-tools ];
then
    apt_install rng-tools
    [ ! -f /etc/default/rng-tools ] && exit 1
    echo "HRNGDEVICE=/dev/urandom" >>/etc/default/rng-tools
    restart_service rng-tools
fi

# global environment variables
cp export.sh /etc/profile.d/globalenv.sh

# cleanup
source setup/cleanup.sh

# custom script
[ -x data/custom.sh ] && source data/custom.sh

# last step: setup ssh
#source setup/ssh.sh
