# HDR toggle (manual)

## Why not scripted

Toggling "Use HDR" reliably on Windows 11 requires `DisplayConfigSetDeviceInfo`
with `DISPLAYCONFIG_SET_ADVANCED_COLOR_STATE`, which has changed structure
between Windows 11 builds (the older `EnableAdvancedColor` flag was joined by
`AdvancedColorMode` in 24H2's HDR/SDR-mode rework). A wrong call can leave the
TV in a black-screen state on signal change. The spec for this task says: if not
confident it's safe, leave it manual. So it's manual.

## Do this

1. With the TV on and the PC outputting to it, press **Win + Alt + B**.
   This toggles HDR via the Game Bar on the active display, and it's the safest
   one-key method. Watch the LG: a brief signal renegotiation flash is normal,
   and the TV's badge in the top-right should change to "HDR Game" (after Game
   mode is enabled per Part D).
2. Verify in Windows: **Settings → System → Display → HDR**. The "Use HDR"
   toggle should be **On**, and "Stream HDR video" should also be **On**.
3. If the Win+Alt+B shortcut does nothing, open the same Settings page and
   flip "Use HDR" by hand.

## If you'd rather use a CLI helper (opt-in)

[`HDRTray` / `HDRCmd`](https://github.com/res2k/Windows-HDR-color-changer)
and similar small open-source utilities can toggle HDR from a command line.
They're community tools — vet before use. The task spec didn't authorize
downloading them silently, so they're not in `Run-All.ps1`. If you decide to
use one, install it yourself; it's a clean way to script HDR off for SDR work
and back on for games.

## What "good" looks like after this

- Windows reports HDR On.
- The LG shows the small "HDR" or "HDR Game" badge in the top-right when input
  switches to the PC.
- A pure-white test pattern in an HDR-aware app is dazzlingly bright (the panel
  goes near full-field peak on white slides).
- An SDR Notepad window does NOT look washed out (if it does, SDR brightness is
  off — see `Per-Game-Settings.md` → "SDR content in HDR mode").
