param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$ClientSecret,

    [Parameter(Mandatory = $true)]
    [string]$WorkspaceId,

    [Parameter(Mandatory = $true)]
    [string]$PbixPath
)

$ErrorActionPreference = "Stop"

Write-Host "🔐 Getting Azure AD access token..."

# ===============================
# 1️⃣ Get Access Token
# ===============================
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://analysis.windows.net/powerbi/api/.default"
}

$tokenResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -Body $tokenBody `
    -ContentType "application/x-www-form-urlencoded"

$accessToken = $tokenResponse.access_token

$headers = @{
    Authorization = "Bearer $accessToken"
}

# ===============================
# 2️⃣ Validate PBIX File
# ===============================
if (!(Test-Path $PbixPath)) {
    throw "❌ PBIX file not found at path: $PbixPath"
}

$reportName = [System.IO.Path]::GetFileNameWithoutExtension($PbixPath)

Write-Host "📦 PBIX file found: $reportName"

# ===============================
# 3️⃣ Upload PBIX (CORRECT FORMAT)
# ===============================
Write-Host "🚀 Uploading PBIX to Power BI workspace..."

$importUrl = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/imports?datasetDisplayName=$reportName&nameConflict=CreateOrOverwrite"

$fileBytes = [System.IO.File]::ReadAllBytes($PbixPath)
$fileName  = [System.IO.Path]::GetFileName($PbixPath)

$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$body = (
    "--$boundary",
    "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
    "Content-Type: application/octet-stream$LF",
    [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes),
    "--$boundary--$LF"
) -join $LF

$headers["Content-Type"] = "multipart/form-data; boundary=$boundary"

Invoke-RestMethod `
    -Method Post `
    -Uri $importUrl `
    -Headers $headers `
    -Body $body

Write-Host "✅ PBIX upload request submitted successfully!"
