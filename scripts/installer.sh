#!/bin/bash
# Helper installation scripts for rapid download and building of the Kontalk server
# It will install everything in the directory provided as a parameter (default: $PWD/kontalk-server)
# A second parameter can be used to use a specific branch
# To be used as a standalone script like this:
# wget -qq -O - url_to_installer.sh | bash

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 1; }
try() { "$@" || die "cannot $*"; }
check_for() { which $@ >/dev/null || die "Unable to locate $*"; }

check_programs()
{
    # check for git
    check_for git
    # check for maven
    check_for mvn
}

# check for needed programs
check_programs

WORKDIR="$1"
BRANCH="$2"

if [ "$WORKDIR" == "" ]; then
    WORKDIR="$PWD/kontalk-server"
fi

if [ -a "$WORKDIR" ]; then
    die "Working directory $WORKDIR already exists."
fi

cd $(dirname "$WORKDIR")

yell "Downloading sources"

if [ "$BRANCH" == "" ]; then
    BRANCH="master"
fi

try git clone -n https://github.com/kontalk/tigase-kontalk.git ${WORKDIR} && (cd ${WORKDIR} && git checkout ${BRANCH} && git submodule update --init)

cd kontalk-server
mvn install
