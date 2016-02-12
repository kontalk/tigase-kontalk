#!/bin/bash
# Setup SSH server

source setup/functions.sh

if [ -n "${SSH_PORT}" ]; then
    echo "Setting SSH server port to ${SSH_PORT}"

    tools/editconf.py /etc/ssh/sshd_config -s "Port=${SSH_PORT}"
    ufw_allow ${SSH_PORT}
    
    hide_output service ssh reload
fi
