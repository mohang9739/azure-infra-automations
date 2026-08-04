# ═══════════════════════════════════════════
# AVD Drain Host Script
# Called by health monitor
# Safely removes host from rotation
# No forced disconnections
# ═══════════════════════════════════════════

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$HostPoolName,

    [Parameter(Mandatory=$true)]
    [string]$SessionHostName
)

Write-Output "$(Get-Date) - Starting drain for: $SessionHostName"

# Step 1: Disable new sessions
# AllowNewSession = false
# No new users can connect
Update-AzWvdSessionHost `
    -ResourceGroupName $ResourceGroupName `
    -HostPoolName $HostPoolName `
    -Name $SessionHostName `
    -AllowNewSession:$false

Write-Output "$(Get-Date) - New sessions disabled for: $SessionHostName"

# Step 2: Wait for existing sessions to drain
$maxWaitMinutes = 30
$waited = 0

while ($waited -lt $maxWaitMinutes) {
    $host = Get-AzWvdSessionHost `
        -ResourceGroupName $ResourceGroupName `
        -HostPoolName $HostPoolName `
        -Name $SessionHostName

    $activeSessions = $host.Session

    Write-Output "$(Get-Date) - Active sessions remaining: $activeSessions"

    if ($activeSessions -eq 0) {
        Write-Output "$(Get-Date) - All sessions drained. Host safe for maintenance."
        break
    }

    # Wait 1 minute before checking again
    Start-Sleep -Seconds 60
    $waited++
}

if ($waited -ge $maxWaitMinutes) {
    Write-Output "$(Get-Date) - WARNING: Drain timeout after $maxWaitMinutes minutes"
    Write-Output "$(Get-Date) - Sessions still active - manual intervention required"
}

Write-Output "$(Get-Date) - Drain complete for: $SessionHostName"
