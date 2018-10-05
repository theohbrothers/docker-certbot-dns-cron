$GENERATE_BASE_DIR = $PSScriptRoot
$TEMPLATES_DIR = Join-Path $GENERATE_BASE_DIR "templates"
$PROJECT_BASE_DIR = Split-Path $GENERATE_BASE_DIR -Parent

cd $GENERATE_BASE_DIR

$PLUGINS = @"
cloudflare
cloudxns
digitalocean
dnsimple
dnsmadeeasy
google
linode
luadns
nsone
ovh
rfc2136
route53
"@.Split("`n") | % { $_.Trim() }


function Get-ContentFromTemplate {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Plugin
    ,
        [switch]$Secret
    ,
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ })]
        [string]$TemplatePath
    )
    & $TemplatePath
}
function Generate-DockerFileContextFiles {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Plugin
    ,
        [string]$Destination
    )
    New-Item $Destination -ItemType Directory -Force -ErrorAction SilentlyContinue > $null
    if (Test-Path $Destination) {
        Get-ContentFromTemplate -Plugin $Plugin -Secret:$Secret -TemplatePath "$TEMPLATES_DIR/Dockerfile.ps1" | Out-File "$Destination/Dockerfile" -Encoding utf8
        Copy-Item "$PROJECT_BASE_DIR/app" $Destination -Recurse -Force
        Copy-Item "$TEMPLATES_DIR/docker-entrypoint.sh" $Destination -Recurse -Force
        Copy-Item "$TEMPLATES_DIR/crontab" $Destination -Recurse -Force
    }
}
function Generate-ExampleFiles {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Plugin
    ,
        [switch]$Secret
    ,
        [ValidateNotNullOrEmpty()]
        [string]$Destination
    )
    New-Item $Destination -ItemType Directory -Force -ErrorAction SilentlyContinue > $null
    if (Test-Path $Destination) {
        $suffix = if ($Secret) { '-secret' } else { '' }
        Get-ContentFromTemplate -Plugin $Plugin -Secret:$Secret -TemplatePath "$TEMPLATES_DIR/docker-compose.yml.ps1" | Out-File "$Destination/docker-compose$suffix.yml" -Encoding utf8
        Copy-Item -Path "$TEMPLATES_DIR/plugins/$PLUGIN/dns_$( $Plugin )_credentials.ini" -Destination $Destination
    }
}

foreach ($plugin in $PLUGINS) {
    $PLUGIN_DIR = "$PROJECT_BASE_DIR/variants/$Plugin"
    $PLUGIN_BUILD_DIR = "$PLUGIN_DIR/build"

    Generate-ExampleFiles -Plugin $plugin -Destination $PLUGIN_DIR
    Generate-ExampleFiles -Plugin $plugin -Secret -Destination $PLUGIN_DIR
    Generate-DockerFileContextFiles -Plugin $plugin -Destination $PLUGIN_BUILD_DIR
}