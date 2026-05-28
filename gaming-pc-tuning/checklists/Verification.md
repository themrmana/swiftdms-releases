# Verification

## Already verified by the scripts (check the log)

The log file under `gaming-pc-tuning/logs/tuning-<timestamp>.log` should
contain, in order:

- `Restore point 'Pre-GPU-tuning' created.`
- A "before" snapshot of the display (`display-before-<timestamp>.json`).
- `Apply result: SUCCESSFUL` and `Active now: 3840x2160 @ 120Hz` for the
  primary display.
- An NVPI backup path (`nvpi-backup-<timestamp>.nip`) and the SHA256 of the
  `nvidiaProfileInspector.exe` that was used.
- An "after" snapshot of the display.

If any of those are missing or differ from the target, re-run the relevant
script before continuing. In particular, `3840x2160 @ 120Hz` on a different
device than expected means the wrong monitor was treated as primary — pass
`-DeviceName "\\.\DISPLAYn"` to `03-set-display-mode.ps1` using the name
from the `before` snapshot.

## To verify by hand

### Resolution + refresh

- **Settings → System → Display → Advanced display**.
- "Display information" panel: confirm **Active signal mode: 3840 × 2160,
  120.000 Hz**, **Bit depth: 10-bit** (or 8-bit if Part C step 2 fell back),
  **Color format: RGB**, **Color space: standard sRGB** (when SDR) or
  **HDR** badge present (when HDR is on).

### HDR

- Same page, **"Use HDR" = On**, **"Stream HDR video" = On**.
- On the TV, a brief HDR badge appears top-right when input switches to the
  PC.

### G-Sync (the most important check)

- **NVIDIA app → System → Display → G-SYNC**: the LG NANO86 row shows
  **G-SYNC Compatible (Not Validated)** with the checkbox ticked.
- Turn on the **G-Sync status indicator**:
  - NVIDIA app: **Settings → Performance overlay** (or in the classic NVCP:
    **Display → G-SYNC → "G-SYNC compatible indicator"**).
  - It overlays "G-Sync: ON" in the top-left when active.
- Launch any GPU-bound game. The indicator should say **G-Sync: ON**. The
  in-game frame counter should hover at or near **116 fps** (the cap), never
  exceeding it.
- Drop into a frame-rate-variable area (a forest, a particle-heavy scene).
  Watch a high-contrast vertical edge during fast camera pans — there should
  be no tearing.

### Latency feel

- The desktop cursor should feel "stuck to the panel". If it feels slightly
  swimmy, V-Sync is somehow doubled up — check that the in-game V-Sync is
  Off (Per-Game-Settings.md), and that Low Latency Mode is actually Ultra in
  NVPI (Part B step 3).
- NVIDIA Reflex Analyzer (in the overlay) is the empirical version of this if
  you want a number — reports PC + display latency. Anything under ~25 ms
  end-to-end at the cap is on target.

### Color

- Open a pure-black image fullscreen. The panel should look pitch black, with
  no obvious blocky lifting in dark areas (those would indicate Limited-range
  signal into a Full-range TV setting, or vice versa — recheck Part C step 2
  vs Part D step 5).
- Open a pure-white image. In HDR it should be eye-watering; in SDR it should
  look like paper at the SDR brightness slider value.

### What "all good" looks like in one line

> Windows reports `3840x2160 @ 120.000 Hz, 10 bpc, RGB`, HDR On, G-Sync overlay
> says "ON" in a game, the in-game framerate sits at 116, dark scenes have
> no flicker, blacks are clean, the TV badge says "HDR Game".

If you can say all of that, you're done.
