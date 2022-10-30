#!/bin/sh

# This script signs cert of domain names passed as arguments, copies it to the cert store /certs, reloads a target container, and emails the success status of the three previous steps.

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

num_domains=$( echo "$DOMAINS" | wc -l )
num_skipped=0
output "Will sign certs for $num_domains domains"
for domain in $DOMAINS
do
    output "Processing domain: $domain"

    # 1. certificate signing
    if [ -n "$domain" ]; then
        output "Performing certificate signing stage"
        status_file="/tmp/status-$( date +%s ).log"
        signcert "$domain" "$OPT_FORCE_RENEWAL" | tee "$status_file"
        status=$( cat "$status_file" )
        skipped=
        success_signcert=
        echo "$status" | grep 'Certificate not yet due for renewal' > /dev/null 2>&1 && output "Certificate for domain $domain not yet due for renewal." && skipped=1 && num_skipped=$( echo `expr $num_skipped + 1` ) && continue
        echo "$status" | grep 'Congratulations! Your certificate and chain have been saved' > /dev/null 2>&1 && output "Certificate for domain $domain was signed." && success_signcert=1 || success_signcert=

        # Generate report
        if [ -n "$skipped" ]; then
            report="$report\nSign cert for $domain skipped"
        else
            [ -n "$success_signcert" ] && report="$report\nSign cert for $domain successful" || report="$report\nSign cert for $domain failed"
        fi
        rm -rf "$status_file"
    fi

    # 2. deploy
    if [ -n "$DEPLOY_CERTS" ]; then
        output "Performing deploy stage"
        deploycert "$domain"

        # Generate report
        [ $? = 0 ] && report="$report\nDeploy cert for $domain successful" || report="$report\nDeploy certs for $domain failed"
    else
        output "Skipping deploy stage"
    fi

    # 3. reload
    if [ -n "$TARGET_CONTAINER_NAME" ]; then
        output "Performing reload stage"
        sendsignal "$TARGET_CONTAINER_NAME" "SIGHUP"

        # Generate report
        [ $? = 0 ] && report="$report\nReload target container successful" || report="$report\nReload target container failed"
    else
        output "Skipping reload stage"
    fi

done

# Generate report
report_title="Subject: [Certbot automation summary report: $( echo `expr $num_domains - $num_skipped` ) newly signed certs]"
report="$report_title\n\nCertbot automation summary report on $( date '+%Y-%m-%d %H:%M:%S' ): \n$report"

# Skip sending email if all certs were not due
[ "$num_domains" = "$num_skipped" ] && output "Nothing to do" && EMAIL_REPORT= && report="$report\nAll certificates not due for renewal."

# 4. email report
if [ -n "$EMAIL_REPORT" ];  then
    if [ -n "$EMAIL_DISABLED" ]; then
        report="$report\nCannot send email due to missing variables"
    else
        echo -e "$report" | sendmail -w 5 -f "$SMTP_FROM" "-au$SMTP_USER" "-ap$SMTP_PASSWORD" -H "openssl s_client -quiet -tls1_2 -starttls smtp -connect $SMTP_SERVER:$SMTP_PORT" "$SMTP_TO"
        [ $? = 0 ] && report="$report\nSend email Successful" || report="$report\nSend email failed"
    fi
else
    output "Not emailing Certbot automation summary report"
fi

# 5. Output report to stdout
output "$report"
