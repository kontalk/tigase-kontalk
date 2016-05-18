#!/bin/bash

# use production branch
BRANCH="production"

echo "Installing Kontalk from ${BRANCH} branch"

echo "Installing system dependencies"
apt_install gnupg2 libgpgme11-dev libkyotocabinet16 libkyotocabinet-dev gcc g++ maven git make

# switch to home directory
OLDCWD=$PWD
cd

# install jkyotocabinet
if [ ! -f .jkyotosetup ];
then
    wget -q http://fallabs.com/kyotocabinet/javapkg/kyotocabinet-java-1.24.tar.gz >/dev/null &&
    tar -xzf kyotocabinet-java-1.24.tar.gz &&
    cd kyotocabinet-java-1.24 &&
    hide_output ./configure --prefix=/usr
    hide_output make
    hide_output sudo make install
    cd .. &&
    rm -fR kyotocabinet-java-1.24 kyotocabinet-java-1.24.tar.gz &&

    touch .jkyotosetup
fi

# install Kontalk server
if [ ! -d tigase-kontalk ];
then
    echo "Installing Kontalk server"
    git clone -b "${BRANCH}" "https://github.com/kontalk/tigase-server" &&
    git clone -b "${BRANCH}" "https://github.com/kontalk/tigase-extension" &&
    git clone "https://github.com/kontalk/tigase-kontalk" &&
    cd tigase-kontalk &&
    hide_output mvn install
    ln -sf /usr/lib/libjkyotocabinet.so jars/libjkyotocabinet.so
    cd ..
fi

cd ${OLDCWD}

# allow XMPP port
ufw_allow xmpp-client
