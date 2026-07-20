#!/usr/bin/env python3
"""
Claude Phone Remote — HOST (the "sister program" that runs on your PC).

It does two jobs:
  1. Serves the phone web app to any phone on your WiFi.
  2. Opens a WebSocket control link so the phone can see your screen and
     drive the Claude app (type prompts, press Enter, tap, hotkeys).

The link auto-reconnects: the phone reconnects if WiFi hiccups, and the
start-host launcher relaunches this process if it ever crashes. So the
"remote control" comes back on its own after a drop.

LAN only. No cloud, no account, no relay. Same spirit as the netplay fix:
your machines, your WiFi, nobody in the middle.

Run it with the launcher (start-host.sh / .command / .bat) so you get the
auto-restart wrapper, or directly:

    python3 claude_remote_host.py

Then open the URL it prints on your phone's browser.
"""

import argparse
import asyncio
import base64
import io
import json
import os
import platform
import secrets
import socket
import subprocess
import sys
import time
from pathlib import Path

# ---- Dependencies (with friendly errors instead of a raw traceback) --------

def _die_missing(pkg, why):
    print(f"\n[!] Missing dependency: {pkg}", file=sys.stderr)
    print(f"    {why}", file=sys.stderr)
    print(f"    Install everything with:  pip install -r requirements.txt\n", file=sys.stderr)
    sys.exit(1)

try:
    from aiohttp import web, WSMsgType
except ImportError:
    _die_missing("aiohttp", "needed to serve the phone app + WebSocket link.")

try:
    import pyautogui
    pyautogui.FAILSAFE = False   # don't abort when the cursor hits a corner
    pyautogui.PAUSE = 0.0
except Exception as e:  # pyautogui blows up at import time on a headless box
    pyautogui = None
    _PYAUTOGUI_ERR = str(e)
else:
    _PYAUTOGUI_ERR = None

try:
    from PIL import Image  # pulled in by pyautogui, used for JPEG encoding
except ImportError:
    Image = None

# ---- Paths -----------------------------------------------------------------

HERE = Path(__file__).resolve().parent
WEBAPP_DIR = (HERE.parent / "webapp").resolve()
PIN_FILE = HERE / ".pin"

# ---- Helpers ---------------------------------------------------------------

def local_ips():
    """Best-effort list of this machine's LAN IPv4 addresses."""
    ips = set()
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))       # no packets sent; just picks the route
        ips.add(s.getsockname()[0])
        s.close()
    except Exception:
        pass
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ip = info[4][0]
            if not ip.startswith("127."):
                ips.add(ip)
    except Exception:
        pass
    return sorted(ips)


def get_or_make_pin():
    """Persist a 4-digit PIN so it stays the same across restarts."""
    if PIN_FILE.exists():
        pin = PIN_FILE.read_text(encoding="utf-8").strip()
        if pin.isdigit() and len(pin) == 4:
            return pin
    pin = f"{secrets.randbelow(10000):04d}"
    try:
        PIN_FILE.write_text(pin, encoding="utf-8")
    except Exception:
        pass
    return pin


def print_ascii_qr(url):
    """Print a scannable QR if the optional 'qrcode' package is installed."""
    try:
        import qrcode
    except ImportError:
        return
    qr = qrcode.QRCode(border=1)
    qr.add_data(url)
    qr.make(fit=True)
    qr.print_ascii(invert=True)


# ---- Screen capture --------------------------------------------------------

def grab_frame(max_width, quality):
    """Return (jpeg_bytes, full_w, full_h) or raise."""
    if pyautogui is None or Image is None:
        raise RuntimeError("screen capture unavailable on this machine")
    img = pyautogui.screenshot()
    full_w, full_h = img.size
    if img.mode != "RGB":
        img = img.convert("RGB")
    if full_w > max_width:
        scale = max_width / float(full_w)
        img = img.resize((max_width, max(1, int(full_h * scale))), Image.BILINEAR)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=quality)
    return buf.getvalue(), full_w, full_h


# ---- Focusing the Claude app (best-effort, per-OS) -------------------------

def focus_claude_app():
    """
    Try to bring the Claude desktop app to the front so typed text lands in it.
    Returns (ok: bool, note: str). If it can't, we type into whatever has focus
    and say so — no pretending.
    """
    system = platform.system()
    try:
        if system == "Darwin":
            r = subprocess.run(
                ["osascript", "-e", 'tell application "Claude" to activate'],
                capture_output=True, text=True, timeout=5,
            )
            if r.returncode == 0:
                return True, "focused Claude (macOS)"
            return False, "couldn't find a 'Claude' app to focus — typing into the active window"

        if system == "Windows":
            # Optional dependency; falls back cleanly if not installed.
            try:
                import pygetwindow as gw
            except ImportError:
                return False, "install pygetwindow to auto-focus Claude — typing into the active window"
            wins = [w for w in gw.getAllTitles() if "claude" in w.lower()]
            if wins:
                win = gw.getWindowsWithTitle(wins[0])[0]
                try:
                    win.activate()
                except Exception:
                    win.minimize(); win.restore()
                return True, "focused Claude (Windows)"
            return False, "no Claude window found — typing into the active window"

        # Linux
        for tool in ("wmctrl",):
            if _which(tool):
                r = subprocess.run([tool, "-a", "Claude"], capture_output=True, timeout=5)
                if r.returncode == 0:
                    return True, "focused Claude (Linux/wmctrl)"
        return False, "install wmctrl to auto-focus Claude — typing into the active window"
    except Exception as e:
        return False, f"focus failed ({e}) — typing into the active window"


def _which(name):
    from shutil import which
    return which(name) is not None


# ---- Input injection (runs off the event loop via executor) ----------------

def do_type(text):
    if pyautogui is None:
        raise RuntimeError("input unavailable on this machine")
    pyautogui.typewrite(text, interval=0.0)


def do_key(key):
    if pyautogui is None:
        raise RuntimeError("input unavailable on this machine")
    pyautogui.press(key)


def do_hotkey(keys):
    if pyautogui is None:
        raise RuntimeError("input unavailable on this machine")
    pyautogui.hotkey(*keys)


def do_click(nx, ny, screen_w, screen_h, button="left", double=False):
    """nx, ny are 0..1 normalized to the FULL screen."""
    if pyautogui is None:
        raise RuntimeError("input unavailable on this machine")
    x = int(max(0.0, min(1.0, nx)) * screen_w)
    y = int(max(0.0, min(1.0, ny)) * screen_h)
    if double:
        pyautogui.doubleClick(x, y, button=button)
    else:
        pyautogui.click(x, y, button=button)


def do_scroll(amount):
    if pyautogui is None:
        raise RuntimeError("input unavailable on this machine")
    pyautogui.scroll(int(amount))


# Keys the phone is allowed to press by name (keeps the surface small + safe).
ALLOWED_KEYS = {
    "enter", "return", "tab", "esc", "escape", "space", "backspace", "delete",
    "up", "down", "left", "right", "home", "end", "pageup", "pagedown",
    "f5", "f11",
}


# ---- The server ------------------------------------------------------------

class Host:
    def __init__(self, args):
        self.args = args
        self.pin = args.pin or get_or_make_pin()
        self.loop = None
        self.clients = set()

    async def run_blocking(self, fn, *a):
        return await self.loop.run_in_executor(None, fn, *a)

    # -- static web app --
    async def index(self, request):
        return web.FileResponse(WEBAPP_DIR / "index.html")

    async def health(self, request):
        return web.json_response({
            "ok": True,
            "input": pyautogui is not None,
            "clients": len(self.clients),
        })

    # -- the control socket --
    async def ws_handler(self, request):
        ws = web.WebSocketResponse(heartbeat=20, max_msg_size=8 * 1024 * 1024)
        await ws.prepare(request)

        authed = False
        live_task = None
        peer = request.remote

        async def send(obj):
            try:
                await ws.send_str(json.dumps(obj))
            except Exception:
                pass

        async def stream_frames():
            """Push frames while live view is on."""
            interval = 1.0 / max(1, self.args.fps)
            while not ws.closed:
                try:
                    jpeg, w, h = await self.run_blocking(
                        grab_frame, self.args.width, self.args.quality
                    )
                    await send({
                        "type": "frame",
                        "jpeg": base64.b64encode(jpeg).decode("ascii"),
                        "sw": w, "sh": h,
                    })
                except Exception as e:
                    await send({"type": "error", "msg": f"capture: {e}"})
                    await asyncio.sleep(1.0)
                await asyncio.sleep(interval)

        try:
            async for msg in ws:
                if msg.type != WSMsgType.TEXT:
                    continue
                try:
                    data = json.loads(msg.data)
                except Exception:
                    continue
                mtype = data.get("type")

                # --- handshake first ---
                if not authed:
                    if mtype == "hello" and str(data.get("pin", "")) == self.pin:
                        authed = True
                        self.clients.add(ws)
                        try:
                            _, sw, sh = await self.run_blocking(
                                grab_frame, self.args.width, self.args.quality
                            )
                            cap = True
                        except Exception:
                            sw, sh, cap = 0, 0, False
                        await send({
                            "type": "welcome",
                            "ok": True,
                            "capture": cap,
                            "input": pyautogui is not None,
                            "host": platform.node(),
                            "os": platform.system(),
                            "screen": {"w": sw, "h": sh},
                        })
                    else:
                        await send({"type": "welcome", "ok": False, "msg": "bad PIN"})
                        await ws.close()
                    continue

                # --- authed commands ---
                try:
                    if mtype == "ping":
                        await send({"type": "pong", "t": data.get("t")})

                    elif mtype == "live":
                        if data.get("on"):
                            if live_task is None or live_task.done():
                                live_task = asyncio.create_task(stream_frames())
                        else:
                            if live_task:
                                live_task.cancel()
                                live_task = None

                    elif mtype == "shot":
                        jpeg, w, h = await self.run_blocking(
                            grab_frame, self.args.width, self.args.quality
                        )
                        await send({
                            "type": "frame",
                            "jpeg": base64.b64encode(jpeg).decode("ascii"),
                            "sw": w, "sh": h,
                        })

                    elif mtype == "type":
                        await self.run_blocking(do_type, str(data.get("text", "")))

                    elif mtype == "key":
                        key = str(data.get("key", "")).lower()
                        if key in ALLOWED_KEYS:
                            await self.run_blocking(do_key, "enter" if key == "return" else key)

                    elif mtype == "hotkey":
                        keys = [str(k).lower() for k in data.get("keys", [])][:4]
                        if keys:
                            await self.run_blocking(do_hotkey, keys)

                    elif mtype == "click":
                        await self.run_blocking(
                            do_click,
                            float(data.get("x", 0)), float(data.get("y", 0)),
                            int(data.get("sw", 0)), int(data.get("sh", 0)),
                            "right" if data.get("button") == "right" else "left",
                            bool(data.get("double")),
                        )

                    elif mtype == "scroll":
                        await self.run_blocking(do_scroll, int(data.get("amount", 0)))

                    elif mtype == "prompt":
                        # The headline action: focus Claude, type, (optionally) send.
                        ok, note = await self.run_blocking(focus_claude_app)
                        await asyncio.sleep(0.35)  # let the window come forward
                        await self.run_blocking(do_type, str(data.get("text", "")))
                        if data.get("send", True):
                            await asyncio.sleep(0.05)
                            await self.run_blocking(do_key, "enter")
                        await send({"type": "prompt_done", "focused": ok, "note": note})

                    else:
                        await send({"type": "error", "msg": f"unknown command: {mtype}"})
                except Exception as e:
                    await send({"type": "error", "msg": str(e)})

        finally:
            if live_task:
                live_task.cancel()
            self.clients.discard(ws)
        return ws

    def build_app(self):
        app = web.Application()
        app.router.add_get("/", self.index)
        app.router.add_get("/health", self.health)
        app.router.add_get("/ws", self.ws_handler)
        app.router.add_static("/", WEBAPP_DIR, show_index=False)
        return app

    def banner(self):
        port = self.args.port
        ips = local_ips()
        primary = ips[0] if ips else "YOUR-PC-IP"
        url = f"http://{primary}:{port}/?pin={self.pin}"
        print("\n" + "=" * 58)
        print("  Claude Phone Remote — HOST is running")
        print("=" * 58)
        print(f"  PIN:   {self.pin}")
        print(f"  Port:  {port}")
        if pyautogui is None:
            print("\n  [!] Input/screen control is OFF on this machine:")
            print(f"      {_PYAUTOGUI_ERR}")
            print("      (You need a real desktop session — not a headless server.)")
        print("\n  On your phone (same WiFi), open ONE of these in the browser:")
        for ip in (ips or ["YOUR-PC-IP"]):
            print(f"      http://{ip}:{port}/?pin={self.pin}")
        print("\n  Tip: 'Add to Home Screen' makes it feel like a real app.")
        print("  Scan this to open it (if a QR shows below):\n")
        print_ascii_qr(url)
        print("=" * 58 + "\n")


def parse_args():
    p = argparse.ArgumentParser(description="Claude Phone Remote host")
    p.add_argument("--port", type=int, default=8765)
    p.add_argument("--pin", default=os.environ.get("CLAUDE_REMOTE_PIN"),
                   help="4-digit PIN (default: saved/generated)")
    p.add_argument("--width", type=int, default=1100,
                   help="max screenshot width sent to phone")
    p.add_argument("--quality", type=int, default=55, help="JPEG quality 1-95")
    p.add_argument("--fps", type=int, default=3, help="live-view frames per second")
    return p.parse_args()


def main():
    args = parse_args()
    if not WEBAPP_DIR.exists():
        print(f"[!] webapp folder not found at {WEBAPP_DIR}", file=sys.stderr)
        sys.exit(1)
    host = Host(args)
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    host.loop = loop
    app = host.build_app()
    host.banner()
    try:
        web.run_app(app, host="0.0.0.0", port=args.port, print=None, loop=loop)
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
