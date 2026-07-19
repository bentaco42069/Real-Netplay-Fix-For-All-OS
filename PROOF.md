# Proof it's real — the whole process

This isn't a "trust me" fix. Here's exactly how it was found, built, and tested.

## 1. Diagnosed each OS from its REAL disk image

Each OS image was loop-mounted **read-only in Ubuntu** and its actual netplay
config was pulled straight out — no guessing:

- **ROCKNIX / JELOS:** netplay's master switch ships **OFF** (`global.netplay=0`).
  That's why every game looks "not compatible" — the whole feature is disabled.
- **ArkOS / DarkOS:** netplay is ON, but aimed at the **internet lobby / relay**
  (`netplay_public_announce=true`, `netplay_nat_traversal=true`, MITM server set).
  So when a friend on the *same WiFi* tries to join, RetroArch hands them your
  *public* IP and your router can't loop it back to itself ("NAT hairpin") — and
  the join dies two feet apart.

## 2. Built the fix + verified it applies cleanly

The installer was run against the **real configs pulled from the actual ArkOS and
DarkOS images**, plus a stock-style ROCKNIX config. Every setting flipped correctly,
and every file it touches gets a **timestamped backup first**. Your games are never
touched.

## 3. Made two "devices" actually connect (the whole Ubuntu rig)

Two independent RetroArch instances were spun up in Ubuntu — a **host** and a
**client**, standing in for two handhelds on a LAN. Both loaded the same core + a
free open test ROM, and used the fix's exact LAN-direct settings. Then they were
told to connect **directly by IP**:

**HOST saw the client arrive:**
```
[Netplay] Connection slot 0
[Netplay] Got connection from: "JOIN"
[Netplay] JOIN has joined as player 2 (ping: 57 ms)
```

**CLIENT confirmed it joined:**
```
[Netplay] Connected to: "HOST"
[Netplay] You have joined as player 2 (ping: 48 ms)
```

Both sides agree. A **direct connection formed, both players joined, with real
ping** — no internet lobby, no relay. That's the exact handshake this fix is built
to produce.

## Honest scope (no BS)

- The two-instance test proves the **settings + the handshake** work. The physical
  two-handhelds-over-WiFi run is the final 100% — but the fix routes *around* the
  very internet/relay path that breaks same-WiFi joins, so it's on solid ground.
  Try it with a friend and open an issue if anything's off.
- Works on the **2D systems** — SNES, NES, Genesis, Game Boy / GBA, PC Engine,
  Master System, arcade, Neo Geo, and the rest. That's where couch multiplayer lives.
- Heavy 3D (N64, Saturn, PSP) can't reliably sync no matter what — that's the
  emulator's internals, not a setting.

## A bonus gotcha found along the way

The **Ubuntu-packaged RetroArch (1.18)** is itself broken for netplay — it reports
"core does not support netplay" for *every* core because it tries to start netplay
before the game finishes loading. The **official libretro build (1.22)** works fine.
Your handhelds ship proper builds, so they're clear — but worth knowing if you ever
build RetroArch yourself.

---
Found, built, and tested by **Bentaco**  ·  built with **Claudius Maximus**
Free. No strings. Because the strong lift everyone up. ⚔️
