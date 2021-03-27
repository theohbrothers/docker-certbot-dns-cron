@"
version: '3.3'
services:

  certbot:
    image: theohbrothers/docker-certbot-dns-cron:$( $VARIANT['tag'] )
    environment:
      ###########
      # Certbot #
      ###########
      # Whether to use production or staging LetsEncrypt endpoint. 0 for production, 1 for staging
      - STAGING=0

      # RSA Key size
      - RSA_KEY_SIZE=4096

$( if ( $PASS_VARIABLES['secret'] ) {
@'
      # Domains file, delimited by "\n"
      - DOMAINS_FILE=/run/secrets/certbot_domains.txt
'@
} else {
@'
      # Domains (delimited by ';')
      - DOMAINS=foo.example.com;bar.example.com
'@
})
      # Admin Email's Local-part for LetsEncrypt expiry-notification emails
      # E.g. use "admin" for notification emails sent to "admin.example.com"
      # See https://en.wikipedia.org/wiki/Email_address for more information on the Local-part
      - DOMAIN_ADMIN_EMAIL_LOCALPART=admin

      # Certbot DNS Plugin
      - PLUGIN_DNS_PROVIDER=$( $VARIANT['_metadata']['package'] )
      - PLUGIN_DNS_CREDENTIALS_FILE=$( if ( $PASS_VARIABLES['secret'] ) { "/run/secrets/certbot_dns_$( $VARIANT['_metadata']['package'] )_credentials.ini" } else { "/etc/letsencrypt/certbot_dns_$( $VARIANT['_metadata']['package'] )_credentials.ini" } )
      - PLUGIN_DNS_PROPAGATION_SECONDS=10

      ##########
      # Deploy #
      ##########
      # Whether to deploy certs. Omit environment variable to disable
      - DEPLOY_CERTS=1

      ##########
      # Reload #
      ##########
      # Container name to reload after signing and obtaining cert. Omit environment variable to disable
      - TARGET_CONTAINER_NAME=nginx-proxy-docker-gen

      ##########
      # Report #
      ##########
      # Whether to email the certbot report on successful signing of certs
      - EMAIL_REPORT=1
$( if ( $PASS_VARIABLES['secret'] ) {
@'
      # Email vars to send Report
      - EMAIL_FROM_FILE=/run/secrets/certbot_email_from
      - EMAIL_TO_FILE=/run/secrets/certbot_email_to
      - EMAIL_USER_FILE=/run/secrets/certbot_email_user
      - EMAIL_PASSWORD_FILE=/run/secrets/certbot_email_password
      - SMTP_SERVER_FILE=/run/secrets/certbot_email_smtp_server
      - SMTP_PORT_FILE=/run/secrets/certbot_email_smtp_port
'@
} else {
@'
      # Email vars to send Report
      - EMAIL_FROM=foo@example.com
      - EMAIL_TO=foo@example.com
      - EMAIL_USER=foo@example.com
      - EMAIL_PASSWORD=myPassword
      - SMTP_SERVER=foo.smtp.com
      - SMTP_PORT=587
'@
})
$( if ( $PASS_VARIABLES['secret'] ) {
@"
    secrets:
      - certbot_domains.txt
      - certbot_dns_$( $VARIANT['_metadata']['package'] )_credentials.ini
      - certbot_email_from
      - certbot_email_to
      - certbot_email_user
      - certbot_email_password
      - certbot_email_smtp_server
      - certbot_email_smtp_port
"@
})
    volumes:
      - nginx-proxy-certs:/certs/:rw
      - ./data/letsencrypt:/etc/letsencrypt/:rw
      - /var/run/docker.sock:/tmp/docker.sock:ro

$( if ( $PASS_VARIABLES['secret'] ) {
@"
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
      placement:
        constraints: [node.role == manager]

secrets:
  certbot_domains.txt:
    external: true
  certbot_dns_$( $VARIANT['_metadata']['package'] )_credentials.ini:
    external: true
  certbot_email_from:
    external: true
  certbot_email_to:
    external: true
  certbot_email_user:
    external: true
  certbot_email_password:
    external: true
  certbot_email_smtp_server:
    external: true
  certbot_email_smtp_port:
    external: true
"@
})

volumes:
  nginx-proxy-certs:
    external: true

"@
