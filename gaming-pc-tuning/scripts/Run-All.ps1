#requires -RunAsAdministrator
<#
.SYNOPSIS
  Orchestrator for the gaming PC tuning scripts. Runs in order, logs to a
  timestamped file, and pauses for confirmation before each change.

.PARAMETER NonInteractive
  Skip the per-step confirmation prompts. Use with caution.
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $root 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logPath = Join-Path $logDir "tuning-$stamp.log"
$beforeSnap = Join-Path $logDir "display-before-$stamp.json"
$afterSnap  = Join-Path $logDir "display-after-$stamp.json"

function Log {
    param([string]$Message)
    $line = "[{0}] [Run-All] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $line -ForegroundColor Cyan
    Add-Content -Path $logPath -Value $line
}

function Confirm-Step {
    param([string]$Description)
    if ($NonInteractive) { return $true }
    Write-Host ""
    Write-Host "About to: $Description" -ForegroundColor Yellow
    $answer = Read-Host "Continue? [Y/n]"
    return ($answer -eq '' -or $answer -match '^[Yy]')
}

Log "Tuning run started. Log: $logPath"
Log "PC: $env:COMPUTERNAME  User: $env:USERNAME  Windows: $((Get-CimInstance Win32_OperatingSystem).Caption)"

try {
    # --- Step 1: Restore point
    if (Confirm-Step "create a System Restore point named 'Pre-GPU-tuning'") {
        & (Join-Path $PSScriptRoot '01-create-restore-point.ps1') -LogPath $logPath
    } else { Log "SKIPPED step 01 by user." }

    # --- Step 2: Snapshot current display state
    if (Confirm-Step "snapshot current display state to $beforeSnap") {
        & (Join-Path $PSScriptRoot '02-snapshot-display.ps1') -OutPath $beforeSnap -LogPath $logPath
    } else { Log "SKIPPED step 02 by user." }

    # --- Step 3: Set display mode
    if (Confirm-Step "set primary display to 3840 x 2160 @ 120Hz") {
        & (Join-Path $PSScriptRoot '03-set-display-mode.ps1') -Width 3840 -Height 2160 -RefreshHz 120 -LogPath $logPath
    } else { Log "SKIPPED step 03 by user." }

    # --- Step 4: NVPI prep
    if (Confirm-Step "download NVIDIA Profile Inspector, back up the current profile, and open the GUI") {
        & (Join-Path $PSScriptRoot '04-prep-nvidia-profile-inspector.ps1') -LogPath $logPath
        Log "Reminder: apply the three settings from checklists\Part-B-NVIDIA-Profile-Inspector.md in the GUI now, then save."
    } else { Log "SKIPPED step 04 by user." }

    # --- Step 5: Snapshot after
    if (Confirm-Step "snapshot final display state to $afterSnap") {
        & (Join-Path $PSScriptRoot '02-snapshot-display.ps1') -OutPath $afterSnap -LogPath $logPath
    } else { Log "SKIPPED final snapshot." }

    Log "=== AUTOMATED STEPS COMPLETE ==="
    Log "Now work through the manual checklists in this order:"
    Log "  1. checklists\HDR-Toggle.md"
    Log "  2. checklists\Part-B-NVIDIA-Profile-Inspector.md (if not done in step 4)"
    Log "  3. checklists\Part-C-NVIDIA-app.md"
    Log "  4. checklists\Part-D-LG-TV.md (with the remote)"
    Log "  5. checklists\Per-Game-Settings.md (in each game)"
    Log "  6. checklists\Verification.md"
    Log ""
    Log "Before/after JSON: $beforeSnap  ->  $afterSnap"
    Log "Full log: $logPath"
}
catch {
    Log "RUN FAILED: $($_.Exception.Message)"
    Log "Log file: $logPath"
    throw
}
