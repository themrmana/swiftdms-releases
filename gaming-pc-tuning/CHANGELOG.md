# What this branch adds + what's intentionally NOT here

## Added

A self-contained tuning kit under `gaming-pc-tuning/`:

```
gaming-pc-tuning/
├── README.md                                  # Master entry point
├── CHANGELOG.md                               # This file
├── scripts/
│   ├── Run-All.ps1                            # Orchestrator with confirmations + logging
│   ├── 01-create-restore-point.ps1            # Restore point "Pre-GPU-tuning"
│   ├── 02-snapshot-display.ps1                # JSON snapshot of current display state
│   ├── 03-set-display-mode.ps1                # Sets 3840x2160 @ 120Hz via P/Invoke
│   └── 04-prep-nvidia-profile-inspector.ps1   # Downloads NVPI, backs up profile, opens GUI
└── checklists/
    ├── HDR-Toggle.md                          # Manual HDR toggle (Win+Alt+B)
    ├── Part-B-NVIDIA-Profile-Inspector.md     # 3 manual settings + rationale
    ├── Part-C-NVIDIA-app.md                   # G-Sync, RGB Full 10-bit, RTX Video
    ├── Part-D-LG-TV.md                        # TV-side menus (Deep Color, Game mode, etc.)
    ├── Per-Game-Settings.md                   # DLSS / FG / Reflex recipe + per-genre
    └── Verification.md                        # What to check at the end
```

## Automated (with before→after capture)

| Change | Done by | Verification |
|---|---|---|
| System Restore point "Pre-GPU-tuning" | `01-create-restore-point.ps1` | Last 3 restore points printed to log |
| Display state snapshot | `02-snapshot-display.ps1` | JSON before + after written to `logs/` |
| Primary display → 3840×2160 @ 120Hz | `03-set-display-mode.ps1` | Mode tested (CDS_TEST) before commit; re-read post-commit |
| NVPI download + profile backup | `04-prep-nvidia-profile-inspector.ps1` | exe SHA256 + backup `.nip` path logged |

## Intentionally not scripted, with reasons

| Item | Why it's manual |
|---|---|
| **HDR "Use HDR" toggle** | `DisplayConfigSetDeviceInfo` advanced-color signature changed in Win11 24H2 (`AdvancedColorMode` joined `EnableAdvancedColor`); a wrong call can black-screen on signal change. One key press (Win+Alt+B) replaces it. |
| **NVPI: Max Frame Rate / V-Sync / Low Latency Mode** | NVIDIA's setting IDs and value encodings inside `.nip` XML are not part of a stable public API and drift across driver and tool versions. A wrong import can put the profile in a state NVCP can't represent. Three GUI clicks are safer; the script downloads, backs up, and opens the tool so the manual step is 30 seconds. |
| **NVIDIA app: G-Sync enable + RGB Full 10-bit + RTX Video** | Color format / bit depth / dynamic range and G-Sync enablement are registry-driven, signature-shifting, and the most common cause of "I changed something and now the TV is black" reports. Explicit manual list with rationale per item. |
| **LG TV settings (Deep Color, Game mode, FreeSync, Black Level, HGiG, Clarity off)** | No PC-side surface. Must be done with the remote. |
| **Per-game DLSS / Frame Gen / Reflex** | Per-game integration only — driver-forcing breaks the integration. |
| **In-game HDR brightness calibration** | Game-specific, eye-calibrated. |

## Reverting

- Restore point: Control Panel → Recovery → Open System Restore → "Pre-GPU-tuning".
- NVPI: `nvidiaProfileInspector.exe -import gaming-pc-tuning\tools\nvidiaProfileInspector\nvpi-backup-<timestamp>.nip`
- Display mode: re-run `03-set-display-mode.ps1` with values from `logs/display-before-<timestamp>.json`.

## Caveats (read before running)

- These scripts were authored in a Linux container and **have not been
  end-to-end executed on a Windows machine**. Each script logs its actions
  and verifies its own result, but treat the first run as a careful
  walkthrough.
- The `swiftdms-releases` repo is for iOS app releases. This kit is here only
  because the cloud-session instructions directed the push to this repo's
  feature branch. Consider moving the `gaming-pc-tuning/` folder to a more
  appropriate repo before merging anywhere durable.
