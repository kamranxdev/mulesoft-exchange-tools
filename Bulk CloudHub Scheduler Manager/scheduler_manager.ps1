<#
.SYNOPSIS
    Bulk CloudHub Scheduler Manager
    Enables bulk Start/Stop of CloudHub application schedules based on name patterns.

.DESCRIPTION
    This script connects to the Anypoint Platform and lists applications in a specific Environment
    that match a regex pattern. For matching applications, it iterates through their schedules
    and enables (START) or disables (STOP) them.

.PARAMETER Username
    MuleSoft Username.

.PARAMETER Password
    MuleSoft Password.

.PARAMETER EnvId
    Environment ID.

.PARAMETER Action
    Action to perform: START or STOP.

.PARAMETER Pattern
    Regex pattern to match application names (e.g., '.*-dev').

.PARAMETER DryRun
    Simulate the action without applying changes.

.EXAMPLE
    .\scheduler_manager.ps1 -Username "user" -Password "pass" -EnvId "env1" -Action "STOP" -Pattern ".*-dev" -DryRun
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="MuleSoft Username")]
    [string]$Username,

    [Parameter(Mandatory=$true, HelpMessage="MuleSoft Password")]
    [string]$Password,

    [Parameter(Mandatory=$true, HelpMessage="Environment ID")]
    [string]$EnvId,

    [Parameter(Mandatory=$true, HelpMessage="Action: START or STOP")]
    [ValidateSet("START", "STOP")]
    [string]$Action,

    [Parameter(Mandatory=$true, HelpMessage="Regex pattern for app names")]
    [string]$Pattern,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

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
        "X-ANYPNT-ENV-ID" = $EnvId
        "Content-Type" = "application/json"
    }

    Write-Host "🔎 Listing applications in Environment $EnvId matching pattern '$Pattern'..." -ForegroundColor Cyan

    # List Applications (CloudHub 1.0 API)
    $appsUrl = "https://anypoint.mulesoft.com/cloudhub/api/v2/applications"
    $apps = Invoke-RestMethod -Uri $appsUrl -Method Get -Headers $headers

    foreach ($app in $apps) {
        if ($app.domain -match $Pattern) {
            Write-Host "👉 Found target app: $($app.domain)" -ForegroundColor Yellow
            
            # Get Schedules
            $schedulesUrl = "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/$($app.domain)/schedules"
            
            try {
                $schedules = Invoke-RestMethod -Uri $schedulesUrl -Method Get -Headers $headers
                
                foreach ($sched in $schedules) {
                    Write-Host "   ⏰ Schedule: $($sched.name) ($($sched.id))" -ForegroundColor White
                    
                    if ($DryRun) {
                        Write-Host "      [DRY RUN] Would $Action schedule $($sched.id)" -ForegroundColor Gray
                    }
                    else {
                        Write-Host "      🚀 $Action-ing schedule $($sched.id)..." -NoNewline -ForegroundColor Cyan
                        
                        $enabledVal = $true
                        if ($Action -eq "STOP") {
                            $enabledVal = $false
                        }
                        
                        $updateBody = @{
                            enabled = $enabledVal
                        } | ConvertTo-Json

                        $updateUrl = "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/$($app.domain)/schedules/$($sched.id)"
                        
                        $null = Invoke-RestMethod -Uri $updateUrl -Method Put -Headers $headers -Body $updateBody
                        
                        Write-Host " Done." -ForegroundColor Green
                    }
                }
            }
            catch {
                Write-Host "   ⚠️  Failed to fetch/update schedules for app $($app.domain): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`n✅ Bulk Operation Completed." -ForegroundColor Green
}
catch {
    Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
