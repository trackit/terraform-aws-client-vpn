#!/usr/bin/env bash
set -x

if [ -z "$CONCURRENCY" ]; then
    # This is to mitigate concurrency.
    [ -n "$SLEEP_TIME" ] && sleep $SLEEP_TIME

    LOCK_FILE_NAME=decrypt_lock
    until [ "$(test -f $LOCK_FILE_NAME && echo true || echo false)" = "false" ]
    do
        echo "Waiting for $LOCK_FILE_NAME file to be released (deleted)."
        sleep 1
    done

    touch $LOCK_FILE_NAME
fi

terraform output || exit

if [ -z "$KMS_SOPS_ARN" ]; then
    TERRAFORM_OUTPUT=$(terraform output)

    KMS_SOPS_ARN=$(echo $TERRAFORM_OUTPUT | grep 'kms_sops_arn' | sed 's/kms_sops_arn = //g')
    PKI_FOLDER=$(echo $TERRAFORM_OUTPUT | grep 'pki_folder_name' | sed 's/pki_folder_name = //g')

    export SOPS_KMS_ARN=$KMS_SOPS_ARN
fi

function decrypt {
    PKI_FOLDER_NAME=$1
    if [ -f "$PKI_FOLDER_NAME.tar" ]; then
        sops -d -i $PKI_FOLDER_NAME.tar \
            && tar zxvf $PKI_FOLDER_NAME.tar \
            && rm $PKI_FOLDER_NAME.tar
    else
        echo "Already decrypted 👍"
    fi
}


if [ -n "$PKI_FOLDER_NAME" ]; then
    decrypt $PKI_FOLDER_NAME
else 
    for i in $(ls | grep 'pki_' | grep '.tar' | sed 's/.tar//g');
    do
        decrypt $i
    done
fi