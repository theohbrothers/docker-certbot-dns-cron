#!/bin/sh

DIR=/etc/letsencrypt

# Check for domain(s) as argument(s)
[ $# = 0 ] && echo 'Please specify at least one domain as an argument.' && exit 1

for domain in "$@"
do
    cert="$DIR/live/$domain/cert.pem"
    [ ! -f "$cert" ] && echo "No such certificate $cert" && exit 1
    echo "Found certificate: $cert"
    openssl x509 -in "$cert" -text
done