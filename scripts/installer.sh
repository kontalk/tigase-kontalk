#!/bin/bash
# Helper installation scripts for rapid download and building of the Kontalk server
# it will install everything in the directory provided as a parameter (default: $PWD/kontalk-server)
# To be used as a standalone script like this:
# wget -O - url_to_installer.sh | bash

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

if [ "$WORKDIR" == "" ]; then
    WORKDIR="$PWD/kontalk"
fi

if [ -a "$WORKDIR" ]; then
    die "Working directory $WORKDIR already exists."
fi

try mkdir -p "$WORKDIR"
cd "$WORKDIR"

yell "Cloning repositories"

try git clone https://github.com/kontalk/tigase-kontalk.git
try git clone https://github.com/kontalk/tigase-extension.git
try git clone https://github.com/kontalk/tigase-server.git

cd tigase-kontalk
mvn install
