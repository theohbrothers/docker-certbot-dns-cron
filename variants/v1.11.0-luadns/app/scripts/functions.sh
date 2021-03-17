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

    # When domain(s) are given as argument(s), use that
    local domain=${1:-}
    [ -z "$domain" ] && error 'domain not provided.' && exit 1
    local force_renewal=${2:-}
    local flags=
    if [ ! -z "$force_renewal" ]; then
        flags='--force-renewal'
    else
        flags='--keep-until-expiring'
    fi

    output "Preparing to sign certificate"
    output "Using endpoint: $ENDPOINT"
    output "Domain: $domain, *.$domain"
    output "DNS Alternative names to include in cert: $domain, *.$domain"
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

deploycert() {
    # When domain(s) are given as argument(s), use that
    local domain=${1:-}
    [ -z "$domain" ] && error 'domain not provided.' && exit 1

    output "Deploying $domain signed cert and key to /certs"

    # Deploy certs to /certs
    key="$LETSENCRYPT_DIR/live/$domain/privkey.pem"
    dest_key="/certs/$domain.key"
    cert="$LETSENCRYPT_DIR/live/$domain/cert.pem"
    dest_cert="/certs/$domain.crt"
    fullchain_cert="$LETSENCRYPT_DIR/live/$domain/fullchain.pem"
    dest_fullchain="/certs/$domain.fullchain.pem"
    chain_cert="$LETSENCRYPT_DIR/live/$domain/chain.pem"
    dest_chain="/certs/$domain.chain.pem"

    local err=
    output "Copying key $key to $dest_key."
    cp "$key" "$dest_key" && chown root:root "$dest_key" && chmod 440 "$dest_key" || err=1
    output "Copying cert $cert to $dest_cert."
    cp "$cert" "$dest_cert" && chown root:root "$dest_cert" && chmod 440 "$dest_cert" || err=1
    output "Copying fullchain $fullchain_cert to $dest_fullchain."
    cp "$fullchain_cert" "$dest_fullchain" && chown root:root "$dest_fullchain" && chmod 440 "$dest_fullchain" || err=1
    output "Copying chain $chain_cert to $dest_chain."
    cp "$chain_cert" "$dest_chain" && chown root:root "$dest_chain" && chmod 440 "$dest_chain" || err=1

    [ -z "$err" ] && return 0 || return 1
}

sendsignal() {
    local target_container_name=${1:-}
    local signal=${2:-} # E.g. "SIGHUP", "SIGTERM"
    [ -z "$target_container_name" ] && error 'target_container_name not provided' && return 1
    [ -z "$signal" ] && error 'signal not provided' && return 1

    # Ubuntu: nc -U /tmp/docker.sock
    # Alpine: nc local:/tmp/docker.sock
    # Get container name from env var, escaping regex special chars. Typically not needed, but needed only for complex names
    target_container_name_regex_escaped=$(     [ -n "$target_container_name" ] && echo "$target_container_name" | sed 's/\([(){}+*?.^$<>=|]\)/\\\1/g' | sed 's/\(\[\)/\\\1/g' | sed 's/\(\]\)/\\\1/g'     ||     echo "docker-gen"      )
    sed_capture=$( cat - <<EOF
s/.*"Id":"([0-9a-f]+)","Names":\["\/$target_container_name_regex_escaped[^"]*"\].*/\1/g
EOF
)
    target_container_id=$( echo -e "GET /containers/json HTTP/1.0\r\n" | nc local:/tmp/docker.sock | sed -r "$sed_capture" | grep -E '^[0-9a-f]+$' )
    if [ -n "$target_container_id" ]; then
        occurances=$( echo "$target_container_id" | wc -l )
        output "Reloading target container $target_container_name of id: $target_container_id with signal $signal"
        echo -e "POST /containers/$target_container_id/kill?signal=$signal HTTP/1.0\r\n" | nc local:/tmp/docker.sock >/dev/null
        [ $? = 0 ] && return 0 || return 1
    else
        error "Cannot reload target container $target_container_name. Reason: failed to get container id!"
        return 1
    fi
}
