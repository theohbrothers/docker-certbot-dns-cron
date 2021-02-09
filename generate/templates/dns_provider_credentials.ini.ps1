#
# This file is unused.
#
# It is preferred use the individual template files dns_<provider>_credentials.ini.ps1 instead, which will allow us to generate the same .ini file for all subvariants of the variant.
#
$content = switch ($variant['_metadata']['package'] ) {

    'cloudflare' {
        @'
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = cloudflare@example.com
dns_cloudflare_api_key = 0123456789abcdef0123456789abcdef01234567
'@
    }

    'cloudxns' {
        @'
# CloudXNS API credentials used by Certbot
dns_cloudxns_api_key = 1234567890abcdef1234567890abcdef
dns_cloudxns_secret_key = 1122334455667788
'@
    }

    'digitalocean' {
        @'
# DigitalOcean API credentials used by Certbot
dns_digitalocean_token = 0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff
'@
    }

    'dnsimple' {
        @'
# DNSimple API credentials used by Certbot
dns_dnsimple_token = MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAw
'@
    }

    'dnsmadeeasy' {
        @'
# DNS Made Easy API credentials used by Certbot
dns_dnsmadeeasy_api_key = 1c1a3c91-4770-4ce7-96f4-54c0eb0e457a
dns_dnsmadeeasy_secret_key = c9b5625f-9834-4ff8-baba-4ed5f32cae55
'@
    }

    'google' {
        @'
{
  "type": "service_account",
  ...
}

'@
    }

    'linode' {
        @'
# Linode API credentials used by Certbot
dns_linode_key = 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ64
'@
    }

    'luadns' {
        @'
# LuaDNS API credentials used by Certbot
dns_luadns_email = user@example.com
dns_luadns_token = 0123456789abcdef0123456789abcdef
'@
    }

    'nsone' {
        @'
# NS1 API credentials used by Certbot
dns_nsone_api_key = MDAwMDAwMDAwMDAwMDAw
'@
    }

    'luadns' {
        @'
# LuaDNS API credentials used by Certbot
dns_luadns_email = user@example.com
dns_luadns_token = 0123456789abcdef0123456789abcdef
'@
    }

    'ovh' {
        @'
# OVH API credentials used by Certbot
dns_ovh_endpoint = ovh-eu
dns_ovh_application_key = MDAwMDAwMDAwMDAw
dns_ovh_application_secret = MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAw
dns_ovh_consumer_key = MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAw
'@
    }

    'rfc2136' {
        @'
# Target DNS server
dns_rfc2136_server = 192.0.2.1
# Target DNS port
dns_rfc2136_port = 53
# TSIG key name
dns_rfc2136_name = keyname.
# TSIG key secret
dns_rfc2136_secret = 4q4wM/2I180UXoMyN4INVhJNi8V9BCV+jMw2mXgZw/CSuxUT8C7NKKFs AmKd7ak51vWKgSl12ib86oQRPkpDjg==
# TSIG key algorithm
dns_rfc2136_algorithm = HMAC-SHA512
'@
    }

    'route53' {
        @'
[default]
aws_access_key_id=AKIAIOSFODNN7EXAMPLE
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
'@
    }

    default {}
}

$content
