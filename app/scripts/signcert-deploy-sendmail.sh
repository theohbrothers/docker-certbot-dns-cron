#/bin/sh

# This script signs cert, copies it to /nginx-certs, then reloads nginx-proxy
# It is a wrapper around signcert.sh

cd "$( realpath $(dirname "$0") )"
source ./init.sh

if [ $# -gt 0 ]; then
    # Get any passed arguments
    #echo "Num of args (before): $#, args: $@"
    for arg in "$@"; do
        [ "$arg" == '--force' ] || [ "$arg" == '--force' ] && OPT_FORCE_RENEWAL=1 && output 'Forcing renewal of certs' && shift
    done
    #echo "Num of args (after): $#, args: $@"

    # Any remaining arguments will be used as domains
    if [ $# -gt 0 ]; then
        DOMAINS=$@
        output "Using arguments as domains: $DOMAINS"
    else
        output "Using environment variable \$DOMAINS as domains: $DOMAINS"
    fi
else
    output "Using environment variable \$DOMAINS as domains: $DOMAINS"
fi

# Stop here if no domains were given as arguments
[ -z "$DOMAINS" ] && error 'Domain(s) not provided.' && exit 1

for domain in $DOMAINS
do
    # 1. Sign cert
    signcert "$domain" "$OPT_FORCE_RENEWAL"
    [ $? = 0 ] && success_signcert=1

    if [ -n "$success_signcert" ]; then
        # 2. Deploy certs to nginx and docker-gen
        output "Deploying $domain signed cert and key to /certs"
        key="$LETSENCRYPT_DIR/live/$domain/privkey.pem"
        dest_key="/certs/$domain.crt"
        cert="$LETSENCRYPT_DIR/live/$domain/cert.pem"
        dest_cert="/certs/$domain.key"
        cp "$key" "$dest_key" && chown root:root "$dest_key" && chmod 440 "$dest_key" && cp "$cert" "$dest_cert" && chown root:root "$dest_cert" && chmod 440 "$dest_cert"
        [ $? = 0 ] && success_deploycert=1

        # 3. Reload target container (e.g. docker-gen)
        if [ -n "$success_deploycert" ]; then
            # Ubuntu: nc -U /tmp/docker.sock
            # Alpine: nc local:/tmp/docker.sock
            # Get container name from env var, escaping regex special chars. Typically not needed, but needed only for complex names
            target_container_name_regex_escaped=$(     [ -n "$TARGET_CONTAINER_NAME" ] && echo "$TARGET_CONTAINER_NAME" | sed 's/\([(){}+*?.^$<>=|]\)/\\\1/g' | sed 's/\(\[\)/\\\1/g' | sed 's/\(\]\)/\\\1/g'     ||     echo "docker-gen"      )
            sed_capture=$( cat - <<EOF
s/.*"Id":"([0-9a-f]+)","Names":\["\/$target_container_name_regex_escaped"\].*/\1/g
EOF
)
            target_container_id=$( echo -e "GET /containers/json HTTP/1.0\r\n" | nc local:/tmp/docker.sock | sed -r "$sed_capture" | grep -E '^[0-9a-f]+$' )
            if [ -n "$target_container_id" ]; then
                occurances=$( echo "$target_container_id" | wc -l )
                signal="SIGHUP"
                output "Reloading target container $TARGET_CONTAINER_NAME of id: $target_container_id with signal $signal"
                echo -e "POST /containers/$target_container_id/kill?signal=$signal HTTP/1.0\r\n" | nc local:/tmp/docker.sock >/dev/null
                [ $? = 0 ] && success_reload_dockergen=1
            else
                error "Cannot reload target container $TARGET_CONTAINER_NAME. Reason: failed to get container id!"
            fi
        fi
    fi

    # Generate report
    [ -n "$success_signcert" ] && report="$report\nSign cert for $domain successful" || report="$report\nSign cert for $domain failed"
    [ -n "$success_deploycert" ] && report="$report\nDeploy cert for $domain successful" || report="$report\nDeploy certs for $domain failed"
    [ -n "$success_reload_dockergen" ] && report="$report\nReload target container successful" || report="$report\nReload target container failed"
done

# 4. Send email of report
report_title="Subject: [Certbot summary report]"
report="$report_title\n\nCertbot summary report on $( date '+%Y-%m-%d %H:%M:%S' ): \n$report"
if [ -n "$EMAIL_DISABLED" ]; then
    report="$report\nCannot send email due to missing variables"
else
    echo -e "$report" | sendmail -w 5 -f "$SMTP_FROM" "-au$SMTP_USER" "-ap$SMTP_PASSWORD" -H "openssl s_client -quiet -tls1_2 -starttls smtp -connect $SMTP_SERVER:$SMTP_PORT" "$SMTP_TO"
    [ $? = 0 ] && report="$report\nSend email Successful" || report="$report\nSend email failed"
fi

# 5. Output report to logs
output "$report"