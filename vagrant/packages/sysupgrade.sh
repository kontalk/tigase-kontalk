#!/bin/sh

echo "Upgrading system"
apt-get update -qq &&
apt-get dist-upgrade -qq -y
