# The Phone Side (Android)

The phone half of this is **the official Claude app** — you don't install a
separate program, because Remote Control is already built into it. That
*"Connect your computer"* screen is the phone doing its half. This page is just
the exact setup so the phone and the PC sister program (`start-claude-rc.bat`)
lock together and stay connected.

---

## One-time setup

1. **Install the Claude app** on your Android phone (Google Play → "Claude by
   Anthropic").
2. **Sign in with the SAME account** you're signed into on the PC. This is what
   lets the two find each other — the pairing is tied to your account, not to
   being on the same WiFi.
3. On the **PC**, get the sister program running (`start-claude-rc.bat`, then
   `install-autostart.bat` — see the main README). It runs
   `claude --remote-control`, which is what publishes your computer to the app.

---

## Connecting

1. In the Claude app, open the **Connect your computer** screen (the one you
   screenshotted).
2. Because the PC is already running `claude --remote-control`, **your computer
   shows up in the list** — tap it.
3. You're now driving your PC's Claude session from the phone.

---

## Staying on the session you were using (not a new one)

- When you connect, **pick the session you were already in** rather than starting
  a new chat. The PC wrapper launches with `--continue`, so it's holding your
  most recent conversation open in your project folder — tapping it puts you
  right back where you left off.
- Because the PC side auto-starts at login and auto-relaunches on any drop, the
  computer stays available in the app's list whenever the PC is on.

---

## Keeping the phone from dropping the link

Android aggressively suspends background apps to save battery. To keep the
connection sticky:

- **Battery:** Settings → Apps → Claude → Battery → set to **Unrestricted** (or
  turn off "optimize battery usage" for Claude). This is the single biggest fix
  for random disconnects.
- **Keep it foreground** while you're actively working; when you come back to the
  app it re-pairs to the PC on its own (the PC side never went away).
- Solid WiFi or cellular — the pairing is over the internet through your account,
  so any working connection is fine.

---

## If your computer doesn't show up

- Confirm the PC window is actually running `claude --remote-control` (the
  sister program's window should say it's alive and waiting).
- Confirm **both** phone and PC are signed into the **same Claude account**.
- Make sure Claude Code on the PC is **v2.1 or newer**: `claude --version`.
- Restart the PC sister program (close its window and re-run
  `start-claude-rc.bat`); it'll re-publish the computer.

---

## Why there's no custom phone app to build

Remote Control is a closed, first-party feature: the phone app and the
`claude --remote-control` command speak a private protocol to each other. There's
no public API for a third-party app to join that link — so the *correct* phone
client is the Claude app itself. A homemade "phone app" could only fake it by
screen-scraping/keyboard-injecting the PC, which is exactly the approach we threw
out. Using the real Claude app is the right, stable way, and it's already built.

---

by **Bentaco** · built with **Claudius Maximus**
