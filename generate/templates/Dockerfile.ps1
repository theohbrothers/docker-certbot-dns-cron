@"
# Dockerfile: https://hub.docker.com/r/certbot/dns-$( $VARIANT['_metadata']['package'] )
FROM certbot/dns-$( $VARIANT['_metadata']['package'] ):$( $VARIANT['_metadata']['package_version'] )

LABEL maintainer="The Oh Brothers"

COPY app /app
RUN chown -R root:root /app
RUN chmod -R 550 /app/scripts

COPY crontab /var/spool/cron/crontabs/root
RUN chown -R root:root /var/spool/cron/crontabs/root && chmod -R 640 /var/spool/cron/crontabs/root

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# This is the only signal from the docker host that appears to stop crond
STOPSIGNAL SIGKILL

WORKDIR /app

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crond", "-f"]
"@
