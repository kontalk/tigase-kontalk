#!/bin/bash

# use production branch
BRANCH="production"

echo "Installing Kontalk from ${BRANCH} branch"

echo "Installing system dependencies"
sudo apt-get install -qq -y gnupg2 libgpgme11-dev maven git || exit 1

# install gnupg-for-java
if [ ! -f .gpgjsetup ];
then
    echo "Installing gnupg-for-java"
    git clone -b "${BRANCH}" "https://github.com/kontalk/gnupg-for-java.git" &&
    cd gnupg-for-java &&
    mvn -q install || exit 1
    cd .. &&
    rm -fR gnupg-for-java &&

    touch .gpgjsetup
fi

# install Kontalk server
if [ ! -d tigase-kontalk ];
then
    echo "Installing Kontalk server"
    git clone -b "${BRANCH}" "https://github.com/kontalk/tigase-server" &&
    git clone -b "${BRANCH}" "https://github.com/kontalk/tigase-extension" &&
    git clone "https://github.com/kontalk/tigase-kontalk" &&
    cd tigase-kontalk &&
    mvn -q install || exit 1
    cd ..
fi
