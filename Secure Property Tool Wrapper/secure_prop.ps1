<#
.SYNOPSIS
    Secure Property Tool Wrapper
    A simple wrapper for the MuleSoft Secure Properties Tool JAR.
    Simplifies the syntax for encrypting and decrypting strings.

.DESCRIPTION
    Wrapper around the 'secure-properties-tool.jar' provided by MuleSoft.
    Requires Java to be installed (which is standard for MuleSoft developers).

.PARAMETER Action
    encrypt or decrypt.

.PARAMETER Key
    Your encryption key.

.PARAMETER Value
    The string to encrypt/decrypt.

.PARAMETER Algorithm
    (Optional) Blowfish (default), AES, ACES, etc.

.PARAMETER Mode
    (Optional) CBC (default), CFB, ECB, OFB.

.PARAMETER JarPath
    Path to secure-properties-tool.jar. Defaults to looking in current directory.

.EXAMPLE
    .\secure_prop.ps1 -Action encrypt -Key "mykey" -Value "mysecret"
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("encrypt", "decrypt")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$Key,

    [Parameter(Mandatory=$true)]
    [string]$Value,

    [Parameter(Mandatory=$false)]
    [string]$Algorithm = "Blowfish",

    [Parameter(Mandatory=$false)]
    [string]$Mode = "CBC",

    [Parameter(Mandatory=$false)]
    [string]$JarPath = ".\secure-properties-tool.jar"
)

$ErrorActionPreference = "Stop"

# Check Java
try {
    $null = java -version 2>&1
}
catch {
    Write-Host "❌ Error: Java is not installed or not in PATH." -ForegroundColor Red
    exit 1
}

# Check JAR
if (-not (Test-Path $JarPath)) {
    Write-Host "❌ Error: Secure Properties Tool JAR not found at '$JarPath'." -ForegroundColor Red
    Write-Host "Please download it from MuleSoft and place it here, or specify via -JarPath"
    exit 1
}

Write-Host "🔧 Running MuleSoft Secure Properties Tool ($Action)..." -ForegroundColor Cyan

# Execute Java command
try {
    # Syntax: java -jar secure-properties-tool.jar string <action> <algorithm> <mode> <key> <value>
    $output = java -jar $JarPath string $Action $Algorithm $Mode $Key $Value 2>&1
    
    # In PowerShell, invoking a console app outputs an array of strings. 
    # Just outputting it is enough, but let's make it distinct.
    Write-Host "`n$output" -ForegroundColor Green
}
catch {
    Write-Host "❌ Execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
