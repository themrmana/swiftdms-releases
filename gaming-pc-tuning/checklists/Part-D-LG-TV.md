# Part D — LG NANO86 (49NANO86UNA) TV menus (manual, remote)

These settings live in the TV's webOS menus. There is no LAN API on this
model that can flip them, and even if there were, none of this can be done
from the PC. Walk the remote.

## 1. Cable + port

- The PC must be on **HDMI 3** or **HDMI 4** (these are the HDMI 2.1 ports on
  the NANO86). HDMI 1/2 are 2.0 and cap out at 4K/60.
- Use a **certified Ultra High Speed (48 Gbps) HDMI cable**. A 4K/60 cable
  will *appear* to work but will fall back to 4K/60 or YCbCr 4:2:0 silently.
  If 120Hz won't engage and Deep Color (step 2) is on, this is the next
  suspect.

## 2. HDMI ULTRA HD Deep Color → On for the PC's port (THE MASTER SWITCH)

This is the single most-likely thing blocking 4K/120, VRR, and HDR.

- Remote: **Settings (gear) → All Settings → General → Devices → HDMI Settings**.
  (On older webOS firmware: **General → HDMI Ultra HD Deep Color**.)
- For **HDMI 3** (and **HDMI 4** if you might move the cable), flip
  **Deep Color** to **On**.
- The TV will flash through a signal renegotiation when you toggle this. Wait
  10–15 seconds.
- This unlocks: 4K @ 120 Hz, VRR (FreeSync/G-Sync Compatible), HDR10, and
  RGB Full at 10-bit.

## 3. Picture mode → Game

- **Settings → Picture → Select Mode → Game** (when input is the PC).
- This enables low-latency mode (the panel skips most post-processing) and is
  required for VRR to fully engage on this set.
- The badge in the top-right will change to "Game" (or "HDR Game" once HDR is
  on).

## 4. FreeSync → Wide

- **Settings → Picture → Game Optimizer → AMD FreeSync Premium**
  (or **Game Adjust → FreeSync** on older firmware) → **Wide**.
- "Wide" gives the larger VRR window the NANO86 supports.
- If you see flicker in dark scenes (a known LG VRR quirk on some HDR titles),
  switch this to **High** instead — it narrows the VRR window in exchange for
  steadier brightness.
- Despite the menu name saying "AMD", this is what NVIDIA's G-Sync Compatible
  binds to on this TV.

## 5. Black Level → High

- **Settings → Picture → Advanced Settings → HDMI Black Level** for the
  PC's input → **High**.
- "High" = 0–255 (Full range). Matches the **RGB / Full** that the NVIDIA app
  is now sending (Part C step 2). If this is left on **Low** (16–235, Limited)
  while the PC sends Full, blacks will be crushed and highlights clipped.

## 6. HDR processing → HGiG

- Enter an HDR title (or anywhere that triggers HDR mode — pull up an HDR
  YouTube video to force it).
- **Settings → Picture → Advanced Settings → Brightness → Dynamic Tone
  Mapping → HGiG**.
- HGiG = the panel honors the game's PQ curve as-is and does no extra
  tone mapping. Games that expose an HDR calibration screen will calibrate
  correctly only in HGiG. "On" (Active HDR) double-tone-maps; "Off" clips.

## 7. Clarity/processing off

- **Settings → Picture → Advanced Settings → Clarity**:
  - **Super Resolution** → **Off**
  - **Noise Reduction** → **Off**
  - **MPEG Noise Reduction** → **Off**
  - **Sharpness** → **default neutral** (around 10 on this set; do not boost)
- These add latency and degrade pixel-perfect game/desktop output.

## 8. HDR engages automatically

Don't look for an HDR toggle on the TV — there isn't one for input HDR. The
TV switches into HDR mode the moment the PC sends an HDR signal (after Part C
+ HDR toggle), and the picture mode label changes from **"Game"** to
**"HDR Game"**.

## If 120Hz still won't engage after all of this

1. Recheck step 2 on the **specific** port the PC is on.
2. Try the other HDMI 2.1 port (3 ↔ 4).
3. Try a different Ultra High Speed cable.
4. In NVIDIA app → Display, click **"Customize…"** and confirm 3840×2160
   @ 120 Hz appears under the PC-defined / Ultra HD, HD, SD list. If it
   doesn't, the driver isn't seeing a 4K/120-capable link → cable or Deep
   Color.
