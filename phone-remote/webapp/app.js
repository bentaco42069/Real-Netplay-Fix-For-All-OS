/* Claude Phone Remote — phone side.
 *
 * The important part: a WebSocket link that survives drops. It reconnects on
 * its own with exponential backoff, re-does the PIN handshake, and re-arms
 * live view — so if WiFi hiccups or your phone sleeps, control comes back
 * without you touching anything.
 */

"use strict";

const $ = (id) => document.getElementById(id);

const els = {
  dot: $("dot"), status: $("status"),
  gate: $("gate"), pinInput: $("pinInput"), connectBtn: $("connectBtn"), gateMsg: $("gateMsg"),
  screenWrap: $("screenWrap"), screen: $("screen"),
  promptBox: $("promptBox"), promptText: $("promptText"), autoSend: $("autoSend"),
  sendClaude: $("sendClaude"), promptNote: $("promptNote"),
  keys: $("keys"), typeBtn: $("typeBtn"),
  liveBtn: $("liveBtn"), shotBtn: $("shotBtn"),
};

const state = {
  pin: null,
  ws: null,
  connected: false,     // socket open AND handshake accepted
  wantOpen: false,      // user asked to be connected -> keep reconnecting
  live: false,          // desired live-view state (re-armed after reconnect)
  screen: { w: 0, h: 0 },
  retry: 0,             // backoff attempt counter
  reconnectTimer: null,
  heartbeatTimer: null,
  watchdogTimer: null,
  lastPong: 0,
};

const BACKOFF = [500, 1000, 2000, 4000, 8000, 15000]; // ms, capped at last
const HEARTBEAT_MS = 5000;
const PONG_TIMEOUT_MS = 12000;

// ---- UI helpers ------------------------------------------------------------

function setStatus(text, kind) {
  els.status.textContent = text;
  els.dot.className = "dot" + (kind ? " " + kind : "");
}

function showConnectedUI(on) {
  els.gate.classList.toggle("hidden", on);
  els.screenWrap.classList.toggle("hidden", !on);
  els.promptBox.classList.toggle("hidden", !on);
  els.keys.classList.toggle("hidden", !on);
}

// ---- Connection lifecycle --------------------------------------------------

function wsURL() {
  const proto = location.protocol === "https:" ? "wss" : "ws";
  return `${proto}://${location.host}/ws`;
}

function connect() {
  if (!state.pin) return;
  state.wantOpen = true;
  clearTimeout(state.reconnectTimer);

  // Tear down any half-dead socket first.
  if (state.ws) {
    try { state.ws.onclose = null; state.ws.close(); } catch (e) {}
    state.ws = null;
  }

  setStatus(state.retry ? `reconnecting… (try ${state.retry})` : "connecting…", "warn");

  let ws;
  try {
    ws = new WebSocket(wsURL());
  } catch (e) {
    scheduleReconnect();
    return;
  }
  state.ws = ws;

  ws.onopen = () => {
    // Socket is open, but not "connected" until the PIN is accepted.
    send({ type: "hello", pin: state.pin });
  };

  ws.onmessage = (ev) => {
    let msg;
    try { msg = JSON.parse(ev.data); } catch (e) { return; }
    handle(msg);
  };

  ws.onclose = () => {
    state.connected = false;
    stopHeartbeat();
    if (state.wantOpen) {
      setStatus("connection dropped", "bad");
      scheduleReconnect();
    } else {
      setStatus("disconnected", "");
    }
  };

  ws.onerror = () => { /* onclose will follow and handle reconnect */ };
}

function scheduleReconnect() {
  if (!state.wantOpen) return;
  clearTimeout(state.reconnectTimer);
  const delay = BACKOFF[Math.min(state.retry, BACKOFF.length - 1)];
  state.retry += 1;
  setStatus(`dropped — retrying in ${Math.round(delay / 1000)}s`, "bad");
  state.reconnectTimer = setTimeout(connect, delay);
}

function disconnect() {
  state.wantOpen = false;
  clearTimeout(state.reconnectTimer);
  stopHeartbeat();
  if (state.ws) { try { state.ws.close(); } catch (e) {} }
}

function send(obj) {
  const ws = state.ws;
  if (ws && ws.readyState === WebSocket.OPEN) {
    try { ws.send(JSON.stringify(obj)); return true; } catch (e) {}
  }
  return false;
}

// ---- Heartbeat / watchdog --------------------------------------------------
// A socket can look "open" long after the network is actually gone. We ping
// on a timer and, if no pong comes back in time, we force a reconnect.

function startHeartbeat() {
  stopHeartbeat();
  state.lastPong = Date.now();
  state.heartbeatTimer = setInterval(() => {
    send({ type: "ping", t: Date.now() });
  }, HEARTBEAT_MS);
  state.watchdogTimer = setInterval(() => {
    if (Date.now() - state.lastPong > PONG_TIMEOUT_MS) {
      // Silent death: drop and let backoff reconnect.
      if (state.ws) { try { state.ws.close(); } catch (e) {} }
    }
  }, HEARTBEAT_MS);
}

function stopHeartbeat() {
  clearInterval(state.heartbeatTimer);
  clearInterval(state.watchdogTimer);
  state.heartbeatTimer = state.watchdogTimer = null;
}

// ---- Message handling ------------------------------------------------------

function handle(msg) {
  switch (msg.type) {
    case "welcome":
      if (msg.ok) {
        state.connected = true;
        state.retry = 0;
        state.screen = msg.screen || { w: 0, h: 0 };
        const io = msg.input ? "" : "  (input OFF on host)";
        setStatus(`connected · ${msg.host || "PC"}${io}`, "ok");
        showConnectedUI(true);
        els.gateMsg.textContent = "";
        startHeartbeat();
        // Re-arm live view if it was on before the drop.
        if (state.live) send({ type: "live", on: true });
        else send({ type: "shot" });
      } else {
        // Bad PIN: stop retrying and show the gate again.
        state.wantOpen = false;
        state.pin = null;
        try { localStorage.removeItem("claudeRemotePin"); } catch (e) {}
        showConnectedUI(false);
        setStatus("bad PIN", "bad");
        els.gateMsg.textContent = "That PIN didn't match. Check the host window.";
      }
      break;

    case "frame":
      state.screen = { w: msg.sw, h: msg.sh };
      els.screen.src = "data:image/jpeg;base64," + msg.jpeg;
      break;

    case "pong":
      state.lastPong = Date.now();
      break;

    case "prompt_done":
      els.promptNote.textContent = msg.note || (msg.focused ? "sent to Claude" : "typed into active window");
      setTimeout(() => { els.promptNote.textContent = ""; }, 4000);
      // Grab a fresh frame so you can see the result.
      if (!state.live) setTimeout(() => send({ type: "shot" }), 600);
      break;

    case "error":
      els.promptNote.textContent = "host: " + msg.msg;
      break;
  }
}

// ---- Input actions ---------------------------------------------------------

function toggleLive() {
  state.live = !state.live;
  els.liveBtn.textContent = "Live: " + (state.live ? "on" : "off");
  els.liveBtn.classList.toggle("on", state.live);
  send({ type: "live", on: state.live });
}

// Tap the live image -> click the same spot on the PC.
els.screen.addEventListener("click", (e) => {
  const r = els.screen.getBoundingClientRect();
  const nx = (e.clientX - r.left) / r.width;
  const ny = (e.clientY - r.top) / r.height;
  send({ type: "click", x: nx, y: ny, sw: state.screen.w, sh: state.screen.h });
  if (!state.live) setTimeout(() => send({ type: "shot" }), 250);
});

els.sendClaude.addEventListener("click", () => {
  const text = els.promptText.value;
  if (!text.trim()) return;
  send({ type: "prompt", text, send: els.autoSend.checked });
  els.promptText.value = "";
  els.promptNote.textContent = "sending…";
});

els.typeBtn.addEventListener("click", () => {
  const text = prompt("Type text to send to the PC:");
  if (text) send({ type: "type", text });
});

els.keys.addEventListener("click", (e) => {
  const btn = e.target.closest("button");
  if (!btn) return;
  if (btn.dataset.key) send({ type: "key", key: btn.dataset.key });
  else if (btn.dataset.hotkey) send({ type: "hotkey", keys: btn.dataset.hotkey.split(",") });
  if (!state.live) setTimeout(() => send({ type: "shot" }), 250);
});

els.liveBtn.addEventListener("click", toggleLive);
els.shotBtn.addEventListener("click", () => send({ type: "shot" }));

els.connectBtn.addEventListener("click", () => {
  const pin = els.pinInput.value.trim();
  if (!/^\d{4}$/.test(pin)) { els.gateMsg.textContent = "PIN is 4 digits."; return; }
  state.pin = pin;
  state.retry = 0;
  try { localStorage.setItem("claudeRemotePin", pin); } catch (e) {}
  connect();
});

// ---- Reconnect triggers on mobile lifecycle --------------------------------
// Phones aggressively suspend background tabs. When we come back to the
// foreground or the network returns, kick a reconnect immediately instead of
// waiting out the backoff timer.

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible" && state.wantOpen && !state.connected) {
    state.retry = 0;
    connect();
  }
});
window.addEventListener("online", () => {
  if (state.wantOpen && !state.connected) { state.retry = 0; connect(); }
});
window.addEventListener("focus", () => {
  if (state.wantOpen && !state.connected) { state.retry = 0; connect(); }
});

// ---- Boot ------------------------------------------------------------------

(function boot() {
  // PIN can come from the URL (?pin=1234) or a previous session.
  const urlPin = new URLSearchParams(location.search).get("pin");
  let saved = null;
  try { saved = localStorage.getItem("claudeRemotePin"); } catch (e) {}
  const pin = (urlPin && /^\d{4}$/.test(urlPin)) ? urlPin : saved;

  if (pin && /^\d{4}$/.test(pin)) {
    els.pinInput.value = pin;
    state.pin = pin;
    try { localStorage.setItem("claudeRemotePin", pin); } catch (e) {}
    connect();
  } else {
    setStatus("enter PIN", "");
  }

  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("sw.js").catch(() => {});
  }
})();
