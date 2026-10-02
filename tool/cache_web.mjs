import {readdirSync, readFileSync, writeFileSync, statSync} from 'node:fs';
import {createHash} from 'node:crypto';
const root = 'build/web';
function walk(dir) { return readdirSync(dir).flatMap(name => { const path = `${dir}/${name}`; return statSync(path).isDirectory() ? walk(path) : [path.slice(root.length+1)]; }); }
const files = walk(root).filter(file => !file.endsWith('.symbols') && !file.endsWith('.map') && !file.includes('service_worker') && file !== 'lumen-sw.js' && (!file.startsWith('canvaskit/') || /^canvaskit\/(?:(?:chromium|webparagraph)\/)?canvaskit\.(js|wasm)$/.test(file)));
const hash = createHash('sha256');
for (const file of files) { hash.update(file); hash.update(readFileSync(`${root}/${file}`)); }
const version = hash.digest('hex').slice(0,12);
writeFileSync(`${root}/lumen-sw.js`, `
const PREFIX = 'lumen-' + self.registration.scope + '-';
const CACHE = PREFIX + '${version}';
const FILES = ${JSON.stringify(files)};
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
`);
console.log(`Offline cache prepared: ${files.length} local assets, version ${version}`);
