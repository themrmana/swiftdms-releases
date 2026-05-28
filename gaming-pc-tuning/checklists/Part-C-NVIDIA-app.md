# Part C — NVIDIA app (manual, GUI)

These changes live in the **NVIDIA app** (the unified replacement for GeForce
Experience + NVIDIA Control Panel). They're manual because the registry/CLI
surface for color format, bit depth, dynamic range, and G-Sync enablement is
fragile: a wrong write can produce a black screen on the next signal change or
silently switch the TV to YCbCr 4:2:0, which is what we're trying to avoid.

## 0. Confirm driver

- **NVIDIA app → Drivers**.
- Make sure the latest **Game Ready Driver** is installed (Studio drivers are
  fine but Game Ready is the right channel for this use case).
- Reboot if a fresh driver was just installed before doing anything else here.

## 1. G-Sync Compatible — enable for this TV

- **NVIDIA app → System → Display → G-SYNC** (older builds: "Set up G-SYNC"
  in the left sidebar).
- Toggle **Enable G-SYNC, G-SYNC Compatible** → **On**.
- Pick **"Enable for windowed and full-screen mode"**.
- In the per-display list, the LG NANO86 will most likely appear with a
  *"Not validated as G-SYNC Compatible"* warning. That's expected for this
  panel — tick **"Enable settings for the selected display model"** anyway.
  It works as G-Sync Compatible over HDMI 2.1.
- **Apply.**

## 2. Color settings — RGB, Full range, 10-bit if available

- **NVIDIA app → System → Display → Resolution** (older builds: "Change
  resolution").
- Select the LG NANO86.
- Resolution: **3840 × 2160**, Refresh: **120 Hz**. (Should already be set
  by the script — confirm.)
- Output color format: **RGB**.
- Output dynamic range: **Full**.
- Output color depth: **10 bpc** if it's selectable at 4K/120Hz RGB Full.
  If the dropdown is greyed at 8 bpc, leave it at 8 bpc — the TV is signalling
  that 10-bit RGB at 120Hz won't fit the link, which happens unless HDMI 2.1
  Deep Color is on. Fix the TV side (Part D step 2) and re-check.
- **Apply.**

## 3. Video — RTX Video

- **NVIDIA app → Graphics → Video** (or the **Video** tab under Display in
  some builds).
- **RTX Video Super Resolution** → **On**, quality **4 (highest)**.
- **RTX Video HDR** → **On** if you want SDR video sources tone-mapped to HDR
  for the TV. Optional. It only fires for video in browsers / supported
  players; it doesn't affect games or desktop.
- **Apply.**

## 4. Sanity check: NVIDIA Control Panel parity (if you still use it)

- The classic NVIDIA Control Panel and the NVIDIA app sometimes drift on these
  values. Open NVCP → "Change resolution" and confirm RGB / Full / 10 bpc
  match what you set in the NVIDIA app. They should — if they don't, the NVCP
  value is the one the driver is using; re-set there.
