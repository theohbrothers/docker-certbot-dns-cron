#!/bin/sh

# This script copies cert-key pair to the cert store /certs

cd "$( realpath $(dirname "$0") )"
source ./init.sh

if [ $# -gt 0 ]; then
    # Any remaining arguments will be used as domains
    DOMAINS=$@
    output "Using arguments as domains: $DOMAINS"
else
    output "Using environment variable \$DOMAINS as domains: $DOMAINS"
fi

# Stop here if no domains were given as arguments
[ -z "$DOMAINS" ] && error 'Domain(s) not provided.' && exit 1

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
        fullchain_cert="$LETSENCRYPT_DIR/live/$domain/fullchain.pem"
        dest_fullchain="/certs/$domain.fullchain.pem"
        chain_cert="$LETSENCRYPT_DIR/live/$domain/chain.pem"
        dest_chain="/certs/$domain.chain.pem"
        echo "Copying key $key to $dest_key."
        cp "$key" "$dest_key" && chown root:root "$dest_key" && chmod 440 "$dest_key"
        [ ! $? = 0 ] && err=1
        echo "Copying cert $cert to $dest_cert."
        cp "$cert" "$dest_cert" && chown root:root "$dest_cert" && chmod 440 "$dest_cert"
        [ ! $? = 0 ] && err=1
        echo "Copying fullchain $fullchain_cert to $dest_fullchain."
        cp "$fullchain_cert" "$dest_fullchain" && chown root:root "$dest_fullchain" && chmod 440 "$dest_fullchain"
        [ ! $? = 0 ] && err=1
        echo "Copying chain $chain_cert to $dest_chain."
        cp "$chain_cert" "$dest_chain" && chown root:root "$dest_chain" && chmod 440 "$dest_chain"
        [ ! $? = 0 ] && err=1
    fi
done

[ -z "$err" ] && echo "Successfully deployed all cert-key pairs" || echo "Failed to deploy one or more cert-key pairs"
