#!/usr/bin/env bash
# ============================================================================
#  Claude Remote-Control - Always On   (the "sister program"), Linux/macOS/Deck.
# ----------------------------------------------------------------------------
#  Keeps Claude's Remote Control running so the Claude app on your phone stays
#  connected -- and it:
#    * RECONNECTS itself if the link ever drops               (restart loop)
#    * RESUMES the SAME session you were using, not a new one (--continue)
#    * reaches ALL the projects you list, not just one folder (--add-dir)
#
#  Uses the real Claude Code flags (v2.1+):
#    claude --remote-control [name] --continue --add-dir <dirs...>
# ============================================================================
set -u

# ==== SETTINGS -- edit these ================================================

# Stable name for this computer as it shows in the phone app:
SESSION_NAME="${SESSION_NAME:-$(hostname)}"

# Main project folder to resume in (--continue reopens the latest conversation
# in THIS folder, so keep it the same each time):
PROJECT_DIR="${1:-$HOME}"

# All other project folders to reach in that one session (space-separated).
# Example: EXTRA_DIRS=(--add-dir "$HOME/RagnarokOS" "$HOME/code/stuff")
EXTRA_DIRS=()

# Session behavior: --continue keeps the same session. Set RESUME="" to always
# start fresh instead.
RESUME="--continue"

# ===========================================================================

if ! command -v claude >/dev/null 2>&1; then
  echo "[!] The 'claude' command was not found. Install/update Claude Code first."
  exit 1
fi

cd "$PROJECT_DIR" 2>/dev/null || {
  echo "[!] Project folder not found: $PROJECT_DIR"
  exit 1
}

# First run ever: no conversation yet -> start fresh, then always resume after.
MARKER="$(cd "$(dirname "$0")" && pwd)/.rc-initialized"
MODE="$RESUME"
[ -e "$MARKER" ] || MODE=""

echo "============================================================"
echo "  Claude Remote-Control - Always On"
echo "  Computer name : $SESSION_NAME"
echo "  Project       : $(pwd)"
echo "  Session       : keep-same ($RESUME)"
echo "  Open the Claude app on your phone and pick this computer."
echo "  (Ctrl-C to stop.)"
echo "============================================================"

trap 'echo; echo "[*] Stopped."; exit 0' INT TERM

while true; do
  claude --remote-control "$SESSION_NAME" $MODE "${EXTRA_DIRS[@]}"
  code=$?
  [ -e "$MARKER" ] || echo initialized > "$MARKER"
  MODE="$RESUME"
  echo
  echo "[!] Remote Control stopped (code $code). Reconnecting in 3s..."
  sleep 3
done
