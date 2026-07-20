# Claude Phone Remote

A little **sister program** for the Claude app on your PC. Run the host on your
computer, open the web app on your phone (same WiFi), and you've got a **remote
control**: see your screen, type prompts straight into Claude, tap to click,
press keys.

And the part you asked for — **it reconnects itself.** If your WiFi blinks, your
phone sleeps, or you walk out of range, the link comes back on its own the
moment it can. No re-pairing, no fiddling.

Free. No cloud, no account, no relay. LAN only — same spirit as the netplay fix:
your machines, your WiFi, nobody in the middle.

---

## Two pieces

- **The host** (`host/`) — runs on your **PC** (the one with the Claude app).
  It's the "sister program." It serves the phone app and does the actual
  clicking/typing/screenshotting.
- **The phone app** (`webapp/`) — a web app your **phone** opens in its browser.
  Nothing to install from an app store; you just open a link. (You can "Add to
  Home Screen" so it looks and opens like a real app.)

---

## Setup (about 2 minutes)

### 1. On the PC — start the host

You need Python 3.9+.

- **Windows:** double-click `host/start-host.bat`
- **macOS:** double-click `host/start-host.command`
- **Linux / SteamOS:** run `bash host/start-host.sh`

First run installs two Python packages (`aiohttp`, `pyautogui`) automatically.

The window prints a **PIN** and one or more **URLs** like:

    http://192.168.1.20:8765/?pin=4823

### 2. On the phone — open the app

Make sure the phone is on the **same WiFi** as the PC. Open that URL in your
phone's browser (or type the PIN into the app by hand). That's it — you're
connected.

> **Add to Home Screen** (Share menu on iPhone, browser menu on Android) turns
> it into a tap-to-open app with its own icon.

---

## What you can do from the phone

- **Send to Claude** — type a prompt, hit the button. The host brings the Claude
  window to the front, types it in, and presses Enter for you.
- **Live screen** — flip "Live: on" to watch your PC screen. Tap anywhere on the
  image to click that exact spot.
- **Keys** — Enter, Esc, Tab, arrows, Copy/Paste/Undo, and a "Type text" button
  for anything else.
- **Shot** — grab a single fresh screenshot without leaving live view running.

---

## How the reconnect actually works (no hand-waving)

Two safety nets, because a dropped remote is useless:

1. **The link (phone → PC).** The phone holds a WebSocket to the host. It sends a
   heartbeat every few seconds; if the host stops answering, the phone assumes
   the link died and reconnects with backoff (0.5s, 1s, 2s… up to 15s), then
   re-does the PIN handshake and re-arms live view. Coming back to the app,
   regaining signal, or waking the phone all kick an **instant** reconnect
   instead of waiting.
2. **The process (on the PC).** The `start-host` launchers run the host in a
   loop — if it ever crashes, it relaunches in 3 seconds. So the thing the phone
   reconnects *to* stays up too.

Net effect: short of the PC being off, the remote heals itself.

---

## Security (read this)

- Control is gated by a **4-digit PIN** shown in the host window. Someone would
  have to be on your WiFi **and** know the PIN to do anything.
- The link is **plain HTTP over your LAN** — not encrypted. That's fine for a
  home/trusted network; don't run this on public WiFi.
- Change the PIN anytime: delete `host/.pin`, or start with `--pin 1234`.
- The host binds to your whole LAN (so the phone can reach it). Anyone on the
  network can *see* the login page; only the PIN lets them in.

---

## The honest part

- **This drives the Claude app by controlling your keyboard/mouse and screen** —
  it's a real remote, not a private API into Claude. "Send to Claude" focuses the
  Claude window and types. If it can't find a window literally named *Claude*, it
  types into whatever's focused and tells you so — no silent misfires.
- **Auto-focusing the Claude window** is best-effort per OS: macOS uses
  `osascript` (works out of the box); Windows wants the optional `pygetwindow`
  package; Linux wants `wmctrl` installed. Without those, everything still works —
  you just click the Claude window yourself first (or tap it in live view).
- **macOS** will ask for **Screen Recording** and **Accessibility** permission on
  first run (System Settings → Privacy & Security). That's the OS gate for
  screenshots + typing; grant both and relaunch.
- Needs a **real desktop session** on the PC — a headless server with no screen
  can't be screenshotted or typed into, and the host will say so.
- **Tested:** the host's handshake, PIN gate, input injection, click mapping,
  prompt-to-Claude flow, live streaming, and reconnect were all verified with an
  automated end-to-end test. The one thing only *you* can do is the final
  real-device-over-WiFi run — try it and report back.

---

by **Bentaco** · built with **Claudius Maximus**
Because the strong are meant to lift everyone up. ⚔️
