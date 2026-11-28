const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { test } = require('node:test');
const vm = require('node:vm');

const source = readFileSync(join(__dirname, '..', '..', 'web', 'oculum_passkeys.js'), 'utf8');
const hostname = 'mich369.github.io';
const data = Uint8Array.from([1, 2, 3]).buffer;

function platform({ secure = true, create, get, credentialClass = function PublicKeyCredential() {} } = {}) {
  const globals = vm.createContext({
    isSecureContext: secure,
    navigator: { credentials: { create: create ?? (async () => null), get: get ?? (async () => null) } },
    location: { hostname }, PublicKeyCredential: credentialClass, atob, btoa,
  });
  vm.runInContext(source, globals);
  return globals.oculumPasskeys;
}

test('requires a secure context and the current relying-party hostname', async () => {
  assert.equal(platform({ secure: false }).supported(), false);
  const client = platform();
  assert.equal(client.supported(), true);
  await assert.rejects(client.get({ rpId: 'another-site.example', challenge: 'AQID' }), /origin/);
});

test('system registration has discoverable credentials and user verification', async () => {
  const client = platform({ create: async ({ publicKey }) => {
    assert.deepEqual(Array.from(publicKey.challenge), [1, 2, 3]);
    assert.deepEqual(Array.from(publicKey.user.id), [1, 2, 3]);
    assert.equal(publicKey.authenticatorSelection.userVerification, 'required');
    assert.equal(publicKey.authenticatorSelection.residentKey, 'required');
    assert.equal(publicKey.authenticatorSelection.authenticatorAttachment, undefined);
    return {
      id: 'AQID', rawId: data, type: 'public-key', authenticatorAttachment: 'platform',
      response: { clientDataJSON: data, attestationObject: data, getTransports: () => ['internal'] },
      getClientExtensionResults: () => ({}),
    };
  } });
  const response = await client.create({ rp: { id: hostname }, challenge: 'AQID', user: { id: 'AQID' } });
  assert.equal(response.rawId, 'AQID');
  assert.equal(response.response.attestationObject, 'AQID');
  assert.deepEqual(response.response.transports, ['internal']);
});

test('sign-in uses the visible system prompt and converts assertion fields', async () => {
  const client = platform({ get: async ({ publicKey, mediation }) => {
    assert.equal(mediation, 'required');
    assert.equal(publicKey.userVerification, 'required');
    assert.deepEqual(Array.from(publicKey.allowCredentials[0].id), [1, 2, 3]);
    return {
      id: 'AQID', rawId: data, type: 'public-key',
      response: { clientDataJSON: data, authenticatorData: data, signature: data, userHandle: data },
      getClientExtensionResults: () => ({}),
    };
  } });
  const result = await client.get({ rpId: hostname, challenge: 'AQID', allowCredentials: [{ id: 'AQID' }] });
  assert.equal(result.response.userHandle, 'AQID');
  assert.equal(result.response.signature, 'AQID');
});

test('returns cleanly after cancel and allows an independent retry', async () => {
  let count = 0;
  function Credential() {}
  Credential.parseRequestOptionsFromJSON = (options) => options;
  const client = platform({ credentialClass: Credential, get: async () => {
    if (count++ === 0) throw Object.assign(new Error('local system detail'), { name: 'NotAllowedError' });
    return { type: 'public-key', toJSON: () => ({ id: 'fresh', response: {} }) };
  } });
  assert.equal(await client.get({ rpId: hostname, challenge: 'AQID' }), null);
  assert.equal((await client.get({ rpId: hostname, challenge: 'BAUG' })).id, 'fresh');
});
