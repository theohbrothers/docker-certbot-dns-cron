#!/bin/sh

DIR=/etc/letsencrypt

# Check for domain(s) as argument(s)
[ $# = 0 ] && echo 'Please specify at least one domain as an argument.' && exit 1

for domain in "$@"
do
    key="$DIR/live/$domain/privkey.pem"
    [ ! -f "$key" ] && echo "No such key $key" && exit 1
    echo "Found key: $key"
    openssl rsa -text -noout -in "$key"
done