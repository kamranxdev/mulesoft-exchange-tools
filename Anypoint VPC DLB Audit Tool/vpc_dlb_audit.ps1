<#
.SYNOPSIS
    Anypoint VPC & DLB Audit Tool
    Exports configurations for all VPCs and DLBs in an Organization.

.DESCRIPTION
    This script connects to the Anypoint Platform and retrieves configuration details for Virtual Private Clouds (VPCs)
    and Dedicated Load Balancers (DLBs) associated with a specific Organization ID.
    The output is saved as a JSON file.

.PARAMETER Username
    MuleSoft Username.

.PARAMETER Password
    MuleSoft Password.

.PARAMETER OrgId
    Organization ID (VPCs are Org-level).

.PARAMETER OutputFile
    Output JSON file path (Default: vpc_dlb_audit.json).

.EXAMPLE
    .\vpc_dlb_audit.ps1 -Username "myuser" -Password "mypass" -OrgId "org123"
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="MuleSoft Username")]
    [string]$Username,

    [Parameter(Mandatory=$true, HelpMessage="MuleSoft Password")]
    [string]$Password,

    [Parameter(Mandatory=$true, HelpMessage="Organization ID")]
    [string]$OrgId,

    [Parameter(Mandatory=$false, HelpMessage="Output JSON file")]
    [string]$OutputFile = "vpc_dlb_audit.json"
)

# Error handling
$ErrorActionPreference = "Stop"

try {
    # Authentication
    Write-Host "🔐 Authenticating..." -ForegroundColor Cyan
    
    $loginBody = @{
        username = $Username
        password = $Password
    } | ConvertTo-Json

    $tokenResponse = Invoke-RestMethod -Uri "https://anypoint.mulesoft.com/accounts/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody
    
    $accessToken = $tokenResponse.access_token
    
    if ([string]::IsNullOrEmpty($accessToken)) {
        throw "Authentication failed. Access token is empty."
    }
    
    Write-Host "✅ Authentication successful." -ForegroundColor Green

    # Headers for subsequent requests
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "X-ANYPNT-ORG-ID" = $OrgId
    }

    # Fetch VPCs
    Write-Host "☁️  Fetching VPCs..." -ForegroundColor Cyan
    $vpcs = Invoke-RestMethod -Uri "https://anypoint.mulesoft.com/cloudhub/api/vpcs" `
        -Method Get `
        -Headers $headers

    # Fetch DLBs
    Write-Host "⚖️  Fetching DLBs..." -ForegroundColor Cyan
    $dlbs = Invoke-RestMethod -Uri "https://anypoint.mulesoft.com/cloudhub/api/vpcs/load-balancers" `
        -Method Get `
        -Headers $headers

    # Generate Report
    Write-Host "📄 Generating Audit Report..." -ForegroundColor Cyan

    $report = @{
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        organizationId = $OrgId
        vpcs = $vpcs
        loadBalancers = $dlbs
    }

    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding utf8

    Write-Host "✅ Audit Complete. Report saved to $OutputFile" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
