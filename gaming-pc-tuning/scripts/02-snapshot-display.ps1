<#
.SYNOPSIS
  Snapshot the current Windows display state to JSON so it can be reverted.

.DESCRIPTION
  Writes the current resolution, refresh rate, bit depth, orientation, and
  HDR (advanced color) state of every connected display to a JSON file.
  HDR state is queried via DisplayConfig APIs through Get-WmiObject /
  registry as a best-effort, since there is no public WMI class for it.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OutPath,
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

public class DisplaySnapshot {
    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

    public const int ENUM_CURRENT_SETTINGS = -1;

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

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DISPLAY_DEVICE {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }
}
"@

function Get-HdrState {
    # Best-effort: Windows stores advanced-color state under per-monitor keys in
    # HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration\*.
    # Value name "AdvancedColorEnabled" = 1 when HDR is on.
    $hdrStates = @{}
    try {
        $cfg = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration' -ErrorAction Stop
        foreach ($k in $cfg) {
            $sub = Get-ChildItem $k.PSPath -Recurse -ErrorAction SilentlyContinue
            foreach ($s in $sub) {
                $val = Get-ItemProperty -Path $s.PSPath -ErrorAction SilentlyContinue
                if ($val.PSObject.Properties.Name -contains 'AdvancedColorEnabled') {
                    $hdrStates[$s.PSChildName] = [bool]$val.AdvancedColorEnabled
                }
            }
        }
    } catch {
        Write-Log "Could not read HDR state from registry: $($_.Exception.Message)"
    }
    return $hdrStates
}

try {
    $devices = @()
    $i = 0
    while ($true) {
        $dd = New-Object DisplaySnapshot+DISPLAY_DEVICE
        $dd.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($dd)
        if (-not [DisplaySnapshot]::EnumDisplayDevices($null, $i, [ref]$dd, 0)) { break }

        if ($dd.StateFlags -band 1) { # DISPLAY_DEVICE_ACTIVE
            $dm = New-Object DisplaySnapshot+DEVMODE
            $dm.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($dm)
            if ([DisplaySnapshot]::EnumDisplaySettings($dd.DeviceName, [DisplaySnapshot]::ENUM_CURRENT_SETTINGS, [ref]$dm) -ne 0) {
                $devices += [pscustomobject]@{
                    DeviceName    = $dd.DeviceName.Trim()
                    Description   = $dd.DeviceString.Trim()
                    Width         = $dm.dmPelsWidth
                    Height        = $dm.dmPelsHeight
                    RefreshHz     = $dm.dmDisplayFrequency
                    BitsPerPixel  = $dm.dmBitsPerPel
                    Orientation   = $dm.dmDisplayOrientation
                    PositionX     = $dm.dmPositionX
                    PositionY     = $dm.dmPositionY
                }
            }
        }
        $i++
    }

    $snapshot = [pscustomobject]@{
        TakenAt   = (Get-Date).ToString('o')
        Displays  = $devices
        HdrPerKey = Get-HdrState
    }

    $snapshot | ConvertTo-Json -Depth 6 | Set-Content -Path $OutPath -Encoding UTF8
    Write-Log "Wrote display snapshot to $OutPath"

    foreach ($d in $devices) {
        Write-Log ("  {0} -> {1}x{2} @ {3}Hz, {4}bpp" -f $d.DeviceName, $d.Width, $d.Height, $d.RefreshHz, $d.BitsPerPixel)
    }
}
catch {
    Write-Log "FAILED: $($_.Exception.Message)"
    throw
}
