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
$local:VARIANTS_PACKAGES_VERSIONS = @(
    'v1.12.0'
)
$VARIANTS = @(
    foreach ($package in $local:VARIANTS_PACKAGES) {
        foreach ($package_version in $local:VARIANTS_PACKAGES_VERSIONS) {
            @{
                _metadata = @{
                    package = $package
                    package_version = $package_version
                }
                tag = "$package_version-$package"
                # The latest cloudflare image will be tagged :latest. E.g. v1.12.0-cloudflare
                tag_as_latest = if ($package -eq 'cloudflare' -and $package_version -eq $local:VARIANTS_PACKAGES_VERSIONS[0]) { $true } else { $false }


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
                        "dns_$( $package )_credentials.ini" = @{
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
                    )
                 }
            }
        }
    }
)

# Docker image variants' definitions (shared)
$VARIANTS_SHARED = @{
}

# Send definitions down the pipeline
$VARIANTS
