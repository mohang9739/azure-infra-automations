# ═══════════════════════════════════════════
# AVD Health Monitor
# Runs every 15 minutes via cron
# Connects using Managed Identity
# Checks session host health state
# ═══════════════════════════════════════════

param(
    [string]$ResourceGroupName = "rg-spoke-avd-prod",
    [string]$HostPoolName      = "hp-avd-prod",
    [string]$SubscriptionId    = "fc284f47-d0f0-42bd-bb95-23f440135331"
)

# Connect using Managed Identity
# Zero credentials - no passwords
Connect-AzAccount -Identity

# Set subscription context
Set-AzContext -SubscriptionId $SubscriptionId

Write-Output "$(Get-Date) - Starting AVD health check for: $HostPoolName"

# Get all session hosts in host pool
$sessionHosts = Get-AzWvdSessionHost `
    -ResourceGroupName $ResourceGroupName `
    -HostPoolName $HostPoolName

if (-not $sessionHosts) {
    Write-Output "$(Get-Date) - No session hosts found in pool"
    exit 0
}

Write-Output "$(Get-Date) - Found $($sessionHosts.Count) session hosts"

# Check each host for unhealthy state
foreach ($host in $sessionHosts) {
    $hostName = $host.Name.Split("/")[-1]
    $status   = $host.Status
    $sessions = $host.Session

    Write-Output "$(Get-Date) - Host: $hostName | Status: $status | Sessions: $sessions"

    # NeedsAssistance = unhealthy state
    if ($status -eq "NeedsAssistance") {
        Write-Output "$(Get-Date) - UNHEALTHY HOST DETECTED: $hostName"

        # Call drain script
        & "$PSScriptRoot/avd_drain_host.ps1" `
            -ResourceGroupName $ResourceGroupName `
            -HostPoolName $HostPoolName `
            -SessionHostName $hostName

        # Send Teams alert
        & "$PSScriptRoot/teams_alert.ps1" `
            -HostName $hostName `
            -Status $status `
            -Sessions $sessions
    }
}

Write-Output "$(Get-Date) - Health check complete"
