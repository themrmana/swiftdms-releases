# Gaming PC tuning: RTX 5080 → LG NANO86 (49NANO86UNA) at 4K/120/HDR/VRR

Target end-state on the Windows 11 PC driving the TV:

- 3840 × 2160 @ 120 Hz
- HDR on (Use HDR)
- G-Sync Compatible (VRR) active, tear-free, low latency
- RGB Full, 10-bit if available
- NVIDIA app + Profile Inspector configured
- LG TV's HDMI Ultra HD Deep Color enabled on the PC port, Game mode, FreeSync Wide

## Why this is split into scripts + checklists

The original spec required that anything not safe to automate go on a manual list. This is what came out of that:

| Part | What | How |
|------|------|-----|
| A | Windows display (restore point, snapshot, resolution + refresh) | `scripts/` (PowerShell) |
| B | NVIDIA Profile Inspector — download + backup current profile | `scripts/04-prep-nvidia-profile-inspector.ps1` |
| B (cont.) | NVIDIA Profile Inspector — applying the 3 settings | `checklists/Part-B-NVIDIA-Profile-Inspector.md` (manual via the tool's GUI; see "Why not scripted" in that file) |
| C | NVIDIA app — G-Sync, color, RTX Video | `checklists/Part-C-NVIDIA-app.md` |
| D | LG TV menus | `checklists/Part-D-LG-TV.md` |
| HDR | Toggling Use HDR | `checklists/HDR-Toggle.md` (manual; optional helper noted) |
| Game | Per-game settings | `checklists/Per-Game-Settings.md` |
| Verify | What to check at the end | `checklists/Verification.md` |

## How to run

On the Windows PC, from an **elevated PowerShell** (Run as administrator):

```powershell
cd <path-to-this-folder>\scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Run-All.ps1
```

`Run-All.ps1` runs the scripts in order, logging everything to `..\logs\tuning-<timestamp>.log` and writing a before/after JSON snapshot of the display state. It will pause for confirmation before any change.

After scripts finish, work through the manual checklists in this order:

1. `checklists/HDR-Toggle.md`
2. `checklists/Part-B-NVIDIA-Profile-Inspector.md`
3. `checklists/Part-C-NVIDIA-app.md`
4. `checklists/Part-D-LG-TV.md` (with the remote)
5. `checklists/Per-Game-Settings.md` (in each game)
6. `checklists/Verification.md`

## Honest caveats

- These scripts were authored in a remote Linux container and have **not been executed end-to-end on a Windows machine**. Each step is small, idempotent where possible, and logs before/after — but treat the first run as a careful walkthrough, not a one-shot.
- If 120 Hz refuses to take after step 03, that almost always means **HDMI Ultra HD Deep Color is off on the LG**, or the cable isn't a true 48 Gbps Ultra High Speed cable. The PC can't fix either. See `checklists/Part-D-LG-TV.md` step 2.
- HDR toggle and NVPI setting changes are intentionally left manual. See the rationale in their respective files.

## Reverting

- Windows restore point: created in step 01, named `Pre-GPU-tuning`. Use **Control Panel → Recovery → Open System Restore** if needed.
- NVPI profile: backed up in step 04 as `nvpi-backup-<timestamp>.nip` next to the tool. Re-import with `nvidiaProfileInspector.exe -import <file>`.
- Display mode: the original mode is captured in step 02 as JSON. Re-run `03-set-display-mode.ps1 -Width <w> -Height <h> -RefreshHz <hz>` with those values.
