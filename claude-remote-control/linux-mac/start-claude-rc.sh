#!/usr/bin/env bash
# ============================================================================
#  Claude Remote-Control - Always On   (the "sister program"), Linux/macOS/Deck.
# ----------------------------------------------------------------------------
#  Fixes the real problem: your PC not reliably showing up in the phone app.
#    * RE-ANNOUNCES on a timer so the PC keeps showing up  (REFRESH_MINUTES)
#    * RECONNECTS if the link ever drops or crashes        (restart loop)
#    * RESUMES the SAME session, not a new one             (--continue)
#    * reaches ALL the projects you list                   (--add-dir)
#
#  Real Claude Code flags (v2.1+):
#    claude --remote-control [name] --continue --add-dir <dirs...>
# ============================================================================
set -u

# ==== SETTINGS -- edit these ================================================

# Stable name for this computer as it shows in the phone app:
SESSION_NAME="${SESSION_NAME:-$(hostname)}"

# Main project folder to resume in:
PROJECT_DIR="${1:-$HOME}"

# Other project folders to reach in that one session (space-separated):
#   EXTRA_DIRS=(--add-dir "$HOME/RagnarokOS" "$HOME/code/stuff")
EXTRA_DIRS=()

# Keep the same session (--continue). Set to "" to always start fresh.
RESUME="--continue"

# THE FIX for "it doesn't show up every time": re-announce this many minutes so
# the PC keeps re-appearing in the app's list even if the link went stale while
# the process was still alive. --continue means the refresh lands you back on the
# same conversation. Set to 0 to disable and only restart on an actual crash.
REFRESH_MINUTES="${REFRESH_MINUTES:-15}"

# ===========================================================================

if ! command -v claude >/dev/null 2>&1; then
  echo "[!] The 'claude' command was not found. Install/update Claude Code first."
  exit 1
fi
cd "$PROJECT_DIR" 2>/dev/null || { echo "[!] Project folder not found: $PROJECT_DIR"; exit 1; }

MARKER="$(cd "$(dirname "$0")" && pwd)/.rc-initialized"
MODE="$RESUME"; [ -e "$MARKER" ] || MODE=""

echo "============================================================"
echo "  Claude Remote-Control - Always On"
echo "  Computer name : $SESSION_NAME"
echo "  Project       : $(pwd)"
echo "  Re-announce   : every ${REFRESH_MINUTES} min (0 = only on crash)"
echo "  Open the Claude app on your phone and pick this computer."
echo "  (Ctrl-C to stop.)"
echo "============================================================"

trap 'echo; echo "[*] Stopped."; exit 0' INT TERM

run_once() {
  if [ "${REFRESH_MINUTES}" != "0" ] && command -v timeout >/dev/null 2>&1; then
    # Auto-stop after the refresh window so the loop re-announces the PC.
    timeout "${REFRESH_MINUTES}m" claude --remote-control "$SESSION_NAME" $MODE "${EXTRA_DIRS[@]}"
  else
    claude --remote-control "$SESSION_NAME" $MODE "${EXTRA_DIRS[@]}"
  fi
}

while true; do
  run_once
  code=$?
  [ -e "$MARKER" ] || echo initialized > "$MARKER"
  MODE="$RESUME"
  if [ "$code" -eq 124 ]; then
    echo "[*] Re-announcing to keep the PC visible in the app..."
  else
    echo "[!] Remote Control stopped (code $code). Reconnecting in 3s..."
    sleep 3
  fi
done
