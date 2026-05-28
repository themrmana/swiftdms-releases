<#
.SYNOPSIS
  Download NVIDIA Profile Inspector (Orbmu2k) from its official GitHub release,
  verify it, back up the current driver profile, then open the GUI for manual
  application of the three settings listed in the Part B checklist.

.DESCRIPTION
  This script intentionally does NOT script the three setting changes (frame
  rate limit, V-Sync, low-latency mode). NVIDIA's setting IDs and value
  encodings inside .nip XML are not part of a stable public API and have
  shifted across driver and tool versions. A wrong import can leave the
  profile in a confusing state across reboots. See the explanation at the top
  of checklists/Part-B-NVIDIA-Profile-Inspector.md.

  What this script DOES automate:
    1. Downloads the latest nvidiaProfileInspector release from GitHub.
    2. Extracts to .\tools\nvidiaProfileInspector
    3. Exports the current global/base profile to a timestamped backup.
    4. Launches the GUI for you to make the three changes.
#>

[CmdletBinding()]
param(
    [string]$ToolsDir,
    [string]$LogPath,
    [switch]$LaunchGui = $true
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $line
    if ($LogPath) { Add-Content -Path $LogPath -Value $line }
}

if (-not $ToolsDir) {
    $ToolsDir = Join-Path $PSScriptRoot '..\tools\nvidiaProfileInspector'
}
$ToolsDir = [System.IO.Path]::GetFullPath($ToolsDir)
$zipPath = Join-Path $env:TEMP 'nvidiaProfileInspector.zip'
$exePath = Join-Path $ToolsDir 'nvidiaProfileInspector.exe'

try {
    if (-not (Test-Path $ToolsDir)) {
        New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
    }

    if (-not (Test-Path $exePath)) {
        Write-Log "Looking up latest NVIDIA Profile Inspector release..."
        $headers = @{ 'User-Agent' = 'gaming-pc-tuning-script'; 'Accept' = 'application/vnd.github+json' }
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Orbmu2k/nvidiaProfileInspector/releases/latest' -Headers $headers
        $asset = $release.assets | Where-Object { $_.name -match '\.zip$' } | Select-Object -First 1
        if (-not $asset) { throw "No .zip asset on latest release ($($release.tag_name))." }

        Write-Log "Downloading $($asset.name) from $($release.tag_name)"
        Invoke-WebRequest -Uri $asset.browser_download_url -Headers $headers -OutFile $zipPath
        Write-Log "Extracting to $ToolsDir"
        Expand-Archive -Path $zipPath -DestinationPath $ToolsDir -Force
        Remove-Item $zipPath -Force
    } else {
        Write-Log "NVIDIA Profile Inspector already present at $exePath"
    }

    if (-not (Test-Path $exePath)) {
        # Some releases extract into a subfolder; find the exe.
        $found = Get-ChildItem -Path $ToolsDir -Recurse -Filter 'nvidiaProfileInspector.exe' | Select-Object -First 1
        if ($found) { $exePath = $found.FullName; Write-Log "Located exe at $exePath" }
        else { throw "nvidiaProfileInspector.exe not found after extraction." }
    }

    # File hash for the log (so the user has a record of what version was used).
    $hash = Get-FileHash -Path $exePath -Algorithm SHA256
    Write-Log "exe SHA256: $($hash.Hash)"

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = Join-Path $ToolsDir "nvpi-backup-$stamp.nip"
    Write-Log "Exporting current global profile to $backupPath"
    $p = Start-Process -FilePath $exePath -ArgumentList @('-export', "`"$backupPath`"") -PassThru -Wait -WindowStyle Hidden
    if ($p.ExitCode -ne 0) {
        Write-Log "Profile Inspector export exited with $($p.ExitCode). Continuing anyway."
    }
    if (Test-Path $backupPath) {
        $sz = (Get-Item $backupPath).Length
        Write-Log "Backup written ($sz bytes)."
    } else {
        Write-Log "WARNING: backup file not found. Driver may have no custom global profile yet, or export failed."
    }

    if ($LaunchGui) {
        Write-Log "Launching NVIDIA Profile Inspector GUI. Apply the three settings from Part-B checklist, click the disk icon to save, then close the window."
        Start-Process -FilePath $exePath
    }

    Write-Log "OK: NVIDIA Profile Inspector prepared. Backup: $backupPath"
}
catch {
    Write-Log "FAILED: $($_.Exception.Message)"
    throw
}
