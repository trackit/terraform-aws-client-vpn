#!/usr/bin/env bash
set -x 

LOCK_FILE_NAME=decrypt_lock

terraform output || exit

if [ -z "$KMS_SOPS_ARN" ]; then
    KMS_SOPS_ARN=$(terraform output | grep 'kms_sops_arn' | sed 's/kms_sops_arn = //g')
    export SOPS_KMS_ARN=$KMS_SOPS_ARN
fi

function encrypt {
    PKI_FOLDER_NAME=$1

    tar zcvf $PKI_FOLDER_NAME.tar $PKI_FOLDER_NAME \
        && rm -rf $PKI_FOLDER_NAME \
        && (sops -e -i $PKI_FOLDER_NAME.tar || (tar zxvf $PKI_FOLDER_NAME.tar && $PKI_FOLDER_NAME.tar))\
        && echo "Releasing $LOCK_FILE_NAME"\
        && (test -f $LOCK_FILE_NAME && rm $LOCK_FILE_NAME)
}

if [ -n "$PKI_FOLDER_NAME" ]; then
    encrypt $PKI_FOLDER_NAME
else 
    for i in $(ls | grep 'pki_' | grep -v '.tar');
    do
        encrypt $i
    done
fi