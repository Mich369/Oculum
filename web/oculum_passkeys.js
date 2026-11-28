(() => {
  'use strict';

  function supported() {
    return globalThis.isSecureContext === true &&
      typeof globalThis.PublicKeyCredential === 'function' &&
      typeof navigator.credentials?.create === 'function' &&
      typeof navigator.credentials?.get === 'function';
  }

  function decode(value) {
    if (typeof value !== 'string' || !/^[A-Za-z0-9_-]+={0,2}$/.test(value) || value.length > 16384) {
      throw new Error('Invalid WebAuthn option');
    }
    const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
    return Uint8Array.from(atob(base64), (character) => character.charCodeAt(0));
  }

  function encode(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (const value of bytes) binary += String.fromCharCode(value);
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }

  function publicKeyOptions(options, registration) {
    const rpId = registration ? options.rp?.id : options.rpId;
    if (rpId !== location.hostname) throw new Error('Unexpected WebAuthn origin');
    const timeout = typeof options.timeout === 'number' && options.timeout > 0
      ? Math.min(options.timeout, 120000) : 120000;
    const credentialClass = globalThis.PublicKeyCredential;
    const adjusted = { ...options, timeout };
    if (registration) {
      adjusted.authenticatorSelection = {
        ...options.authenticatorSelection,
        residentKey: 'required',
        requireResidentKey: true,
        userVerification: 'required',
      };
      if (typeof credentialClass.parseCreationOptionsFromJSON === 'function') {
        return credentialClass.parseCreationOptionsFromJSON(adjusted);
      }
      adjusted.user = { ...options.user, id: decode(options.user?.id) };
    } else {
      adjusted.userVerification = 'required';
      if (typeof credentialClass.parseRequestOptionsFromJSON === 'function') {
        return credentialClass.parseRequestOptionsFromJSON(adjusted);
      }
    }
    adjusted.challenge = decode(adjusted.challenge);
    for (const field of ['excludeCredentials', 'allowCredentials']) {
      if (adjusted[field]) {
        adjusted[field] = adjusted[field].map((entry) => ({ ...entry, id: decode(entry.id) }));
      }
    }
    return adjusted;
  }

  function asResponse(credential, registration) {
    if (credential?.type !== 'public-key') throw new Error('Invalid WebAuthn credential');
    if (typeof credential.toJSON === 'function') return credential.toJSON();
    const source = credential.response;
    const response = { clientDataJSON: encode(source.clientDataJSON) };
    if (registration) {
      response.attestationObject = encode(source.attestationObject);
      response.transports = typeof source.getTransports === 'function' ? source.getTransports() : [];
    } else {
      response.authenticatorData = encode(source.authenticatorData);
      response.signature = encode(source.signature);
      if (source.userHandle != null) response.userHandle = encode(source.userHandle);
    }
    return {
      id: credential.id, rawId: encode(credential.rawId), type: credential.type, response,
      authenticatorAttachment: credential.authenticatorAttachment ?? undefined,
      clientExtensionResults: credential.getClientExtensionResults(),
    };
  }

  async function request(options, registration) {
    if (!supported()) throw new Error('WebAuthn unavailable');
    const publicKey = publicKeyOptions(options, registration);
    try {
      const credential = registration
        ? await navigator.credentials.create({ publicKey })
        : await navigator.credentials.get({ publicKey, mediation: 'required' });
      return credential ? asResponse(credential, registration) : null;
    } catch (error) {
      if (error?.name === 'AbortError' || error?.name === 'NotAllowedError') return null;
      // The credential, authenticator errors, and challenge stay out of logs.
      throw new Error('The device could not use the passkey');
    }
  }

  globalThis.oculumPasskeys = Object.freeze({
    supported,
    create: (options) => request(options, true),
    get: (options) => request(options, false),
  });
})();
