const assert = require('node:assert/strict');
const {createHash, webcrypto} = require('node:crypto');
const {readFileSync} = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const project = 'https://example.test/Oculum/';
const oldCommit = 'a'.repeat(40);
const newCommit = 'c'.repeat(40);
const entries = {
  [oldCommit]: {'assets/still.webp': 'same illustration', 'main.dart.js': 'old code'},
  [newCommit]: {'assets/still.webp': 'same illustration', 'main.dart.js': 'new code'},
};
const source = readFileSync(path.join(__dirname, '../../web/oculum_resource_worker.js'), 'utf8');
const rowFor = text => [createHash('sha256').update(text).digest('hex'), Buffer.byteLength(text)];

function fixture() {
  const storage = new Map();
  const calls = [];
  const failures = new Set();
  const caches = {
    async open(name) {
      if (!storage.has(name)) storage.set(name, new Map());
      const bucket = storage.get(name);
      return {
        match: async key => bucket.get(String(key))?.clone(),
        put: async (key, value) => { bucket.set(String(key), value.clone()); },
      };
    },
  };
  const fetch = async input => {
    const url = new URL(input.url || input);
    calls.push(url.href);
    const relative = url.pathname.slice(new URL(project).pathname.length);
    const commit = url.searchParams.get('v');
    if (relative === 'oculum-resources.json' && entries[commit]) {
      const files = Object.fromEntries(Object.entries(entries[commit]).map(([key, text]) => [key, rowFor(text)]));
      return Response.json({commit, files});
    }
    return new Response(failures.has(relative) ? 'corrupt' : entries[commit]?.[relative] || 'original passthrough');
  };
  function reopen() {
    const handlers = new Map();
    const self = {
      registration: {scope: project},
      addEventListener: (name, handler) => handlers.set(name, handler),
    };
    vm.runInNewContext(source, {self, caches, URL, fetch, Response, crypto: webcrypto});
    return {
      async assign(id, commit) {
        let result, pending;
        handlers.get('message')({
          source: {id, url: project},
          data: {type: 'oculum-release', commit},
          ports: [{postMessage: value => { result = value; }}],
          waitUntil: promise => { pending = promise; },
        });
        await pending;
        assert.equal(result, true);
      },
      get(id, path, options) {
        let pending;
        handlers.get('fetch')({
          clientId: id,
          request: new Request(new URL(path, project), options),
          respondWith: promise => { pending = promise; },
        });
        return pending;
      },
    };
  }
  return {reopen, calls, failures};
}

test('two releases reuse identical bytes even after worker restart and skip directly to the target', async () => {
  const f = fixture();
  const previous = f.reopen();
  await previous.assign('old', oldCommit);
  assert.equal(await (await previous.get('old', 'assets/still.webp')).text(), 'same illustration');
  assert.equal(await (await previous.get('old', 'main.dart.js')).text(), 'old code');
  const next = f.reopen();
  await next.assign('new', newCommit);
  assert.equal(await (await next.get('new', 'assets/still.webp')).text(), 'same illustration');
  assert.equal(await (await next.get('new', 'main.dart.js')).text(), 'new code');
  assert.equal(await (await next.get('old', 'main.dart.js')).text(), 'old code');
  assert.equal(f.calls.filter(url => url.includes('still.webp')).length, 1);
  assert.equal(f.calls.filter(url => url.includes('main.dart.js')).length, 2);
  assert.equal(f.calls.filter(url => url.includes('oculum-resources.json')).length, 2);
});

test('a failed hash serves no mismatching code and lets the correct result be fetched later', async () => {
  const f = fixture();
  const w = f.reopen();
  await w.assign('new', newCommit);
  f.failures.add('main.dart.js');
  assert.equal((await w.get('new', 'main.dart.js')).status, 503);
  f.failures.delete('main.dart.js');
  assert.equal(await (await w.get('new', 'main.dart.js')).text(), 'new code');
  assert.equal(f.calls.filter(url => url.includes('main.dart.js')).length, 2);
});

test('login returns, cross-origin requests and authenticated or partial responses bypass the asset cache', async () => {
  const f = fixture();
  const w = f.reopen();
  await w.assign('new', newCommit);
  assert.equal(w.get('new', '?code=temporary'), undefined);
  assert.equal(w.get('new', 'https://backend.example.test/assets/private'), undefined);
  assert.equal(w.get('new', 'assets/still.webp', {headers: {Authorization: 'test'}}), undefined);
  assert.equal(w.get('new', 'assets/still.webp', {headers: {Range: 'bytes=0-24'}}), undefined);
  assert.equal(f.calls.length, 1);
});
