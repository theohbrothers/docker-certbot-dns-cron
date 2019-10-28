# docker-certbot-dns-cron

[![pipeline status](https://gitlab.com/leojonathanoh/docker-certbot-dns-cron/badges/dev/pipeline.svg)](https://gitlab.com/leojonathanoh/docker-certbot-dns-cron/commits/dev)
[![github-tag](https://img.shields.io/github/tag/leojonathanoh/docker-certbot-dns-cron)](https://github.com/leojonathanoh/docker-certbot-dns-cron/releases/)
[![docker-image-size](https://img.shields.io/microbadger/image-size/leojonathanoh/docker-certbot-dns-cron/latest)](https://hub.docker.com/r/leojonathanoh/docker-certbot-dns-cron)
[![docker-image-layers](https://img.shields.io/microbadger/layers/leojonathanoh/docker-certbot-dns-cron/latest)](https://hub.docker.com/r/leojonathanoh/docker-certbot-dns-cron)

Dockerized [Certbot with DNS Plugins](https://certbot.eff.org/docs/using.html#dns-plugins), with cron, deploy, email alert capabilities.

It signs wildcards certificates for domains. For instance, the DNS Names for an obtained certificate for `example.com` would be: `example.com, *.example.com`.

All Certbot plugins are supported: `cloudflare`, `cloudxns`, `digitalocean`, `dnsimple`, `dnsmadeeasy`, `google`, `linode`, `luadns`, `nsone`, `ovh`, `rfc2136`, `route53`

## Variants

Each variant is Certbot DNS provider plugin image.

| Tag | Plugin name |
|:-------:|:---------:|
| `:latest`, `:cloudflare` | [certbot-dns-cloudflare](https://certbot-dns-cloudflare.readthedocs.io)
| `:cloudxns` | [certbot-dns-cloudxns](https://certbot-dns-cloudxns.readthedocs.io)
| `:digitalocean` | [certbot-dns-digitalocean](https://certbot-dns-digitalocean.readthedocs.io)
| `:dnsimple` | [certbot-dns-dnsimple](https://certbot-dns-dnsimple.readthedocs.io)
| `:dnsmadeeasy` | [certbot-dns-dnsmadeeasy](https://certbot-dns-dnsmadeeasy.readthedocs.io)
| `:google` | [certbot-dns-google](https://certbot-dns-google.readthedocs.io)
| `:linode` | [certbot-dns-linode](https://certbot-dns-linode.readthedocs.io)
| `:luadns` | [certbot-dns-luadns](https://certbot-dns-luadns.readthedocs.io)
| `:nsone` | [certbot-dns-nsone](https://certbot-dns-nsone.readthedocs.io)
| `:ovh` | [certbot-dns-ovh](https://certbot-dns-ovh.readthedocs.io)
| `:rfc2136` | [certbot-dns-rfc2136](https://certbot-dns-rfc2136.readthedocs.io)
| `:route53` | [certbot-dns-route53](https://certbot-dns-route53.readthedocs.io)

## Environment variables

Environment variables are used to control various steps of the automation process.

### 1. Certbot

| Name | Default value | Description | Corresponds to `certbot` argument |
|:-------:|:---------------:|:---------:|:---------:|
| `STAGING` | `0` |  Whether to use production or staging LetsEncrypt endpoint. 0 for production, 1 for staging
| `RSA_KEY_SIZE` | `4096` | Size of the RSA key. | `--rsa-key-size`
| `DOMAINS` | `""` | Domains (delimited by ';' ) | `--domains`, `-d`
| `DOMAINS_FILE` | `4096` | Same as `DOMAINS`, but this should point to a file. Domains should be delimited by "\n". Useful when using secrets. | `--domains`, `-d`
| `DOMAIN_ADMIN_EMAIL_LOCALPART` | `admin` | Admin Email's Local-part for LetsEncrypt expiry-notification emails. The final email will be `<DOMAIN_ADMIN_EMAIL_LOCALPART>@domain.com` | `--email`, `-m`
| `PLUGIN_DNS_PROVIDER` | `""` | DNS Provider. Valid values are: `cloudflare`, `cloudxns`, `digitalocean`, `dnsimple`, `dnsmadeeasy`, `google`, `linode`, `luadns`, `nsone`, `ovh`, `rfc2136`, `route53`  | `--dns-<PLUGIN_DNS_PROVIDER>`
| `PLUGIN_DNS_CREDENTIALS_FILE` | `""` | Path to the dns credentials file | `--dns-<PLUGIN_DNS_PROVIDER>-credentials`.
| `PLUGIN_DNS_PROPAGATION_SECONDS` | certbot plugin default, check plugin documentation | The number of seconds to wait for DNS to propagate before asking the ACME server to verify the DNS record. | `--dns-<PLUGIN_DNS_PROVIDER>-propagation-seconds`.

### 2. Deploy

| Name | Default value | Description |
|:-------:|:---------------:|:---------:|
| `DEPLOY_CERTS` | `""` | Whether to deploy the sign cert and key. This copies `/etc/letsencrypt/live/<domain>/privkey.pem` to `/certs/<domain>.key`, and `/etc/letsencrypt/live/<domain>/cert.pem` to `/certs/<domain>.crt`. Omit environment variable to disable deploy

### 3. Reload

| Name | Default value | Description |
|:-------:|:---------------:|:---------:|
| `TARGET_CONTAINER_NAME` | `""` | Container name to reload (with SIGHUP) after signing and obtaining cert. In Swarm mode, specify `<stack><service>` and any container with name starting with `<stack><service>` will be sent a signal. Only one container name may be matched, so ensure this is as unique as possible. Omit environment variable to disable reload

### 4. Report Emailing

| Name | Default value | Description |
|:-------:|:---------------:|:---------:|
| `EMAIL_REPORT` | `""` | Whether to email the summary report on successful cert-signing, deployment, and reloading of target container. Omit environment variable to disable email
| `EMAIL_FROM` | `""` | Email sender address
| `EMAIL_TO` | `""` | Email receipient address
| `EMAIL_USER` | `""` | SMTP sender account user
| `EMAIL_PASSWORD` | `""` | SMTP sender account password
| `SMTP_SERVER` | `""` | SMTP server DNS / hostname / IP address. E.g. `smtp.example.com`, `1.2.3.4`
| `SMTP_PORT` | `""` | SMTP server port. E.g. `587`, `465`

#### If using Swarm Secrets

Instead of writing your email credentials in the `docker-compose.yml`, use specific environment variables that point to each Swarm Secrets mountpoints `/run/secrets/secret_file`. These files will be read to obtain the email credentials.

> Note: Change the Secret Environment Variables to point to your secret name. E.g. if the name of your secret is `my_secret_password`, use the value `/run/secrets/my_secret_password` for `EMAIL_PASSWORD_FILE`

| Name | Default value | Description |
|:-------:|:---------------:|:---------:|
| `EMAIL_FROM_FILE` | `/run/secrets/certbot_email_from` | Email sender address
| `EMAIL_TO_FILE` | `/run/secrets/certbot_email_to` | Email receipient address
| `EMAIL_USER_FILE` | `/run/secrets/certbot_email_user` | SMTP sender account user
| `EMAIL_PASSWORD_FILE` | `/run/secrets/certbot_email_password` | SMTP sender account password
| `SMTP_SERVER_FILE` | `/run/secrets/certbot_email_smtp_server` | SMTP server DNS / hostname / IP address. E.g. `smtp.example.com`, `1.2.3.4`
| `SMTP_PORT_FILE` | `/run/secrets/certbot_email_smtp_port` | SMTP server port. E.g. `587`, `465`

--------------------

## Examples

### Not using Swarm Secrets

This example signs 2 wildcard certificates, one certificate for `example.com`, and one for `ns.example.com` :

1. `example.com`, `*.example.com`
2. `ns.example.com`, `*.ns.example.com`

```sh
docker service create --name certbot-dns-cron \
    -e STAGING=1 \
    -e 'DOMAINS=example.com;ns.example.com' \
    -e PLUGIN_DNS_CREDENTIALS_FILE=
    -e PLUGIN_DNS_PROVIDER=cloudflare \
    -e PLUGIN_DNS_CREDENTIALS_FILE=/etc/letsencrypt/certbot_dns_cloudflare_credentials.ini \
    -e PLUGIN_DNS_PROPAGATION_SECONDS=10 \
    --mount type=bind,source=/var/run/certbot_dns_cloudflare_credentials.ini,target=/etc/letsencrypt/certbot_dns_cloudflare_credentials.ini,readonly \
    --mount type=bind,source=/path/to/data/certs/,target=/certs \
    --mount type=bind,source=/path/to/data/letsencrypt,target=/etc/letsencrypt \
	--replicas=1 \
	wonderous/certbot-dns-cron
```

Contents of secret `certbot_dns_cloudflare_credentials.ini`
```ini
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = cloudflare@example.com
dns_cloudflare_api_key = 0123456789abcdef0123456789abcdef01234567
```

### Using Swarm Secrets

This example signs 2 wildcard certificates, one certificate for `example.com`, and one for `ns.example.com` :

1. `example.com`, `*.example.com`
2. `ns.example.com`, `*.ns.example.com`

LetsEncrypt expiry notification emails will be sent to: `admin@example.com`

```sh
docker service create --name certbot-dns-cron \
    -e STAGING=1 \
    --secret certbot_domains.txt \
    --secret certbot_dns_cloudflare_credentials.ini \
    -e PLUGIN_DNS_PROVIDER=cloudflare \
    -e PLUGIN_DNS_CREDENTIALS_FILE=/run/secrets/certbot_dns_cloudflare_credentials.ini \
    -e PLUGIN_DNS_PROPAGATION_SECONDS=10 \
    --mount type=bind,source=/path/to/data/certs/,target=/certs \
    --mount type=bind,source=/path/to/data/letsencrypt,target=/etc/letsencrypt \
	--replicas=1 \
	wonderous/certbot-dns-cron
```

Contents of secret `certbot_dns_cloudflare_credentials.ini`

```ini
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = cloudflare@example.com
dns_cloudflare_api_key = 0123456789abcdef0123456789abcdef01234567
```

Contents of secret `certbot_domains.txt`

```
example.com
ns.example.com
```

### Full Example (Using Swarm Secrets)

This example will sign, deploy certs, reload a target container (requires mounting the `docker.sock`), and email a summary report about the success of those tasks (requires email credential secrets). Four wildcard certificates will be obtained:

1. `example.com`, `*.example.com`
2. `ns.example.com`, `*.ns.example.com`
2. `example2.com`, `*.example2.com`
2. `ns.example2.com`, `*.ns.example2.com`

LetsEncrypt expiry notification emails will be sent to: `admin@example.com`

```sh
docker service create --name certbot-dns-cron \
    -e STAGING=1 \
    -e PLUGIN_DNS_PROVIDER=cloudflare \
    -e PLUGIN_DNS_CREDENTIALS_FILE=/run/secrets/certbot_dns_cloudflare_credentials.ini \
    -e PLUGIN_DNS_PROPAGATION_SECONDS=10 \
    --secret certbot_domains.txt \
    --secret certbot_dns_cloudflare_credentials.ini \
    -e DOMAIN_ADMIN_EMAIL_LOCALPART=admin
    \
    -e DEPLOY_CERTS=1 \
    \
    -e TARGET_CONTAINER_NAME=nginx-proxy_docker-gen \
    \
    -e EMAIL_REPORT=1 \
    --secret certbot_email_from \
    --secret certbot_email_to \
    --secret certbot_email_user \
    --secret certbot_email_password \
    --secret certbot_email_smtp_server \
    --secret certbot_email_smtp_port \
    \
    --mount type=bind,source=/path/to/data/certs/,target=/certs \
    --mount type=bind,source=/path/to/data/letsencrypt,target=/etc/letsencrypt \
    --mount type=bind,source=/var/run/docker.sock,target=/tmp/docker.sock \
	--replicas=1 \
	wonderous/certbot-dns-cron
```

Contents of secret `certbot_domains.txt`

```
example.com
ns.example.com
example2.com
ns.example2.com
```

Contents of secret `certbot_dns_cloudflare_credentials.ini`

```ini
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = cloudflare@example.com
dns_cloudflare_api_key = 0123456789abcdef0123456789abcdef01234567
```

Contents of secret `certbot_email_from`

```
me@example.com
```

Contents of secret `certbot_email_to`

```
me@example.com
```

Contents of secret `certbot_email_user`

```
me@example.com
```

Contents of secret `certbot_email_password`

```
myPassword
```

Contents of secret `certbot_email_smtp_server`

```
smtp.example.com
```

Contents of secret `certbot_email_smtp_port`

```
587
```

----------------------------------------

## Cron interval

By default, the cron invokes the main script every hour.

----------------------------------------


## Script behaviour

### Certificate Signing stage

Assuming you passed in the necessary environment variables, renewing certs would be as simple as invoking the main script, whether through `docker exec`, or directly. The script always reads environment variables to initialize all variables each time it is invoked.

### Deploy stage

The script copies each successfully signed domain certificate / key to the folder `/certs`.

To disable this stage, omit the environment variable `DEPLOY_CERTS`

### Reload stage

The script sends a `SIGHUP` (`1`) to a container with name starting with `TARGET_CONTAINER_NAME`.

When `Swarm Mode` is used, all services go by the naming convention `<stack><service>`. `<stack>` is the name given when using `docker stack up`, and `<service>` is the service key in the `docker-compose.yml` or `docker-stack.yml`. If a container name starts with `<stack><service>`, ignoring the suffix, that container is sent the signal. As an example, if the value of `TARGET_CONTAINER_NAME` variable is `mystack_docker-gen`, the service called `mystack_docker-gen.1.jb2xwgp3ktnmsmp1eo31563jw` is sent the reload signal. The signal is sent to one container only; if multiple containers names match `mystack_docker-gen`, no signal is sent. Therefore keep the container name as unique as possible.

Mounting the `/var/run/docker.sock` is necessary for reloading to take place.

To disable this stage, omit the environment variable `TARGET_CONTAINER_NAME`


### Email stage

This sends a summarized report of all the previous steps and their success status. Only one email is sent each time the script is invoked.

No email is sent in these cases:
1. The email functionality is disabled by omitting `EMAIL_REPORT`
2. One or more email credentials were not specified, among: `EMAIL_FROM`, `EMAIL_TO`, `EMAIL_USER`, `EMAIL_PASSWORD`, `SMTP_SERVER`, `SMTP_PORT`
3. The email credentials were wrong
4. All the given domains' certificates are not due for renewal

Assuming all variables are set correctly, as long as one certificate is obtained / renewed, a summary report will be sent.

To disable this stage, omit the environment variable `EMAIL_REPORT`


------------------------------------------

## Manually sign a certificate

To do so, invoke the main script, passing domain(s) as arguments.

If a certificate for a given domain doesn't yet exist, a new certificate will be obtained.
If a certificate for a given domain is not due for renewal, certbot shows a message that no renewal is done.

### On the Docker Host

```sh
docker exec -it "$container_name_or_id" sh -c '/app/scripts/signcert-deploy-sendmail.sh example.com
```

To force, use the `--force` flag

```sh
docker exec -it "$container_name_or_id" sh -c '/app/scripts/signcert-deploy-sendmail.sh example.com
```

### Inside the container

```sh
/app/scripts/signcert-deploy-sendmail.sh example.com
```

To force, use the `--force` flag

```sh
/app/scripts/signcert-deploy-sendmail.sh --force example.com
```

For multiple domains

```sh
/app/scripts/signcert-deploy-sendmail.sh --force example.com example2.com example3.com
```

## Manually remove a certificate

This can either be done by using the provided script `removecert.sh`, or manually deleting the domain folder in the `letsencrypt` data folder. For `example.com`, delete the folder named `example.com`

### On the Docker Host

```sh
docker exec -it "$container_name_or_id" sh -c '/app/scripts/removecert.sh example.com
```

### Inside the container

```sh
/app/scripts/removecert.sh example.com
```

## Read a certificate

### On the Docker Host

```sh
docker exec -it "$container_name_or_id" sh -c '/app/scripts/readcert.sh example.com
```

### Inside the container

```sh
/app/scripts/readcert.sh example.com
```
