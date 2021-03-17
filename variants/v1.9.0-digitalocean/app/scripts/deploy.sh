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
        output "Performing deploy stage"
        deploycert "$domain" || err=1
    else
        output "Skipping deploy stage"
    fi
done

[ -z "$err" ] && output "Successfully deployed all cert-key pairs" || output "Failed to deploy one or more cert-key pairs"
