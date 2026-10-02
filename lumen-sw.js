
const PREFIX = 'lumen-' + self.registration.scope + '-';
const CACHE = PREFIX + '3bef464e58d7';
const FILES = [".last_build_id",".nojekyll","assets/AssetManifest.bin","assets/AssetManifest.bin.json","assets/FontManifest.json","assets/NOTICES","assets/assets/curriculum.json","assets/assets/fonts/DMSerifDisplay.ttf","assets/assets/fonts/Manrope.ttf","assets/assets/fonts/NotoSans.ttf","assets/fonts/MaterialIcons-Regular.otf","assets/fonts/fallback/Roboto-Regular.ttf","assets/packages/cupertino_icons/assets/CupertinoIcons.ttf","assets/shaders/ink_sparkle.frag","assets/shaders/stretch_effect.frag","canvaskit/canvaskit.js","canvaskit/canvaskit.wasm","canvaskit/chromium/canvaskit.js","canvaskit/chromium/canvaskit.wasm","canvaskit/webparagraph/canvaskit.js","canvaskit/webparagraph/canvaskit.wasm","favicon.png","flutter.js","flutter_bootstrap.js","icons/Icon-192.png","icons/Icon-512.png","icons/Icon-maskable-192.png","icons/Icon-maskable-512.png","index.html","main.dart.js","manifest.json","research.html","version.json"];
self.addEventListener('install', event => event.waitUntil((async () => {
  const cache = await caches.open(CACHE);
  await cache.addAll(FILES.map(path => new URL(path, self.registration.scope).href));
  await self.skipWaiting();
})()));
self.addEventListener('activate', event => event.waitUntil((async () => {
  for (const key of await caches.keys()) if (key.startsWith(PREFIX) && key !== CACHE) await caches.delete(key);
  await self.clients.claim();
})()));
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || !url.href.startsWith(self.registration.scope)) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const cached = await cache.match(event.request, {ignoreSearch: true});
    if (cached) return cached;
    if (event.request.mode === 'navigate') return (await cache.match(new URL('index.html', self.registration.scope).href)) || fetch(event.request);
    return fetch(event.request);
  })());
});
