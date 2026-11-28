'use strict';

const scope = new URL(self.registration.scope);
const assetCache = `oculum-static-sha256-1:${scope.pathname}`;
const metadataCache = `oculum-static-revisions-1:${scope.pathname}`;
const revisions = new Map();
const manifests = new Map();
const validCommit = value => typeof value === 'string' && /^[0-9a-f]{40}$/.test(value);
const scopedUrl = path => new URL(path, scope);

self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));

function manifestFor(commit) {
  if (!manifests.has(commit)) {
    const request = scopedUrl(`oculum-resources.json?v=${commit}`);
    const task = (async () => {
      const cache = await caches.open(metadataCache);
      const saved = await cache.match(request);
      const response = saved || await fetch(request, {
        cache: 'no-cache', credentials: 'omit', redirect: 'error',
      });
      if (!response.ok) throw new Error('Manifest unavailable');
      const parsed = await response.clone().json();
      if (parsed.commit !== commit || !parsed.files || Array.isArray(parsed.files)) {
        throw new Error('Manifest revision mismatch');
      }
      if (!saved) await cache.put(request, response).catch(() => {});
      return parsed.files;
    })();
    manifests.set(commit, task);
    task.catch(() => manifests.delete(commit));
  }
  return manifests.get(commit);
}

const clientMarker = id => scopedUrl(`__oculum_worker_client__/${encodeURIComponent(id)}`);

self.addEventListener('message', event => {
  const {type, commit} = event.data || {};
  const source = event.source;
  if (type !== 'oculum-release' || !validCommit(commit) || !source?.id ||
      !source.url.startsWith(scope.href) || !event.ports[0]) return;
  event.waitUntil((async () => {
    try {
      await manifestFor(commit);
      revisions.set(source.id, commit);
      const cache = await caches.open(metadataCache);
      await cache.put(clientMarker(source.id), new Response(commit)).catch(() => {});
      event.ports[0].postMessage(true);
    } catch (_) {
      event.ports[0].postMessage(false);
    }
  })());
});

async function revisionOf(clientId) {
  if (revisions.has(clientId)) return revisions.get(clientId);
  const cache = await caches.open(metadataCache);
  const saved = await cache.match(clientMarker(clientId));
  const commit = await saved?.text();
  if (!validCommit(commit)) return null;
  revisions.set(clientId, commit);
  return commit;
}

async function readResource(request, url, clientId) {
  const commit = await revisionOf(clientId).catch(() => null);
  if (commit === null || (url.search && url.search !== `?v=${commit}`)) return fetch(request);
  const files = await manifestFor(commit).catch(() => null);
  const relative = url.pathname.slice(scope.pathname.length);
  const pair = files && Object.hasOwn(files, relative) ? files[relative] : null;
  if (!Array.isArray(pair) || !/^[0-9a-f]{64}$/.test(pair[0]) ||
      !Number.isSafeInteger(pair[1]) || pair[1] < 0 || pair[1] > 24 * 1024 * 1024) {
    return fetch(request);
  }
  const [digest, size] = pair;
  const extension = /\.([A-Za-z0-9]+)$/.exec(relative)?.[1] || 'bin';
  const key = scopedUrl(`__oculum_worker_content__/${digest}.${extension}`);
  const cache = await caches.open(assetCache).catch(() => null);
  const cached = await cache?.match(key).catch(() => null);
  if (cached) return cached;
  url.searchParams.set('v', commit);
  const response = await fetch(url, {cache: 'no-cache', credentials: 'omit', redirect: 'error'});
  if (response.status !== 200) return response;
  const bytes = await response.clone().arrayBuffer();
  const raw = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes));
  const actual = Array.from(raw, byte => byte.toString(16).padStart(2, '0')).join('');
  if (bytes.byteLength !== size || actual !== digest) {
    return new Response('Oculum: risorsa ancora in aggiornamento.', {status: 503});
  }
  await cache?.put(key, response.clone()).catch(() => {});
  return response;
}

self.addEventListener('fetch', event => {
  const {clientId, request} = event;
  const url = new URL(request.url);
  if (!clientId || request.method !== 'GET' || request.mode === 'navigate' ||
      request.headers.has('Authorization') || request.headers.has('Range') ||
      url.origin !== scope.origin || !url.pathname.startsWith(scope.pathname)) return;
  const relative = url.pathname.slice(scope.pathname.length);
  if (!relative.startsWith('assets/') && !relative.startsWith('canvaskit/') &&
      !/^main\.dart(?:\.js_\d+\.part)?\.(?:js|mjs|wasm)$/.test(relative)) return;
  event.respondWith(readResource(request, url, clientId));
});
