importScripts('./js/vendor/workbox-sw.js');

workbox.setConfig({
  modulePathPrefix: './js/vendor/',
  debug: false,
});

workbox.core.clientsClaim();

self.addEventListener('install', () => {
  self.skipWaiting();
});

// Precache static app shell assets. Workbox versions this list automatically
// based on the contents of the array, so no manual CACHE_NAME bump is needed.
workbox.precaching.precacheAndRoute([
  './',
  './index.html',
  './css/style.css?v=30',
  './js/app.js?v=24',
  './js/vendor/alpine.min.js',
  './js/vendor/dexie.min.js',
  './js/vendor/fonts/SpaceGrotesk-Variable.ttf',
  './manifest.json',
  './icons/KREDIT.svg',
  './icons/icon-maskable.svg',
]);

// Remove any old precache entries left over from previous SW versions.
workbox.precaching.cleanupOutdatedCaches();

// Runtime cache for same-origin requests not already in the precache list.
// StaleWhileRevalidate serves from cache immediately, then refreshes the
// cache in the background, avoiding permanently stale content.
workbox.routing.registerRoute(
  ({ url }) => url.origin === self.location.origin,
  new workbox.strategies.StaleWhileRevalidate({
    cacheName: 'kredit-runtime-v6',
  })
);
