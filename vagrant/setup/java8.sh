#!/bin/sh

source setup/functions.sh

if which java >/dev/null; then
    echo "Skipping Java installation"
else
    echo "Installing Oracle JDK 8"
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 >/dev/null
    apt_get_quiet update
    echo debconf shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | /usr/bin/debconf-set-selections
    apt_install -qq --yes oracle-java8-installer >/dev/null
    yes "" | apt_install -f
fi
