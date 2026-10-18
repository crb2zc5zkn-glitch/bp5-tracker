/* Offline support. Online: always fetch the newest files (so updates appear on the next open).
   Offline or on a slow connection (3 s): fall back to the saved copy. Logged workouts live in localStorage, not here. */
const V = "iron-records-v2";
const ASSETS = ["./", "index.html", "manifest.webmanifest", "icons/icon-192.png", "icons/icon-512.png", "icons/apple-touch-icon.png"];
self.addEventListener("install", e => { e.waitUntil(caches.open(V).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== V).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const r = e.request;
  if (r.method !== "GET" || new URL(r.url).origin !== location.origin) return;
  e.respondWith((async () => {
    const cache = await caches.open(V);
    try {
      const res = await Promise.race([
        fetch(r, { cache: "no-cache" }),
        new Promise((_, rej) => setTimeout(() => rej(new Error("slow")), 3000))
      ]);
      if (res && res.ok) cache.put(r, res.clone());
      return res;
    } catch (err) {
      const hit = (await cache.match(r, { ignoreSearch: true })) || (r.mode === "navigate" && (await cache.match("./")));
      if (hit) return hit;
      throw err;
    }
  })());
});
