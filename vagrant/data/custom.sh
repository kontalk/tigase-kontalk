#!/bin/bash

source setup/functions.sh

echo "Removing unused packages"
apt_get_quiet remove --purge bash-completion

echo "Customizing environment"
cp data/bash_aliases /root/.bash_aliases
cp /etc/bash.bashrc /root/.bashrc
tools/editconf.py /root/.bashrc \
    force_color_prompt=yes
