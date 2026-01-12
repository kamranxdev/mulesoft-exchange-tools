# MuleSoft Exchange Asset Hard Delete Tool
# File: mulesoft-hard-delete.ps1

param (
    [Parameter(Mandatory=$true, HelpMessage="MuleSoft Username")]
    [string]$USERNAME,

    [Parameter(Mandatory=$true, HelpMessage="MuleSoft Password")]
    [string]$PASSWORD,

    [Parameter(Mandatory=$true, HelpMessage="Organization ID")]
    [string]$ORG_ID,

    [Parameter(Mandatory=$false)]
    [int]$LIMIT = 40,

    [Parameter(Mandatory=$false)]
    [int]$OFFSET = 0,

    [Parameter(Mandatory=$false)]
    [string]$SEARCH = ""
)

# Step 1: Get access token
Write-Host "🔐 Logging in..." -ForegroundColor Cyan

$loginBody = @{
    username = $USERNAME
    password = $PASSWORD
} | ConvertTo-Json

try {
    $tokenResponse = Invoke-RestMethod -Uri "https://anypoint.mulesoft.com/accounts/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody
    
    $TOKEN = $tokenResponse.access_token
    
    if ([string]::IsNullOrEmpty($TOKEN)) {
        Write-Host "❌ Login failed. No access token received." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Token obtained successfully." -ForegroundColor Green
}
catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: List soft deleted assets
Write-Host "`n📋 Fetching soft deleted assets..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "Bearer $TOKEN"
}

$url = "https://anypoint.mulesoft.com/exchange/api/v2/organizations/$ORG_ID/softDeleted?limit=$LIMIT&offset=$OFFSET"
if ($SEARCH) {
    $url += "&search=$SEARCH"
}

try {
    $softDeleted = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    
    Write-Host "`n📦 Soft Deleted Assets:" -ForegroundColor Yellow
    $softDeleted | ConvertTo-Json -Depth 10 | Write-Host
    
    if ($softDeleted.Count -eq 0) {
        Write-Host "`nℹ️  No soft deleted assets found." -ForegroundColor Blue
        exit 0
    }
}
catch {
    Write-Host "❌ Failed to fetch assets: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Interactive delete option
Write-Host "`n⚠️  SELECT ASSET TO HARD DELETE (PERMANENT, NO RECOVERY!)" -ForegroundColor Yellow
Write-Host "=" * 70 -ForegroundColor Yellow

for ($i = 0; $i -lt $softDeleted.Count; $i++) {
    $asset = $softDeleted[$i]
    Write-Host "$($i + 1). $($asset.assetId) v$($asset.version)" -ForegroundColor White
}

Write-Host "`nEnter index number (1-$($softDeleted.Count)) or 'q' to quit: " -NoNewline -ForegroundColor Cyan
$input = Read-Host

if ($input -eq 'q' -or $input -eq 'Q') {
    Write-Host "❌ Cancelled." -ForegroundColor Yellow
    exit 0
}

$index = $null
if ([int]::TryParse($input, [ref]$index)) {
    if ($index -ge 1 -and $index -le $softDeleted.Count) {
        $selectedAsset = $softDeleted[$index - 1]
        $ORG = $selectedAsset.organizationId
        $GROUP = $selectedAsset.groupId
        $ASSET = $selectedAsset.assetId
        $VERSION = $selectedAsset.version
        
        Write-Host "`n⚠️  Deleting $GROUP/$ASSET/$VERSION..." -ForegroundColor Red
        
        $deleteHeaders = @{
            "Authorization" = "Bearer $TOKEN"
            "x-delete-type" = "hard-delete"
        }
        
        # Try primary endpoint
        $deleteUrl = "https://anypoint.mulesoft.com/exchange/api/v2/assets/$GROUP/$ASSET/$VERSION"
        
        try {
            $deleteResponse = Invoke-RestMethod -Uri $deleteUrl `
                -Method Delete `
                -Headers $deleteHeaders `
                -ErrorAction Stop
            
            Write-Host "✅ Hard delete completed successfully!" -ForegroundColor Green
            $deleteResponse | ConvertTo-Json -Depth 10 | Write-Host
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            
            if ($statusCode -eq 404) {
                Write-Host "❌ Delete failed with 404. Trying alternative endpoint..." -ForegroundColor Yellow
                
                # Try alternative endpoint with organization ID
                $altUrl = "https://anypoint.mulesoft.com/exchange/api/v2/organizations/$ORG/assets/$GROUP/$ASSET/$VERSION"
                
                try {
                    $altResponse = Invoke-RestMethod -Uri $altUrl `
                        -Method Delete `
                        -Headers $deleteHeaders `
                        -ErrorAction Stop
                    
                    Write-Host "✅ Hard delete completed via alternative endpoint!" -ForegroundColor Green
                    $altResponse | ConvertTo-Json -Depth 10 | Write-Host
                }
                catch {
                    Write-Host "❌ Alternative endpoint also failed: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "`n💡 Troubleshooting tips:" -ForegroundColor Cyan
                    Write-Host "   - Verify you have 'Exchange Administrator' permissions" -ForegroundColor White
                    Write-Host "   - Check if the asset needs UI-based deletion first" -ForegroundColor White
                    Write-Host "   - Contact MuleSoft support if issue persists" -ForegroundColor White
                }
            }
            else {
                Write-Host "❌ Delete failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "❌ Invalid index. Please enter a number between 1 and $($softDeleted.Count)." -ForegroundColor Red
    }
}
else {
    Write-Host "❌ Invalid input. Cancelled." -ForegroundColor Red
}