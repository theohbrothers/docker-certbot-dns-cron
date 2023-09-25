# Docker image variants' definitions
$local:PACKAGES = @(
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
$local:PACKAGE_VERSIONS = @(
    '1.12.0'
    '1.11.0'
    '1.10.1'
    '1.9.0'
    # '1.8.0'
    # '1.7.0'
    # '1.6.0'
    # '1.5.0'
    # '1.4.0'
    # '1.4.0'
    # '1.3.0'
    # '1.2.0'
    # '1.1.0'
    # '1.0.0'
    # '0.40.1'
)
$VARIANTS = @(
    foreach ($package in $local:PACKAGES) {
        foreach ($package_version in $local:PACKAGE_VERSIONS) {
            @{
                _metadata = @{
                    package = $package
                    package_version = $package_version
                    platforms = 'linux/amd64'
                    job_group_key = $package_version
                }
                tag = "v$package_version-$package"
                # The latest cloudflare image will be tagged :latest. E.g. v1.12.0-cloudflare
                tag_as_latest = if ($package -eq 'cloudflare' -and $package_version -eq $local:PACKAGE_VERSIONS[0]) { $true } else { $false }
                buildContextFiles = @{
                    templates = @{
                        'Dockerfile' = @{
                            common = $true
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
                                    generatedFileNameOverride = 'docker-stack.yml'
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
