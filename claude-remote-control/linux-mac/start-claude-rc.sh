#!/usr/bin/env bash
# ============================================================================
#  Claude Remote-Control - Always On   (the "sister program"), Linux/macOS.
# ----------------------------------------------------------------------------
#  Keeps `claude remote-control` running on THIS machine so the Claude app on
#  your phone can always connect to it. If it drops or crashes, this relaunches
#  it on its own -- so you stay connected without touching the terminal.
#
#  First time: run it once, finish any login/pairing, then open the Claude
#  phone app and pick this computer from the list.
#
#  Auto-start at login:
#    - Linux (systemd):  loginctl enable-linger + a user service, or add this
#      script to your desktop's Startup Applications.
#    - macOS: add it as a Login Item (System Settings > General > Login Items),
#      or use the launchd plist noted in the README.
# ============================================================================
set -u

# ---- EDIT THIS: the project folder you want Claude to work in ---------------
PROJECT_DIR="${1:-$HOME}"

if ! command -v claude >/dev/null 2>&1; then
  echo "[!] The 'claude' command was not found on your PATH."
  echo "    Install or update Claude Code first, then run this again."
  exit 1
fi

cd "$PROJECT_DIR" 2>/dev/null || {
  echo "[!] Project folder not found: $PROJECT_DIR"
  echo "    Pass the folder as an argument:  ./start-claude-rc.sh /path/to/project"
  exit 1
}

echo "============================================================"
echo "  Claude Remote-Control - Always On"
echo "  Project: $(pwd)"
echo "  Keeping 'claude remote-control' alive."
echo "  Open the Claude app on your phone and pick this computer."
echo "  (Ctrl-C to stop.)"
echo "============================================================"

# Ctrl-C should actually quit, not just restart the loop.
trap 'echo; echo "[*] Stopped."; exit 0' INT TERM

while true; do
  claude remote-control
  code=$?
  echo
  echo "[!] remote-control stopped (code $code). Reconnecting in 3s..."
  sleep 3
done
