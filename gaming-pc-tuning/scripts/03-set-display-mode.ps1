<#
.SYNOPSIS
  Set the primary display to a requested resolution and refresh rate.

.PARAMETER Width
  Horizontal resolution. Default 3840.

.PARAMETER Height
  Vertical resolution. Default 2160.

.PARAMETER RefreshHz
  Refresh rate in Hz. Default 120.

.PARAMETER DeviceName
  Optional. If multiple displays are connected and you don't want the primary,
  pass the device name (e.g. "\\.\DISPLAY1") shown by 02-snapshot-display.ps1.

.PARAMETER WhatIf
  Show what would happen without changing the mode.

.NOTES
  Uses ChangeDisplaySettingsEx via P/Invoke. The driver decides whether to
  accept the mode. If the LG TV's HDMI Ultra HD Deep Color is OFF on this port,
  Windows will report DISP_CHANGE_BADMODE when asking for 4K @ 120Hz — that is
  the canonical signal that you need to fix the TV side first.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$Width = 3840,
    [int]$Height = 2160,
    [int]$RefreshHz = 120,
    [string]$DeviceName,
    [string]$LogPath
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $line
    if ($LogPath) { Add-Content -Path $LogPath -Value $line }
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class DisplaySet {
    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern int ChangeDisplaySettingsEx(string deviceName, ref DEVMODE devMode, IntPtr hwnd, int dwFlags, IntPtr lParam);

    public const int ENUM_CURRENT_SETTINGS = -1;
    public const int CDS_TEST = 0x00000002;
    public const int CDS_UPDATEREGISTRY = 0x00000001;
    public const int DM_PELSWIDTH = 0x00080000;
    public const int DM_PELSHEIGHT = 0x00100000;
    public const int DM_DISPLAYFREQUENCY = 0x00400000;

    public const int DISP_CHANGE_SUCCESSFUL = 0;
    public const int DISP_CHANGE_RESTART = 1;
    public const int DISP_CHANGE_FAILED = -1;
    public const int DISP_CHANGE_BADMODE = -2;
    public const int DISP_CHANGE_NOTUPDATED = -3;
    public const int DISP_CHANGE_BADFLAGS = -4;
    public const int DISP_CHANGE_BADPARAM = -5;
    public const int DISP_CHANGE_BADDUALVIEW = -6;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels;
        public short dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }
}
"@

function Decode-ChangeResult {
    param([int]$Code)
    switch ($Code) {
        0  { 'SUCCESSFUL' }
        1  { 'RESTART_REQUIRED' }
        -1 { 'FAILED' }
        -2 { 'BADMODE (driver/TV does not accept this mode — check HDMI Ultra HD Deep Color on the LG)' }
        -3 { 'NOTUPDATED (registry write failed)' }
        -4 { 'BADFLAGS' }
        -5 { 'BADPARAM' }
        -6 { 'BADDUALVIEW' }
        default { "Unknown ($Code)" }
    }
}

try {
    $dm = New-Object DisplaySet+DEVMODE
    $dm.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($dm)

    $target = if ($DeviceName) { $DeviceName } else { $null }

    Write-Log ("Querying current mode for {0}" -f ($(if ($target) { $target } else { '<primary>' })))
    if ([DisplaySet]::EnumDisplaySettings($target, [DisplaySet]::ENUM_CURRENT_SETTINGS, [ref]$dm) -eq 0) {
        throw "EnumDisplaySettings returned 0 (no current mode)."
    }
    Write-Log ("  Current: {0}x{1} @ {2}Hz, {3}bpp" -f $dm.dmPelsWidth, $dm.dmPelsHeight, $dm.dmDisplayFrequency, $dm.dmBitsPerPel)

    if ($dm.dmPelsWidth -eq $Width -and $dm.dmPelsHeight -eq $Height -and $dm.dmDisplayFrequency -eq $RefreshHz) {
        Write-Log "Already at target mode; nothing to do."
        return
    }

    $dm.dmPelsWidth = $Width
    $dm.dmPelsHeight = $Height
    $dm.dmDisplayFrequency = $RefreshHz
    $dm.dmFields = [DisplaySet]::DM_PELSWIDTH -bor [DisplaySet]::DM_PELSHEIGHT -bor [DisplaySet]::DM_DISPLAYFREQUENCY

    Write-Log ("Testing mode {0}x{1} @ {2}Hz" -f $Width, $Height, $RefreshHz)
    $testResult = [DisplaySet]::ChangeDisplaySettingsEx($target, [ref]$dm, [IntPtr]::Zero, [DisplaySet]::CDS_TEST, [IntPtr]::Zero)
    Write-Log "  Test result: $(Decode-ChangeResult $testResult)"
    if ($testResult -ne 0) {
        throw "Mode test failed: $(Decode-ChangeResult $testResult). Aborting before commit."
    }

    if ($PSCmdlet.ShouldProcess("$target", "Apply mode $Width x $Height @ ${RefreshHz}Hz")) {
        Write-Log "Applying mode (UPDATEREGISTRY)"
        $applyResult = [DisplaySet]::ChangeDisplaySettingsEx($target, [ref]$dm, [IntPtr]::Zero, [DisplaySet]::CDS_UPDATEREGISTRY, [IntPtr]::Zero)
        Write-Log "  Apply result: $(Decode-ChangeResult $applyResult)"
        if ($applyResult -ne 0 -and $applyResult -ne 1) {
            throw "Failed to apply mode: $(Decode-ChangeResult $applyResult)"
        }

        Start-Sleep -Seconds 2

        # Read back
        if ([DisplaySet]::EnumDisplaySettings($target, [DisplaySet]::ENUM_CURRENT_SETTINGS, [ref]$dm) -ne 0) {
            Write-Log ("  Active now: {0}x{1} @ {2}Hz, {3}bpp" -f $dm.dmPelsWidth, $dm.dmPelsHeight, $dm.dmDisplayFrequency, $dm.dmBitsPerPel)
            if ($dm.dmPelsWidth -ne $Width -or $dm.dmPelsHeight -ne $Height -or $dm.dmDisplayFrequency -ne $RefreshHz) {
                throw "Mode was accepted by ChangeDisplaySettingsEx but read-back differs from request. STOP and investigate before continuing."
            }
            Write-Log "OK: Target mode is active."
        }
    }
}
catch {
    Write-Log "FAILED: $($_.Exception.Message)"
    throw
}
