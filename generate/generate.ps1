# This script generates the each Docker image variants' build context files' in ./variants/<variant>

$GENERATE_BASE_DIR = $PSScriptRoot
$GENERATE_TEMPLATES_DIR = Join-Path $GENERATE_BASE_DIR "templates"
$GENERATE_DEFINITIONS_DIR = Join-Path $GENERATE_BASE_DIR "definitions"
$PROJECT_BASE_DIR = Split-Path $GENERATE_BASE_DIR -Parent

$ErrorActionPreference = 'Stop'

cd $GENERATE_BASE_DIR

# Get variants' definition
$VARIANTS = & (Join-Path $GENERATE_DEFINITIONS_DIR "VARIANTS.ps1")

# Get files' definition
$FILES = &(Join-Path $GENERATE_DEFINITIONS_DIR "FILES.ps1")

function Get-ContentFromTemplate {
    param (
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path
    ,
        [ValidateRange(1,100)]
        [int]$PrependNewLines
    )
    $content = & $Path
    if ($PrependNewLines -gt 0) {
        1..($PrependNewLine) | % {
            $content = "`n$content"
        }
    }
    $content
}
function Get-ContextFileContent {
    param (
        [string]$TemplateFile
    ,
        [string]$TemplateDirectory
    ,
        [switch]$Header
    ,
        [array]$SubTemplates
    ,
        [switch]$Footer
    ,
        [hashtable]$TemplatePassVariables
    )

    # This special variable will be used throughout templates
    $PASS_VARIABLES = if ($TemplatePassVariables) { $TemplatePassVariables } else { @{} }

    if ( $Header ) {
        Get-ContentFromTemplate -Path "$TemplateDirectory/$TemplateFile.header.ps1"
    }

    if ( $SubTemplates -is [array] -and $SubTemplates.Count -gt 1) {
        $SubTemplates | % {
            Get-ContentFromTemplate -Path "$TemplateDirectory/$TemplateFile/$_/$_.ps1" -PrependNewLines 2
        }
    }else {
        Get-ContentFromTemplate -Path "$TemplateDirectory/$TemplateFile.ps1"
    }

    if ( $Footer ) {
        Get-ContentFromTemplate -Path "$TemplateDirectory/$TemplateFile.footer.ps1"
    }
}

# Generate each Docker image variant's build context files
$VARIANTS | % {
    $VARIANT = $_
    $VARIANT_DIR = "$PROJECT_BASE_DIR/variants/$($VARIANT['name'])"

    "Generating variant of name $( $VARIANT['name'] ), variant dir: $VARIANT_DIR" | Write-Host -ForegroundColor Green
    if ( ! (Test-Path $VARIANT_DIR) ) {
        New-Item -Path $VARIANT_DIR -ItemType Directory -Force > $null
    }

    # Generate Docker build context files
    if ( $VARIANT['buildContextFiles'] ) {
        # Templates
        if ( $VARIANT['buildContextFiles']['templates'] -and $VARIANT['buildContextFiles']['templates'] -is [hashtable] ) {
            $VARIANT['buildContextFiles']['templates'].GetEnumerator() | % {
                $templateFile = $_.Key
                $templateFileConfig = $_.Value
                $templateObject = @{
                    TemplateFile = $templateFile
                    TemplateDirectory = $GENERATE_TEMPLATES_DIR
                    Header = if ( $templateFileConfig['includeHeader'] ) { $true } else { $false }
                    # Dynamically determine the sub templates from the name of the variant. (E.g. 'foo-bar' will comprise of foo and bar variant sub templates for this template file)
                    SubTemplates = $VARIANT['name'] -split '-' | % { $_.Trim() } | ? { $_ } | ? { $_ -ne $VARIANT['distro'] }
                    Footer = if ( $templateFileConfig['includeFooter'] ) { $true } else { $false }
                }

                $generatedFile = "$VARIANT_DIR/$templateFile"
                $templateFileConfig['passes'] | % {
                    $pass = $_
                    $templateObject['TemplatePassVariables'] = if ( $pass['variables'] ) { $pass['variables'] } else { @() }
                    $generatedFile = if ( $pass['generatedFileNameOverride'] ) { "$VARIANT_DIR/$( $pass['generatedFileNameOverride'] )" } else { $generatedFile }
                    $generatedFileContent = Get-ContextFileContent @templateObject
                    $generatedFileContent | Out-File $generatedFile -Encoding Utf8 -Force -NoNewline
                }
            }
        }

        # Copies
        if ( $VARIANT['buildContextFiles']['copies'] ) {
            $VARIANT['buildContextFiles']['copies'] | % {
                $blob = $_.Trim()
                # Any blob starting with '/' means we will
                if ($blob -match '^\/') {
                    $fullPathBlob = Join-Path $PROJECT_BASE_DIR $blob
                }else {
                    $fullPathBlob = "$GENERATE_TEMPLATES_DIR/variants/$( $VARIANT['name'] )/$blob"
                }
                Copy-Item -Path $fullPathBlob -Destination $VARIANT_DIR -Force -Recurse
            }
        }
    }

}

# Generate other repo files
$FILES | % {
    # Generate README.md
    Get-ContentFromTemplate -Path (Join-Path $GENERATE_TEMPLATES_DIR "$_.ps1") | Out-File (Join-Path $PROJECT_BASE_DIR $_) -Encoding utf8 -NoNewline
}