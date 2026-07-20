#!/usr/bin/env bash
# Claude Phone Remote — host launcher (Linux / SteamOS / handhelds).
# Auto-restarts the host if it ever crashes, so the remote comes back on its own.
set -u
cd "$(dirname "$0")"

PY="${PYTHON:-python3}"

# First run: make sure deps are installed.
if ! "$PY" -c "import aiohttp, pyautogui" 2>/dev/null; then
  echo "[*] Installing host dependencies (one time)..."
  "$PY" -m pip install --user -r requirements.txt || {
    echo "[!] pip install failed. Install manually:  $PY -m pip install -r requirements.txt"
    exit 1
  }
fi

echo "[*] Starting Claude Phone Remote host (Ctrl-C to stop)."
while true; do
  "$PY" claude_remote_host.py "$@"
  code=$?
  # Clean exit (Ctrl-C = 130) -> stop. Any crash -> wait and relaunch.
  if [ $code -eq 0 ] || [ $code -eq 130 ]; then
    echo "[*] Host stopped."
    break
  fi
  echo "[!] Host exited (code $code). Restarting in 3s..."
  sleep 3
done
