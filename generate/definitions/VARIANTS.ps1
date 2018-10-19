# Docker image variants' definitions
$VARIANTS_VERSION = "1.0.0"
$VARIANTS = @(
    @{
        name = 'cloudflare'
    }
    @{
        name = 'cloudxns'
    }
    @{
        name = 'digitalocean'
    }
    @{
        name = 'dnsimple'
    }
    @{
        name = 'dnsmadeeasy'
    }
    @{
        name = 'google'
    }
    @{
        name = 'linode'
    }
    @{
        name = 'luadns'
    }
    @{
        name = 'nsone'
    }
    @{
        name = 'ovh'
    }
    @{
        name = 'rfc2136'
    }
    @{
        name = 'route53'
    }
)

# Docker image variants' definitions (shared)
$VARIANTS_SHARED = @{
    buildContextFiles = @{
        templates = @{
            'Dockerfile' = @{
                common = $true
                #includeHeader = $true
                #includeVariant = $true
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

# Intelligently add properties
$VARIANTS | % {
    $VARIANT = $_
    $VARIANT['version'] = $VARIANTS_VERSION
    $VARIANTS_SHARED.GetEnumerator() | % {
        $VARIANT[$_.Name] =  $_.Value
    }
}

# Send definitions down the pipeline
$VARIANTS