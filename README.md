# Netplay-For-Everyone

A one-shot fix for the netplay bugs on **ArkOS**, **DarkOS**, and **ROCKNIX** — so
2-player games stop saying *"not compatible"* and your friend on the same WiFi can
actually **join your host**.

Free. No strings.

**✅ Verified real** — each OS was diagnosed from its actual disk image in Ubuntu, and the netplay handshake was proven between two RetroArch clients (both joined, live ping). **[See the full proof →](PROOF.md)**

## What it fixes

Two different bugs, depending on your OS:

- **ROCKNIX / JELOS** ship with netplay's **master switch OFF** (`global.netplay=0`).
  Every game looks "incompatible" because the whole feature is disabled.
  → We turn it **on**.
- **ArkOS / DarkOS** have netplay **on**, but aimed at the **internet lobby / relay**
  (`netplay_public_announce` + `netplay_nat_traversal` = true). So when your buddy two
  feet away tries to join, RetroArch routes through the internet and your home router
  can't loop it back to you ("NAT hairpin") — the join dies.
  → We switch it to **direct LAN**.

On every OS we also make sure the relay middleman is off, so it's a clean,
same-network, no-internet connection.

## How to use it

1. Copy `netplay-fix-install.sh` onto your handheld.
2. Run it once, as root:  `sudo bash netplay-fix-install.sh`
3. It backs up your config first, flips the switches, and tells you how to play.

It **auto-detects** which OS you're on. **Your games are never touched.** It's safe to
run more than once — every file it edits gets a timestamped `.bak` backup.

## Playing with a friend (same WiFi)

1. **Host:** open a game → Netplay → Start / Host.
2. **Host:** note your local IP (Network settings — looks like `192.168.x.x`).
3. **Friend:** open the **same game + same core** → Netplay → Connect to Netplay Host
   → type the host's `192.168.x.x` → join.

Same game, same core, same WiFi = you're in.

## The honest part

- This fixes the **2D systems** — SNES, NES, Genesis, Game Boy / GBA, PC Engine,
  arcade, Neo Geo, and the rest. That's where couch multiplayer lives.
- A handful of heavy 3D systems (N64, Saturn, PSP) can't reliably sync no matter what
  — that's the emulator's internals, not a setting. Not this fix's fault, and not
  something a config flip can cure.

## Made by

**Bentaco**  ·  7-29-15  ·  6-15-18
built with **Claudius Maximus**

Because the strong are meant to lift everyone up. ⚔️
