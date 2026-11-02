const CACHE_NAME = "continuum-shell-v8";
const APP_SHELL = ["./","./index.html","./login.html","./inventory.html","./planning.html","./production.html","./quality.html","./inspection.html","./dispatch.html","./settings.html","./style.css","./theme.css","./app.js","./supabase-config.js","./manifest.webmanifest","./continuum-logo-lockup.png","./continuum-infinity-mark.png"];
self.addEventListener("install", event => { event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(APP_SHELL))); self.skipWaiting(); });
self.addEventListener("activate", event => { event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))))); self.clients.claim(); });
self.addEventListener("fetch", event => {
  if (event.request.method !== "GET" || new URL(event.request.url).origin !== self.location.origin) return;
  event.respondWith(caches.match(event.request).then(cached => cached || fetch(event.request).then(response => { const copy=response.clone(); caches.open(CACHE_NAME).then(cache=>cache.put(event.request,copy)); return response; }).catch(() => caches.match("./index.html"))));
});
