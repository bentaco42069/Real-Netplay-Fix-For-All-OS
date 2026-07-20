# Claude Remote-Control — Always On

A small **sister program** for your PC that keeps Claude's own **`claude
remote-control`** running, so the **Claude app on your phone is always connected
to your computer** — and reconnects itself if the link ever drops.

This does **not** replace or fake anything. `claude remote-control` (a.k.a.
`claude rc`) is Anthropic's real feature — the one on the *"Connect your
computer"* screen in the phone app. This just keeps it alive and starts it for
you, so you never have to open a terminal and type the command again.

- ✅ Runs `claude remote-control` on your PC and **relaunches it if it drops**.
- ✅ **Starts automatically at login**, so whenever your PC is on, your phone can
  connect.
- ✅ Uses the **project folder you choose**, and connects to your **existing
  Claude Code sessions** — it doesn't spin up a throwaway new one.

---

## What you need first

1. **Claude Code installed on the PC** and signed in. Check with:
   `claude --version` in a terminal. (If `claude` isn't found, install/update
   Claude Code first.)
2. The **Claude app on your phone**, signed into the **same account**.

That phone screen you saw — *"In a terminal on your computer… run
`claude remote-control`… then come back here and select your computer"* — is
exactly what this automates.

---

## Windows (your PC)

Everything is in the `windows/` folder.

1. **Set your project folder.** Open `start-claude-rc.bat` in Notepad and edit
   this line to the folder you want Claude working in (e.g. your Ragnarok work):

       set "PROJECT_DIR=%USERPROFILE%"

2. **First run — do it visibly once.** Double-click `start-claude-rc.bat`. Finish
   any sign-in/pairing it asks for. Then open the Claude app on your phone and
   **pick this computer** from the list. Confirm it connects.

3. **Make it always-on.** Double-click `install-autostart.bat`. From now on it
   launches **hidden at every login** and keeps itself running. Your phone can
   connect any time the PC is on.

   To turn it back off: `uninstall-autostart.bat`.

---

## Linux / macOS / Steam Deck

Use `linux-mac/start-claude-rc.sh`:

    bash linux-mac/start-claude-rc.sh /path/to/your/project

Auto-start at login:
- **macOS:** System Settings → General → Login Items → add the script.
- **Linux desktop:** add it to *Startup Applications*.
- **systemd (headless):** a user service that runs the script with
  `Restart=always` gives you the same "always on" behavior.

---

## How the "never disconnects" part works

Two layers, so a dropped link fixes itself:

1. **The phone ↔ PC link** is handled by Claude's own `remote-control` — the
   phone app reconnects to your computer on its own while the command is
   running.
2. **The command itself** is kept alive by this wrapper: if `claude
   remote-control` ever exits or crashes, the launcher waits a few seconds and
   starts it again — forever, until you close the window. Combined with
   auto-start at login, the only way you're *not* connected is if the PC is off.

---

## Same session, not a new one

Your conversations live in Claude Code on this PC. When you connect from the
phone, you **pick the session you were already using** and keep going — remote
control drives your real sessions, it doesn't create a fresh throwaway chat.
Point the launcher at the same project folder each time and your work is right
where you left it.

---

## Honest notes

- This is a **keep-alive + auto-start wrapper** around a real Anthropic command.
  All the actual phone↔PC connecting is Claude's feature; the value here is that
  you never have to babysit the terminal.
- **Do the first login/pairing with the window visible** (step 2) before turning
  on auto-start — a hidden window can't show you a sign-in prompt.
- Needs `claude` on your PATH and a normal desktop login session. A powered-off
  or logged-out PC obviously can't be connected to.
- If Anthropic changes the command name or flags, update the one line in
  `start-claude-rc.bat` / `.sh` that runs `claude remote-control`.

---

by **Bentaco** · built with **Claudius Maximus**
Because the strong are meant to lift everyone up. ⚔️
