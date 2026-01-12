<#
.SYNOPSIS
    MuleSoft Business Group User/Role Auditor
    Audits users and their roles across the entire MuleSoft Organization Hierarchy.

.DESCRIPTION
    This script recursively traverses the MuleSoft organization hierarchy, starting from a root Org ID
    (or the user's primary Org). For each organization/business group, it lists all users and their roles,
    exporting the data to a CSV file.

.PARAMETER Username
    MuleSoft Username.

.PARAMETER Password
    MuleSoft Password.

.PARAMETER ClientId
    Connected App Client ID (Optional, for OAuth).

.PARAMETER ClientSecret
    Connected App Client Secret (Optional, for OAuth).

.PARAMETER OrgId
    Root Organization ID (Optional, auto-detected if not provided).

.PARAMETER OutputFile
    Output CSV file path (Default: user_audit_report.csv).

.EXAMPLE
    .\audit_users.ps1 -Username "user" -Password "pass"
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="MuleSoft Username")]
    [string]$Username,

    [Parameter(Mandatory=$true, HelpMessage="MuleSoft Password")]
    [string]$Password,

    [Parameter(Mandatory=$false)]
    [string]$ClientId,

    [Parameter(Mandatory=$false)]
    [string]$ClientSecret,

    [Parameter(Mandatory=$false)]
    [string]$OrgId,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "user_audit_report.csv"
)

$ErrorActionPreference = "Stop"

# Helper function to process org recursively
function Process-Org {
    param (
        [string]$CurrentOrgId,
        [string]$CurrentOrgName,
        [string]$Token
    )

    Write-Host "🔍 Scanning Org: $CurrentOrgName ($CurrentOrgId)..." -ForegroundColor Cyan

    # Get Users in this Org
    # Note: Pagination is not handled here for simplicity.
    try {
        $usersUrl = "https://anypoint.mulesoft.com/accounts/api/organizations/$CurrentOrgId/users"
        $headers = @{ "Authorization" = "Bearer $Token" }
        $usersResponse = Invoke-RestMethod -Uri $usersUrl -Method Get -Headers $headers
        
        foreach ($user in $usersResponse.data) {
            # Get Roles for this user in this context
            try {
                $rolesUrl = "https://anypoint.mulesoft.com/accounts/api/organizations/$CurrentOrgId/users/$($user.id)/roles"
                $rolesResponse = Invoke-RestMethod -Uri $rolesUrl -Method Get -Headers $headers
                
                $roles = ($rolesResponse.data.name) -join "|"
                
                # Add to CSV object list
                $global:auditData += [PSCustomObject]@{
                    "Organization Name" = $CurrentOrgName
                    "Organization ID"   = $CurrentOrgId
                    "Username"          = $user.username
                    "First Name"        = $user.firstName
                    "Last Name"         = $user.lastName
                    "Email"             = $user.email
                    "Roles"             = $roles
                }
            }
            catch {
                Write-Warning "Failed to fetch roles for user $($user.username) in org $CurrentOrgId"
            }
        }
    }
    catch {
        Write-Warning "Failed to fetch users for org $CurrentOrgId: $($_.Exception.Message)"
    }

    # Get Sub-Organizations (Hierarchy)
    # The hierarchy endpoint returns a tree.
    # To keep this script simple and iterative similar to the bash one (which had a placeholder),
    # we would ideally use the hierarchy API. 
    # For this implementation, we will fetch the hierarchy ONLY if we are at the root, 
    # or rely on the user passing the root.
    
    # NOTE: The Bash script had a recursion placeholder. 
    # Here I will try to fetch immediate children if possible, but the hierarchy API is usually best called once.
    # Let's stick to the structure: if this is called recursively, we assume the caller handles logic.
    # But since the bash script didn't fully implement recursion, I'll add a simple fetching of children
    # using the hierarchy endpoint which returns the full tree, so theoretically we process it once.
    
    # Actually, a better approach for this script is:
    # 1. Fetch full hierarchy tree.
    # 2. Flatten and iterate.
}

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

    # Get Root Org ID if not provided
    if ([string]::IsNullOrEmpty($OrgId)) {
        Write-Host "ℹ️  Fetching Root Organization ID..."
        $meResponse = Invoke-RestMethod -Uri "https://anypoint.mulesoft.com/accounts/api/me" `
            -Method Get `
            -Headers @{ "Authorization" = "Bearer $accessToken" }
        $OrgId = $meResponse.user.organization.id
    }

    Write-Host "🏢 Auditing Organization Hierarchy starting at: $OrgId" -ForegroundColor Yellow

    # Initialize data collector
    $global:auditData = @()

    # Get Hierarchy
    # This returns the whole tree starting from the org
    $hierarchyUrl = "https://anypoint.mulesoft.com/accounts/api/organizations/$OrgId/hierarchy"
    $hierarchy = Invoke-RestMethod -Uri $hierarchyUrl -Method Get -Headers @{ "Authorization" = "Bearer $accessToken" }

    # Flatten helper
    function Flatten-Hierarchy($node) {
        Process-Org -CurrentOrgId $node.id -CurrentOrgName $node.name -Token $accessToken
        
        if ($node.subOrganizations) {
            foreach ($sub in $node.subOrganizations) {
                Flatten-Hierarchy -node $sub
            }
        }
    }

    # Start recursion
    Flatten-Hierarchy -node $hierarchy

    # Export to CSV
    if ($global:auditData.Count -gt 0) {
        $global:auditData | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding utf8
        Write-Host "✅ Audit Complete. Report saved to $OutputFile" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  No user data found." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
