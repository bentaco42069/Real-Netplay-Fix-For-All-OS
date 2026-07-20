/* Minimal service worker: makes the app installable and loads the shell fast.
 * It deliberately stays out of the way of the control link (/ws) and /health —
 * those always go straight to the network. */

const CACHE = "claude-remote-v1";
const SHELL = ["./", "index.html", "app.js", "style.css", "manifest.webmanifest", "icon.svg"];

self.addEventListener("install", (e) => {
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).catch(() => {}));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const url = new URL(e.request.url);
  // Never touch the socket or health probe.
  if (url.pathname === "/ws" || url.pathname === "/health") return;
  if (e.request.method !== "GET") return;

  // Network-first for the shell so updates land; fall back to cache offline.
  e.respondWith(
    fetch(e.request)
      .then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(e.request, copy)).catch(() => {});
        return res;
      })
      .catch(() => caches.match(e.request).then((r) => r || caches.match("index.html")))
  );
});
