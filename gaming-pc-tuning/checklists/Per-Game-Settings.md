# Per-game settings (manual, in each game's menu)

Generic recipe that's right for almost any modern title on this rig.

## In every game

| Setting | Value | Why |
|---|---|---|
| Display mode | Fullscreen exclusive (or Borderless on titles that route through the compositor for HDR — DX12/Vulkan usually fine either way) | Lets G-Sync engage cleanly |
| Resolution | 3840 × 2160 | Native panel res; DLSS will internally render lower |
| V-Sync (in-game) | **Off** | Driver V-Sync (Part B) is the backstop; in-game V-Sync usually adds queue depth |
| Frame rate cap (in-game) | **Off** | Part B's 116 fps driver cap handles it. If a game has its own cap that's strictly enforced (e.g. matches Reflex), set that to 116 instead — either is fine, just don't stack two different caps |
| HDR (in-game) | **On** | Required for the HDR signal Pat C/HDR enables to be filled |
| HDR peak brightness calibration | Use the in-game slider on the brightest "barely visible" pattern; the NANO86 peaks around 600–700 nits HDR — that's the number to target | HGiG (Part D step 6) only works if you set it honestly |

## DLSS / Frame Gen / Reflex (where supported)

| Setting | Value |
|---|---|
| **DLSS Super Resolution** | **Quality** (drop to **Balanced** in heavy titles if 116 fps isn't sustained) |
| **DLSS Multi Frame Generation** | **2×** |
| **NVIDIA Reflex** | **On** (or **On + Boost** for competitive titles) |
| Frame Gen + native Reflex | Always keep Reflex On when Frame Gen is On — it counteracts the latency added by interpolation |

Do NOT force DLSS / Frame Gen / Reflex globally from the driver — they need
the game's own integration to insert frames correctly.

## SDR content in HDR mode

When HDR is on system-wide, Windows tone-maps SDR content (Notepad, the web,
desktop apps) to HDR. Calibrate this once:

- **Settings → System → Display → HDR → SDR content brightness**.
- Drag the slider until a white SDR window looks like a paper-white page, not
  a flashbang. On the NANO86 this lands roughly at 35–45 / 100 depending on
  room light.

## Per-genre tweaks

- **Competitive shooters** (Apex/CS2/Valorant/OW2): Reflex **On + Boost**;
  drop DLSS to **Performance** to maximize input rate; turn Frame Gen **Off**
  (the extra latency isn't worth it competitively).
- **Single-player / cinematic** (CP2077/AW2/HL2 RTX): DLSS **Quality**,
  Frame Gen **2×**, ray-tracing maxed out — the 116 fps cap and G-Sync will
  smooth what the GPU actually produces.
- **VRR-sensitive HDR titles** (some Forza/CoD HDR builds): if you see
  brightness flicker in dark scenes, switch the TV's FreeSync from
  **Wide** to **High** (Part D step 4) — that narrows the VRR window enough
  to suppress the flicker.
