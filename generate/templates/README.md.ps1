@'
# docker-certbot-dns-cron

[![github-actions](https://github.com/theohbrothers/docker-certbot-dns-cron/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/docker-certbot-dns-cron/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/docker-certbot-dns-cron?style=flat-square)](https://github.com/theohbrothers/docker-certbot-dns-cron/releases/)
[![docker-image-size](https://img.shields.io/docker/image-size/theohbrothers/docker-certbot-dns-cron/latest)](https://hub.docker.com/r/theohbrothers/docker-certbot-dns-cron)

Dockerized [certbot](https://github.com/certbot/certbot) with [DNS Plugins](https://certbot.eff.org/docs/using.html#dns-plugins), based on [official certbot docker images](https://hub.docker.com/u/certbot), with cron, deploy, email alert capabilities.

It signs wildcards certificates for domains. For instance, the DNS Names for an obtained certificate for `example.com` would be: `example.com, *.example.com`.

All Certbot plugins are supported: `cloudflare`, `cloudxns`, `digitalocean`, `dnsimple`, `dnsmadeeasy`, `google`, `linode`, `luadns`, `nsone`, `ovh`, `rfc2136`, `route53`

## Deprecation notice

The present application is a 4-step tool for automating ACME certificate renewal using `certbox` for a container orchestrator like `docker` standalone or `docker` `swarm`.

However, step `2.`, `3.`, and `4.` may be solved by using already existing tools, for instance:

- Copying certs to another service can be done by sharing a volume or by some other means
- Reloading another service by sending a signal can be done in many other ways which are more secure than doing it over `/var/run/docker.sock`
- Notification can be done in many other ways other than email

Since there only remains step `1.` to solve, there is no benefit to using this application. The `certbot` tool itself constantly evolves, and it makes no sense to maintain a wrapping entrypoint script around it.

Hence, it is simpler to just use the [official certbot docker images](https://hub.docker.com/u/certbot). If a cron is needed, create a crontab in `/etc/crontabs/<user>` and run `crond`.


'@

@"
## Tags

Each variant is Certbot DNS provider plugin image.

| Tag | Plugin name | Dockerfile Build Context  |
|:-------:|:---------:|:---------:
$(
($VARIANTS | % {
    if ( $_['tag_as_latest'] ) {
@"
| ``:$( $_['tag'] )``, ``:latest`` | [certbot-dns-$( $_['_metadata']['package'] )](https://certbot-dns-$( $_['_metadata']['package'] ).readthedocs.io) | [View](variants/$( $_['tag'] )) |

"@
    }else {
@"
| ``:$( $_['tag'] )`` | [certbot-dns-$( $_['_metadata']['package'] )](https://certbot-dns-$( $_['_metadata']['package'] ).readthedocs.io) | [View](variants/$( $_['tag'] )) |

"@
    }
}) -join ''
)

"@

@'
## Usage

### Example: Not using Swarm Secrets

This example signs 2 wildcard certificates, one certificate for `example.com`, and one for `ns.example.com` :

1. `example.com`, `*.example.com`
2. `ns.example.com`, `*.ns.example.com`


'@

@"
``````sh
docker service create --name certbot-dns-cron \
    -e STAGING=1 \
    -e 'DOMAINS=example.com;ns.example.com' \
    -e PLUGIN_DNS_PROVIDER=cloudflare \
    -e PLUGIN_DNS_CREDENTIALS_FILE=/etc/letsencrypt/certbot_dns_cloudflare_credentials.ini \
    -e PLUGIN_DNS_PROPAGATION_SECONDS=10 \
    --mount type=bind,source=/var/run/certbot_dns_cloudflare_credentials.ini,target=/etc/letsencrypt/certbot_dns_cloudflare_credentials.ini,readonly \
    --mount type=bind,source=/path/to/data/certs/,target=/certs \
    --mount type=bind,source=/path/to/data/letsencrypt,target=/etc/letsencrypt \
    --replicas=1 \
    theohbrothers/docker-certbot-dns-cron:$( $VARIANTS | ? { $_['tag_as_latest'] } | Select -First 1 | % { $_['tag'] } )
``````


"@

@'
Contents of secret `certbot_dns_cloudflare_credentials.ini`

```ini
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = cloudflare@example.com
dns_cloudflare_api_key = 0123456789abcdef0123456789abcdef01234567
```

### Example: Using Swarm Secrets

This example signs 2 wildcard certificates, one certificate for `example.com`, and one for `ns.example.com` :

1. `example.com`, `*.example.com`
2. `ns.example.com`, `*.ns.example.com`

LetsEncrypt expiry notification emails will be sent to: `admin@example.com`


'@

@"
``````sh
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
    theohbrothers/docker-certbot-dns-cron:$( $VARIANTS | ? { $_['tag_as_latest'] } | Select -First 1 | % { $_['tag'] } )
``````


"@

@'
Contents of secret `certbot_dns_cloudflare_credentials.ini`

```ini
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = cloudflare@example.com
dns_cloudflare_api_key = 0123456789abcdef0123456789abcdef01234567
```

Contents of secret `certbot_domains.txt`

```txt
example.com
ns.example.com
```

### Full Example: Using Swarm Secrets

This example will sign, deploy certs, reload a target container (requires mounting the `docker.sock`), and email a summary report about the success of those tasks (requires email credential secrets). Four wildcard certificates will be obtained:

- `example.com`, `*.example.com`
- `ns.example.com`, `*.ns.example.com`
- `example2.com`, `*.example2.com`
- `ns.example2.com`, `*.ns.example2.com`

LetsEncrypt expiry notification emails will be sent to: `admin@example.com`


'@

@"
``````sh
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
    theohbrothers/docker-certbot-dns-cron:$( $VARIANTS | ? { $_['tag_as_latest'] } | Select -First 1 | % { $_['tag'] } )
``````


"@

@'
Contents of secret `certbot_domains.txt`

```txt
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

```txt
me@example.com
```

Contents of secret `certbot_email_to`

```txt
me@example.com
```

Contents of secret `certbot_email_user`

```txt
me@example.com
```

Contents of secret `certbot_email_password`

```txt
myPassword
```

Contents of secret `certbot_email_smtp_server`

```txt
smtp.example.com
```

Contents of secret `certbot_email_smtp_port`

```txt
587
```

## Environment variables

Environment variables are used to configure various stages of the automation process.

### 1. `certbot` Certificate Signing stage

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

### 2. Deploy stage

| Name | Default value | Description |
|:-------:|:---------------:|:---------:|
| `DEPLOY_CERTS` | `""` | Whether to deploy the signed cert, key, fullchain cert, and chain cert. This copies `/etc/letsencrypt/live/<domain>/privkey.pem` to `/certs/<domain>.key`, `/etc/letsencrypt/live/<domain>/cert.pem` to `/certs/<domain>.crt`, `/etc/letsencrypt/live/<domain>/fullchain.pem` to `/certs/<domain>.fullchain.pem`, and `/etc/letsencrypt/live/<domain/chain.pem` to `/certs/<domain>.chain.pem`. Omit environment variable to disable deploy

### 3. Reload stage

| Name | Default value | Description |
|:-------:|:---------------:|:---------:|
| `TARGET_CONTAINER_NAME` | `""` | Container name to reload (with SIGHUP) after signing and obtaining cert. In Swarm mode, specify `<stack><service>` and any container with name starting with `<stack><service>` will be sent a signal. Only one container name may be matched, so ensure this is as unique as possible. Omit environment variable to disable reload

### 4. Email notification stage

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

Instead of specifying your email credentials in the `docker-stack.yml`, use environment variables suffixed with `_FILE`, each pointing to Swarm Secrets' mountpoints `/run/secrets/<secret_name>`. These files will be read to obtain the email credentials.

| Name | Default value | Description |
|:-------:|:---------------:|:---------:|
| `EMAIL_FROM_FILE` | `/run/secrets/certbot_email_from` | Email sender address
| `EMAIL_TO_FILE` | `/run/secrets/certbot_email_to` | Email receipient address
| `EMAIL_USER_FILE` | `/run/secrets/certbot_email_user` | SMTP sender account user
| `EMAIL_PASSWORD_FILE` | `/run/secrets/certbot_email_password` | SMTP sender account password
| `SMTP_SERVER_FILE` | `/run/secrets/certbot_email_smtp_server` | SMTP server DNS / hostname / IP address. E.g. `smtp.example.com`, `1.2.3.4`
| `SMTP_PORT_FILE` | `/run/secrets/certbot_email_smtp_port` | SMTP server port. E.g. `587`, `465`

## Cron interval

By default, the cron invokes the main script every hour.

## Script usage

### Manually sign a certificate

To do so, invoke the main script, passing domain(s) as arguments.

If a certificate for a given domain doesn't yet exist, a new certificate will be obtained.
If a certificate for a given domain is not due for renewal, certbot shows a message that no renewal is done.

```sh
docker exec -it "$container_name_or_id" sh -c '/app/scripts/signcert-deploy-sendmail.sh example.com'

# For multiple domains
docker exec -it "$container_name_or_id" sh -c '/app/scripts/signcert-deploy-sendmail.sh example.com example2.com example3.com'
```

To force certificate renewal even if the certificate is not yet due for renewal, use the `--force` flag:

```sh
docker exec -it "$container_name_or_id" sh -c '/app/scripts/signcert-deploy-sendmail.sh --force example.com'

# For multiple domains
docker exec -it "$container_name_or_id" sh -c '/app/scripts/signcert-deploy-sendmail.sh --force example.com example2.com example3.com'
```

### Manually deploy a signed certificate

This can either be done by using the provided script `deploy.sh`

```sh
docker exec -it "$container_name_or_id" sh -c '/app/scripts/deploy.sh example.com'
```

### Manually remove a certificate

This can either be done by using the provided script `removecert.sh`, or manually deleting the domain folder in the `letsencrypt` data folder. For `example.com`, delete the folder named `example.com`

```sh
docker exec -it "$container_name_or_id" sh -c '/app/scripts/removecert.sh example.com'
```

### Read a certificate

```sh
docker exec -it "$container_name_or_id" sh -c '/app/scripts/readcert.sh example.com'
```

## Script behaviour

### `certbot` Certificate Signing stage

Assuming you passed in the necessary environment variables, renewing certs would be as simple as invoking the main script, whether through `docker exec`, or directly inside the container. The script reads environment variables each time it is invoked.

### Deploy stage

The script copies each successfully signed domain certificate, key, full chain, and chain certificates to the folder `/certs`.

To disable this stage, omit the environment variable `DEPLOY_CERTS`.

### Reload stage

The script sends a `SIGHUP` (`1`) to a container with name starting with `TARGET_CONTAINER_NAME`.

When `Swarm Mode` is used, all services go by the naming convention `<stack><service>`. `<stack>` is the name given when using `docker stack up`, and `<service>` is the service key in the `docker-compose.yml` or `docker-stack.yml`. If a container name starts with `<stack><service>`, ignoring the suffix, that container is sent the signal. As an example, if the value of `TARGET_CONTAINER_NAME` variable is `mystack_docker-gen`, the service called `mystack_docker-gen.1.jb2xwgp3ktnmsmp1eo31563jw` is sent the reload signal. The signal is sent to one container only; if multiple containers names match `mystack_docker-gen`, no signal is sent. Therefore keep the container name as unique as possible.

Mounting the `/var/run/docker.sock` is necessary for reloading to take place.

To disable this stage, omit the environment variable `TARGET_CONTAINER_NAME`.

### Email notification stage

This sends a summarized report of all the previous steps and their success status. Only one email is sent each time the script is invoked.

No email is sent in these cases:

1. The email functionality is disabled by omitting `EMAIL_REPORT`
2. One or more email credentials were not specified, among: `EMAIL_FROM`, `EMAIL_TO`, `EMAIL_USER`, `EMAIL_PASSWORD`, `SMTP_SERVER`, `SMTP_PORT`
3. The email credentials were wrong
4. All the given domains' certificates are not due for renewal

Assuming all variables are set correctly, as long as one certificate is obtained / renewed, a summary report will be sent.

To disable this stage, omit the environment variable `EMAIL_REPORT`.

## Development

Requires Windows `powershell` or [`pwsh`](https://github.com/PowerShell/PowerShell).

```powershell
# Install Generate-DockerImageVariants module: https://github.com/theohbrothers/Generate-DockerImageVariants
Install-Module -Name Generate-DockerImageVariants -Repository PSGallery -Scope CurrentUser -Force -Verbose

# Edit ./generate templates

# Generate the variants
Generate-DockerImageVariants .
```

'@
