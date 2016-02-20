#!/bin/bash

# create SSL certificate if needed
SSL_CERT="${HOME}/tigase-kontalk/certs/$(hostname -f).pem"
if [ ! -f ${SSL_CERT} ];
then
    echo "Generating SSL certificate"
    hide_output openssl req -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$(hostname -f)" -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
    mkdir -p $(dirname ${SSL_CERT})
    cat cert.pem key.pem >${SSL_CERT} &&
    rm cert.pem key.pem
fi

# create GPG key if needed
if [ ! -f ${HOME}/.gpgsetup ];
then
    echo "Generating GPG key pair"
    hide_output gpg2 --batch --gen-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 2048
Subkey-Type: 1
Subkey-Length: 2048
Name-Real: Kontalk server
Name-Email: kontalk@$(hostname -f)
Expire-Date: 0
EOF

    touch ${HOME}/.gpgsetup
fi
