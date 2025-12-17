param(
    [Parameter(Mandatory = $true)] [string] $TenantId,
    [Parameter(Mandatory = $true)] [string] $ClientId,
    [Parameter(Mandatory = $true)] [string] $ClientSecret,
    [Parameter(Mandatory = $true)] [string] $WorkspaceId,
    [Parameter(Mandatory = $true)] [string] $PbixPath
)

$ErrorActionPreference = "Stop"

Write-Host "🔐 Getting access token..."

$body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://analysis.windows.net/powerbi/api/.default"
}

$tokenResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -Body $body `
    -ContentType "application/x-www-form-urlencoded"

$accessToken = $tokenResponse.access_token
$headers = @{ Authorization = "Bearer $accessToken" }

if (-not (Test-Path $PbixPath)) {
    throw "PBIX file not found at path: $PbixPath"
}

$reportName = [System.IO.Path]::GetFileNameWithoutExtension($PbixPath)

Write-Host "🚀 Uploading PBIX to Power BI workspace..."

$importUrl = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/imports?datasetDisplayName=$reportName&nameConflict=CreateOrOverwrite"

$bytes = [System.IO.File]::ReadAllBytes($PbixPath)

Invoke-RestMethod `
    -Method Post `
    -Uri $importUrl `
    -Headers $headers `
    -ContentType "application/octet-stream" `
    -Body $bytes | Out-Null

Write-Host "✅ Deployment completed successfully!"
