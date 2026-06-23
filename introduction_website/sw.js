const CACHE_NAME = 'sunday-school-promo-v1';
const ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './detailed_features.md',
  './public/logo.png',
  './public/favicon.ico',
  './public/images/icons/icon-72x72.png',
  './public/images/icons/icon-96x96.png',
  './public/images/icons/icon-128x128.png',
  './public/images/icons/icon-144x144.png',
  './public/images/icons/icon-152x152.png',
  './public/images/icons/icon-192x192.png',
  './public/images/icons/icon-384x384.png',
  './public/images/icons/icon-512x512.png',
  './public/images/icons/icon-192x192-maskable.png',
  './public/images/icons/icon-512x512-maskable.png'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS);
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  e.respondWith(
    caches.match(e.request).then((cachedResponse) => {
      return cachedResponse || fetch(e.request).catch(() => {
        // Fallback for document navigation if offline and not cached
        if (e.request.mode === 'navigate') {
          return caches.match('./index.html');
        }
      });
    })
  );
});
