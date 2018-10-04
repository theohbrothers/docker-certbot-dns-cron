# Dockerfile: https://hub.docker.com/r/certbot/dns-linode/
FROM certbot/dns-linode

MAINTAINER The Oh Brothers

COPY app /app
RUN chown -R root:root /app
RUN chmod -R 550 /app/scripts

COPY /app/crontabs/root /var/spool/cron/crontabs/root
RUN chown -R root:root /var/spool/cron/crontabs/root && chmod -R 640 /var/spool/cron/crontabs/root

# This is the only signal from the docker host that appears to stop crond
STOPSIGNAL SIGKILL

WORKDIR /app

CMD ["crond", "-f"]
