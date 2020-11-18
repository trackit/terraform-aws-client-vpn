#!/usr/bin/env bash

set -x

CWD=$(pwd)

if [ -d "$PKI_FOLDER_NAME" ]; then
    echo "PKI seems to be already configured."
else
    echo "Need to pull project"
    git clone https://github.com/OpenVPN/easy-rsa.git
    mkdir $PKI_FOLDER_NAME
    cp -r easy-rsa/easyrsa3/* $PKI_FOLDER_NAME
    rm -rf easy-rsa
    cd $PKI_FOLDER_NAME
    ./easyrsa init-pki
    echo $CERT_ISSUER | ./easyrsa build-ca nopass
    ./easyrsa build-server-full server nopass
    mkdir $KEY_SAVE_FOLDER
    cp pki/ca.crt $KEY_SAVE_FOLDER
    cp pki/issued/server.crt $KEY_SAVE_FOLDER
    cp pki/private/server.key $KEY_SAVE_FOLDER
    cd $KEY_SAVE_FOLDER
    # aws acm import-certificate --certificate-arn $ACM_SERVER_CERTIFICATE_ARN --certificate file://server.crt --private-key file://server.key --certificate-chain file://ca.crt --region $REGION
fi

# cd $CWD
# ${MODULE_PATH}/scripts/encrypt.sh