#!/bin/sh

# This script copies cert-key pair to the cert store /certs

cd "$( realpath $(dirname "$0") )"
source ./init.sh

err=
for domain in $DOMAINS
do
    if [ -n "$DEPLOY_CERTS" ]; then
        # 2. Deploy certs to nginx and docker-gen
        output "Deploying $domain signed cert and key to /certs"
        key="$LETSENCRYPT_DIR/live/$domain/privkey.pem"
        dest_key="/certs/$domain.key"
        cert="$LETSENCRYPT_DIR/live/$domain/cert.pem"
        dest_cert="/certs/$domain.crt"
        echo "Copying key $key to $dest_key."
        cp "$key" "$dest_key" && chown root:root "$dest_key" && chmod 440 "$dest_key"
        [ ! $? = 0 ] && err=1
        echo "Copying cert $cert to $dest_cert."
        cp "$cert" "$dest_cert" && chown root:root "$dest_cert" && chmod 440 "$dest_cert"
        [ ! $? = 0 ] && err=1
    fi
done

[ -z "$err" ] && echo "Successfully deployed all cert-key pairs" || echo "Failed to deploy one or more cert-key pairs"
