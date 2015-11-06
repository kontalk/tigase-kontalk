#!/bin/bash

# use production branch
BRANCH="production"

echo "Installing Kontalk from ${BRANCH} branch"

echo "Installing system dependencies"
sudo apt-get install -qq -y gnupg2 libgpgme11-dev maven git &&

# install gnupg-for-java
git clone -b "${BRANCH}" "https://github.com/kontalk/gnupg-for-java.git" &&
cd gnupg-for-java &&
mvn install &&
cd .. &&
rm -fR gnupg-for-java &&

# install Kontalk server
git clone -b "${BRANCH}" "https://github.com/kontalk/tigase-server" &&
git clone -b "${BRANCH}" "https://github.com/kontalk/tigase-extension" &&
git clone "https://github.com/kontalk/tigase-kontalk" &&
cd tigase-kontalk &&
mvn install
