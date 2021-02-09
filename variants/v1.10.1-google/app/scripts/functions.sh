#!/bin/sh

# Define some functions

output() {
    echo -e "[$( date '+%Y-%m-%d %H:%M:%S' )] $1"
}

error() {
    echo -e "[$( date '+%Y-%m-%d %H:%M:%S' )] $1" >&2
}

debug() {
    output "[DEBUG] $1"
}

signcert() {
    # This script signs a wildcard certificate
    # Guide from: https://certbot-dns-cloudflare.readthedocs.io/en/latest/
    # Guide from: https://www.eigenmagic.com/2018/03/14/howto-use-certbot-with-lets-encrypt-wildcard-certificates/

    output "Preparing to sign certificate"
    output "Using endpoint: $ENDPOINT"

    # When domain(s) are given as argument(s), use that
    domain=${1:-}
    [ -z "$domain" ] && error 'Domain not provided.' && exit 1
    output "Domain: $domain, *.$domain"
    output "DNS Alternative names to include in cert: $domain, *.$domain"

    force_renewal=${2:-}
    if [ ! -z "$force_renewal" ]; then
        flags='--force-renewal'
    else
        flags='--keep-until-expiring'
    fi

    output "Using rsa key size: $RSA_KEY_SIZE"

    if [ ! -z "$PLUGIN_DNS_PROVIDER" ]; then
        output "Using dns plugin $PLUGIN_DNS_PROVIDER, dns credentials file: $PLUGIN_DNS_CREDENTIALS_FILE, propagation: $PLUGIN_DNS_PROPAGATION_SECONDS"
    fi

    domain_admin_email="$DOMAIN_ADMIN_EMAIL_LOCALPART@$domain"
    output "Domain admin email will be: $domain_admin_email"

    # Sign / renew existing
    certbot certonly \
        --rsa-key-size "$RSA_KEY_SIZE" \
        --server "$ENDPOINT" \
        --non-interactive \
        --agree-tos \
        "$flags" \
        "--dns-$PLUGIN_DNS_PROVIDER" \
        "--dns-$PLUGIN_DNS_PROVIDER-credentials" "$PLUGIN_DNS_CREDENTIALS_FILE" \
        "--dns-$PLUGIN_DNS_PROVIDER-propagation-seconds" "$PLUGIN_DNS_PROPAGATION_SECONDS" \
        --cert-name "$domain" \
        --email "$domain_admin_email" \
        -d "$domain" \
        -d "*.$domain"
        #--dry-run \
        #--keep-until-expiring \
        #--expand \
        #--force-renewal \
}