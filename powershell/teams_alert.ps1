# ═══════════════════════════════════════════
# Teams Alert Script
# Posts webhook notification to Teams
# Called by health monitor
# Webhook URL from Key Vault
# ═══════════════════════════════════════════

param(
    [Parameter(Mandatory=$true)]
    [string]$HostName,

    [Parameter(Mandatory=$true)]
    [string]$Status,

    [Parameter(Mandatory=$true)]
    [int]$Sessions
)

# Get Teams webhook URL from Key Vault
# Using Managed Identity - zero credentials
$kvName      = "kv-azure-infra-prod"
$secretName  = "teams-webhook-url"

$webhookUrl = (Get-AzKeyVaultSecret `
    -VaultName $kvName `
    -Name $secretName `
    -AsPlainText)

Write-Output "$(Get-Date) - Sending Teams alert for: $HostName"

# Build Teams message card
$body = @{
    "@type"      = "MessageCard"
    "@context"   = "http://schema.org/extensions"
    "themeColor" = "FF0000"
    "summary"    = "AVD Host Unhealthy"
    "sections"   = @(
        @{
            "activityTitle"    = "AVD Health Alert"
            "activitySubtitle" = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') IST"
            "activityImage"    = "https://img.icons8.com/color/48/000000/microsoft.png"
            "facts"            = @(
                @{ "name" = "Host Name";       "value" = $HostName },
                @{ "name" = "Status";          "value" = $Status },
                @{ "name" = "Active Sessions"; "value" = $Sessions },
                @{ "name" = "Action Taken";    "value" = "Host drained - new sessions disabled" },
                @{ "name" = "Host Pool";       "value" = "hp-avd-prod" },
                @{ "name" = "Environment";     "value" = "Production" }
            )
            "markdown" = $true
        }
    )
} | ConvertTo-Json -Depth 10

# Send to Teams via webhook
try {
    Invoke-RestMethod `
        -Uri $webhookUrl `
        -Method Post `
        -ContentType "application/json" `
        -Body $body

    Write-Output "$(Get-Date) - Teams alert sent successfully"
}
catch {
    Write-Output "$(Get-Date) - ERROR: Failed to send Teams alert"
    Write-Output "$(Get-Date) - Error: $_"
}
