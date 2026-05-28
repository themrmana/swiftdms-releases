#requires -RunAsAdministrator
<#
.SYNOPSIS
  Create a Windows System Restore point named "Pre-GPU-tuning".

.NOTES
  System Protection must be enabled on the system drive, or Checkpoint-Computer
  silently does nothing on some Windows 11 SKUs. The script enables it
  defensively. Windows also rate-limits restore points to one per 24h by default;
  the script lowers SystemRestorePointCreationFrequency for this session so a
  point is actually created if you've made one recently.
#>

[CmdletBinding()]
param(
    [string]$Description = 'Pre-GPU-tuning',
    [string]$LogPath
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $line
    if ($LogPath) { Add-Content -Path $LogPath -Value $line }
}

try {
    Write-Log "Ensuring System Protection is enabled on C:\\"
    try {
        Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
    } catch {
        Write-Log "Enable-ComputerRestore failed (may already be enabled): $($_.Exception.Message)"
    }

    Write-Log "Temporarily lowering SystemRestorePointCreationFrequency to 0"
    $rpKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    if (-not (Test-Path $rpKey)) { New-Item -Path $rpKey -Force | Out-Null }
    $previousFreq = (Get-ItemProperty -Path $rpKey -Name 'SystemRestorePointCreationFrequency' -ErrorAction SilentlyContinue).SystemRestorePointCreationFrequency
    Set-ItemProperty -Path $rpKey -Name 'SystemRestorePointCreationFrequency' -Value 0 -Type DWord

    Write-Log "Creating restore point: '$Description'"
    Checkpoint-Computer -Description $Description -RestorePointType 'MODIFY_SETTINGS'

    if ($null -ne $previousFreq) {
        Set-ItemProperty -Path $rpKey -Name 'SystemRestorePointCreationFrequency' -Value $previousFreq -Type DWord
        Write-Log "Restored previous SystemRestorePointCreationFrequency=$previousFreq"
    } else {
        Remove-ItemProperty -Path $rpKey -Name 'SystemRestorePointCreationFrequency' -ErrorAction SilentlyContinue
        Write-Log "Removed temporary SystemRestorePointCreationFrequency override"
    }

    Write-Log "Most recent restore points:"
    Get-ComputerRestorePoint |
        Select-Object -Last 3 SequenceNumber, Description, CreationTime |
        Format-Table -AutoSize | Out-String | ForEach-Object { Write-Log $_ }

    Write-Log "OK: Restore point '$Description' created."
}
catch {
    Write-Log "FAILED: $($_.Exception.Message)"
    throw
}
