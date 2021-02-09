#!/bin/sh

DIR=/etc/letsencrypt

# Check for domain(s) as argument(s)
[ $# = 0 ] && echo 'Please specify at least one domain as an argument.' && exit 1

for domain in "$@"
do
    certbot delete --cert-name "$domain"
done