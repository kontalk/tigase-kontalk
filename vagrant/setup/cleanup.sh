#!/bin/bash
# Cleanup script

source setup/functions.sh

echo "Cleaning up"
apt_get_quiet clean
