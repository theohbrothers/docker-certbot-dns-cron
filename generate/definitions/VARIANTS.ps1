# Docker image variants' definitions
$local:VARIANTS_PACKAGES = @(
    'cloudflare'
    'cloudxns'
    'digitalocean'
    'dnsimple'
    'dnsmadeeasy'
    'google'
    'linode'
    'luadns'
    'nsone'
    'ovh'
    'rfc2136'
    'route53'
)
$VARIANTS = @(
    $VARIANTS_PACKAGES | % {
        @{
            _metadata = @{
                package = $_
                package_version = 'v1.12.0'
            }
            tag = "v1.12.0-$_"
            tag_as_latest = if ($_ -eq 'cloudflare') { $true } else { $false }
        }
    }
)

# Docker image variants' definitions (shared)
$VARIANTS_SHARED = @{
    version = $VARIANTS_VERSION
    buildContextFiles = @{
        templates = @{
            'Dockerfile' = @{
                common = $true
                #includeHeader = $true
                #includeFooter = $true
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
            'docker-entrypoint.sh' = @{
                common = $true
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
            'docker-compose.yml' = @{
                common = $true
                passes = @(
                    @{
                        variables = @{
                            Secret = $false
                        }
                    }
                    @{
                        variables = @{
                            Secret = $true
                        }
                        generatedFileNameOverride = 'docker-compose-secret.yml'
                    }
                )
            }
            'crontab' = @{
                common = $true
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
        }
        copies = @(
            '/app'
            '*.ini'
        )
     }
}

# Send definitions down the pipeline
$VARIANTS
