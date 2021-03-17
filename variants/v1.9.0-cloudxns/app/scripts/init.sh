#!/bin/sh

set -a

IN_SCRIPT=1

BASE_DIR=$( realpath $(dirname "$0") )
cd "$BASE_DIR"
source vars.sh
source functions.sh

LETSENCRYPT_DIR=/etc/letsencrypt

[ -n "$DEBUG" ] #&& set -x && set -u

STAGING=${STAGING:-}

# Get endpoint
ENDPOINT='https://acme-v02.api.letsencrypt.org/directory'
[ -n "$STAGING" ] && ENDPOINT='https://acme-staging-v02.api.letsencrypt.org/directory'

# Get RSA key size
RSA_KEY_SIZE=${RSA_KEY_SIZE:-4096}

# Get domains to sign cert for
DOMAINS=${DOMAINS:-}
DOMAINS=$(  ( [ -n "$DOMAINS" ] && echo "$DOMAINS" | tr ';' ' ' ) || ( [ -n "$DOMAINS_FILE" ] && cat "$DOMAINS_FILE" )  2>/dev/null  )
[ -z "$DOMAINS" ] && error "Domains could not be found from env var \$DOMAINS or \$DOMAINS_FILE. Cannot sign cert."

# Get domain admin email's localpart
DOMAIN_ADMIN_EMAIL_LOCALPART=${DOMAIN_ADMIN_EMAIL_LOCALPART:-admin}

# Get certbot plugin vars
PLUGIN_DNS_PROVIDER=${PLUGIN_DNS_PROVIDER:-}
if [ ! -z "$PLUGIN_DNS_PROVIDER" ]; then
    PLUGIN_DNS_CREDENTIALS_FILE=${PLUGIN_DNS_CREDENTIALS_FILE:-}
    PLUGIN_DNS_PROPAGATION_SECONDS=${PLUGIN_DNS_PROPAGATION_SECONDS:-10}
    # Check certbot plugin credential file exists
    [ ! -f "$PLUGIN_DNS_CREDENTIALS_FILE" ] && error "Certbot plugin credential file in \$PLUGIN_DNS_CREDENTIALS_FILE variable of value '$PLUGIN_DNS_CREDENTIALS_FILE' does not point to a file!"
fi

DEPLOY_CERTS=${DEPLOY_CERTS:-}

# Get the email variables
EMAIL_REPORT=${EMAIL_REPORT:-}
if [ -n "$EMAIL_REPORT" ]; then
    SMTP_FROM=$(  ( [ -n "$EMAIL_FROM" ] && echo "$EMAIL_FROM" ) || ( [ -n "$EMAIL_FROM_FILE" ] && cat "$EMAIL_FROM_FILE" )  2>/dev/null  )
    SMTP_TO=$(  ( [ -n "$EMAIL_TO" ] && echo "$EMAIL_TO" ) || ( [ -n "$EMAIL_TO_FILE" ] && cat "$EMAIL_TO_FILE" )  2>/dev/null  )
    SMTP_USER=$(  ( [ -n "$EMAIL_USER" ] && echo "$EMAIL_USER" ) || ( [ -n "$EMAIL_USER_FILE" ] && cat "$EMAIL_USER_FILE" )  2>/dev/null  )
    SMTP_PASSWORD=$(  ( [ -n "$EMAIL_PASSWORD" ] && echo "$EMAIL_PASSWORD" ) || ( [ -n "$EMAIL_PASSWORD_FILE" ] && cat "$EMAIL_PASSWORD_FILE" )  2>/dev/null  )
    SMTP_SERVER=$(  ( [ -n "$SMTP_SERVER" ] && echo "$SMTP_SERVER" ) || ( [ -n "$SMTP_SERVER_FILE" ] && cat "$SMTP_SERVER_FILE" )  2>/dev/null  )
    SMTP_PORT=$(  ( [ -n "$SMTP_PORT" ] && echo "$SMTP_PORT" ) || ( [ -n "$SMTP_PORT_FILE" ] && cat "$SMTP_PORT_FILE" )  2>/dev/null  )

    # Validate email variables
    [ -z "$SMTP_SERVER" ] && error "Env var SMTP_SERVER is undefined!" && EMAIL_DISABLED=1
    [ -z "$SMTP_USER" ] && error "Env var SMTP_USER is undefined!" && EMAIL_DISABLED=1
    [ -z "$SMTP_PORT" ] && error "Env var SMTP_PORT is undefined!" && EMAIL_DISABLED=1
    [ -z "$SMTP_PASSWORD" ] && error "Env var SMTP_PASSWORD is undefined!" && EMAIL_DISABLED=1
    [ -z "$SMTP_FROM" ] && error "Env var SMTP_FROM is undefined!" && EMAIL_DISABLED=1
    [ -z "$SMTP_TO" ] && error "Env var SMTP_TO is undefined!" && EMAIL_DISABLED=1
fi

# Debug all variables
if [ -n "$DEBUG" ]; then
    debug "BASE_DIR: $BASE_DIR"
    debug "LETSENCRYPT_DIR: $LETSENCRYPT_DIR"
    debug "DEBUG: $DEBUG"

    debug "TARGET_CONTAINER_NAME: $TARGET_CONTAINER_NAME"

    debug "STAGING: $STAGING"
    debug "ENDPOINT: $ENDPOINT"
    debug "RSA_KEY_SIZE: $RSA_KEY_SIZE"
    debug "DOMAINS: $DOMAINS"
    debug "DOMAIN_ADMIN_EMAIL_LOCALPART: $DOMAIN_ADMIN_EMAIL_LOCALPART"

    debug "PLUGIN_DNS_PROVIDER: $PLUGIN_DNS_PROVIDER"
    debug "PLUGIN_DNS_CREDENTIALS_FILE: $PLUGIN_DNS_CREDENTIALS_FILE"
    debug "PLUGIN_DNS_PROPAGATION_SECONDS: $PLUGIN_DNS_PROPAGATION_SECONDS"

    debug "EMAIL_REPORT: $EMAIL_REPORT"
    debug "SMTP_FROM: $SMTP_FROM"
    debug "SMTP_TO: $SMTP_TO"
    debug "SMTP_USER: $SMTP_USER"
    debug "SMTP_PASSWORD: $SMTP_PASSWORD"
    debug "SMTP_SERVER: $SMTP_SERVER"
    debug "SMTP_PORT: $SMTP_PORT"
    debug "EMAIL_DISABLED: $EMAIL_DISABLED"
fi
