# Docker image variants' definitions
$VARIANTS = @(
    @{
        tag = 'cloudflare'
        tag_as_latest = $true
    }
    @{
        tag = 'cloudxns'
    }
    @{
        tag = 'digitalocean'
    }
    @{
        tag = 'dnsimple'
    }
    @{
        tag = 'dnsmadeeasy'
    }
    @{
        tag = 'google'
    }
    @{
        tag = 'linode'
    }
    @{
        tag = 'luadns'
    }
    @{
        tag = 'nsone'
    }
    @{
        tag = 'ovh'
    }
    @{
        tag = 'rfc2136'
    }
    @{
        tag = 'route53'
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
