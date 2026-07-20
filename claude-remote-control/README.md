# Claude Remote-Control — Always On

A small **sister program** for your PC that keeps Claude's own **Remote Control**
running, so your **PC reliably shows up in the Claude app on your phone** and
stays connected.

**The main problem it fixes:** with plain Remote Control, your computer often
just *doesn't appear* in the phone app when you go to connect — the command is
running but the link went stale. This re-announces the PC on a timer so it keeps
popping back into the list, fresh, without you touching anything.

Everything it does:

1. **Re-announces on a timer** so the PC keeps showing up in the app
   (`REFRESH_MINUTES`, default 15). ← the fix for "it doesn't show up every time."
2. **Reconnects itself** if the link ever drops or crashes (restart loop).
3. **Resumes the same session** you were already using — never a fresh chat
   (`--continue`). The re-announce lands you back on that same conversation.
4. **Reaches all the projects you list**, not just one folder (`--add-dir`).

Plus it **starts automatically at login**, so whenever the PC is on, your phone
can connect.

This does **not** fake anything. Remote Control is Anthropic's real feature — the
*"Connect your computer"* screen in the phone app. Under the hood the phone runs
`claude --remote-control`; this just launches it for you, keeps it alive, and
points it at the right session and folders. (Real flags, verified against Claude
Code v2.1: `claude --remote-control [name] --continue --add-dir <dirs...>`.)

---

## What you need first

1. **Claude Code on the PC**, signed in. Check: `claude --version` (needs 2.1+).
2. The **Claude app on your phone**, same account.

---

## Windows

Everything's in `windows/`.

1. **Open `start-claude-rc.bat` in Notepad** and set two things at the top:
   - `PROJECT_DIR` — your main work folder (e.g. your Ragnarok folder). This is
     the session `--continue` reopens, so keep it stable.
   - `EXTRA_DIRS` — any other project folders you want reachable, e.g.
     `set "EXTRA_DIRS=--add-dir C:\Users\you\RagnarokOS C:\code\stuff"`
     (leave blank if you only use the one folder).

2. **First run — visible, once.** Double-click `start-claude-rc.bat`, finish any
   sign-in, then open the Claude phone app and **pick this computer**. Confirm it
   connects.

3. **Make it always-on.** Double-click `install-autostart.bat`. From now on it
   launches hidden at every login, keeps itself alive, and drops you back into
   the same session. Turn it off with `uninstall-autostart.bat`.

---

## Linux / macOS / Steam Deck

`linux-mac/start-claude-rc.sh` — same behavior:

    bash linux-mac/start-claude-rc.sh /path/to/your/project

Edit `SESSION_NAME`, `EXTRA_DIRS`, and `RESUME` at the top if you want. Auto-start
at login: add it to macOS **Login Items**, Linux **Startup Applications**, or a
`systemd --user` service with `Restart=always`.

---

## How each feature works (the real flags)

- **Keeps the PC showing up (the main fix).** Every `REFRESH_MINUTES` (default
  15) the launcher stops and restarts `claude --remote-control`, which forces the
  computer to re-announce itself to your account — so it keeps reappearing in the
  phone app's list even when the old link went stale. Because it restarts *with*
  `--continue`, you land back on the same conversation, so the refresh is nearly
  invisible to you. Set `REFRESH_MINUTES=0` to turn this off and only restart on
  an actual crash. If it ever refreshes mid-task and feels disruptive, raise the
  number (e.g. 30 or 60).
- **Same session, not a new one (#1).** The launcher runs
  `claude --remote-control "<PC name>" --continue`. `--continue` reopens the most
  recent conversation in `PROJECT_DIR`, so every restart — even after a reboot —
  lands you back in the session you were using. (First run ever has nothing to
  continue, so it starts one and drops a `.rc-initialized` marker; every run
  after that resumes.)
- **All your projects (#2).** `EXTRA_DIRS` becomes `--add-dir <folders>`, giving
  that one session tool access to every folder you list — so any work is
  reachable, not just the main one.
- **Never disconnects.** If `claude --remote-control` exits or crashes, the loop
  waits 3s and relaunches. With auto-start at login, the only way you're not
  connected is the PC being off.

---

## Honest notes

- I built and tested this in a **cloud coding session**, where Claude Code itself
  reports *"Remote Control is not available inside a cloud session"* — so I could
  verify the **flags, the restart loop, and the resume logic** (all confirmed
  with a mock), but the **real phone↔PC handshake can only run on your actual
  PC**. Run step 2 on the PC to prove that last mile.
- Keep `PROJECT_DIR` the same each time or `--continue` will resume a different
  folder's conversation.
- If Anthropic changes the flags, it's the one `claude --remote-control` line in
  the script to update.

---

by **Bentaco** · built with **Claudius Maximus**
Because the strong are meant to lift everyone up. ⚔️
