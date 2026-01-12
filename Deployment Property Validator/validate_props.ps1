<#
.SYNOPSIS
    Deployment Property Validator
    Scans MuleSoft project code for placeholders like ${http.port} and checks if they exist in a property file.

.DESCRIPTION
    This script recursively scans a MuleSoft project directory for '.xml' and '.dwl' files to find
    property placeholders in the format '${variable}'. It then checks a specified YAML or Properties
    file to ensure that each found key is defined.

.PARAMETER Project
    Path to the MuleSoft project directory.

.PARAMETER Properties
    Path to the YAML/Properties file to check against.

.EXAMPLE
    .\validate_props.ps1 -Project "C:\MuleSoft\MyProject" -Properties "C:\MuleSoft\MyProject\src\main\resources\dev.yaml"
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Path to the MuleSoft project directory")]
    [string]$Project,

    [Parameter(Mandatory=$true, HelpMessage="Path to the properties file")]
    [string]$Properties
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Properties)) {
    Write-Host "❌ Error: Property file '$Properties' not found." -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Scanning '$Project' for property placeholders..." -ForegroundColor Cyan

# Find placeholders
# Regex checks for ${...} but excludes closing brace inside
# PowerShell's Select-String is similar to grep
$files = Get-ChildItem -Path $Project -Recurse -Include "*.xml", "*.dwl"

$placeholders = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    # Regex to capture ${key}
    $matches = [regex]::Matches($content, '\$\{([^}]+)\}')
    foreach ($match in $matches) {
        $placeholders += $match.Groups[1].Value
    }
}

$uniquePlaceholders = $placeholders | Select-Object -Unique | Sort-Object

Write-Host "📋 Found the following placeholders in code:" -ForegroundColor Yellow
$uniquePlaceholders | ForEach-Object { Write-Host "  - $_" }

if ($uniquePlaceholders.Count -eq 0) {
    Write-Host "ℹ️  No placeholders found."
    exit 0
}

Write-Host "`n🕵️  Validating against $Properties..." -ForegroundColor Cyan

$propContent = Get-Content $Properties -Raw
$missingCount = 0

foreach ($key in $uniquePlaceholders) {
    if ([string]::IsNullOrWhiteSpace($key)) { continue }

    # Check for "key:" (YAML) or "key=" (Properties) or "key ="
    # Also check quoted "key":
    # Simple regex check on the file content
    $pattern = "(?m)^(\s*)$([regex]::Escape($key))[:=]|""$([regex]::Escape($key))""[:=]"
    
    if ($propContent -match $pattern) {
        # Found
    }
    else {
        Write-Host "  ❌ [MISSING] Property '$key' is used in code but NOT found in property file." -ForegroundColor Red
        $missingCount++
    }
}

if ($missingCount -gt 0) {
    Write-Host "`n❌ FAILURE: Found $missingCount missing properties." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "`n✅ SUCCESS: All placeholders appear to be defined." -ForegroundColor Green
    exit 0
}
