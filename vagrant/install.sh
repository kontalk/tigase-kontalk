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

# download and build Kontalk server
source setup/tigase-kontalk.sh

# create Kontalk database
source setup/kontalk-database.sh

# create server keys and certificate
source setup/kontalk-keys.sh

# configure Kontalk server
source setup/kontalk-config.sh
