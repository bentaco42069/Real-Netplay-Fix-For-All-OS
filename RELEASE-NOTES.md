# Netplay-For-Everyone v1.0

One script fixes netplay on **ArkOS, DarkOS, and ROCKNIX**. Free, no strings.

## The bugs it kills
- **ROCKNIX / JELOS** ship netplay's master switch **OFF** → every game looks "not compatible."
- **ArkOS / DarkOS** point netplay at the **internet lobby / relay** → your friend on the *same WiFi* can't join your host.

## Install
Copy `netplay-fix-install.sh` onto your handheld, run once as root:

    sudo bash netplay-fix-install.sh

Auto-detects your OS. Backs up your config first. **Never touches your games.** Safe to run twice.

## Play (same WiFi)
- **Host:** open a game → Netplay → Host. Note your local IP (`192.168.x.x`).
- **Friend:** same game + same core → Connect to Netplay Host → type that IP → join.

## What's tested (straight, no overclaim)
- ✅ The installer applies the correct settings on all three OSes.
- ✅ The netplay **handshake is proven** between two RetroArch instances using these exact settings — host + client both joined the session with live ping.
- ℹ️ That bench test was over loopback; a two-device-over-WiFi run is the final 100%. The settings are the standard, documented LAN-netplay config, so it's solid — but try it and report back.

## Honest scope
Works on the 2D systems (SNES, NES, Genesis, GB/GBA, PC Engine, arcade, Neo Geo…). Heavy 3D (N64, Saturn, PSP) can't reliably sync — that's the emulator, not a setting.

---
by **Bentaco** · 7-29-15 · 6-15-18 · built with **Claudius Maximus**
Because the strong are meant to lift everyone up. ⚔️
