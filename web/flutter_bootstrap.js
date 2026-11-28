{{flutter_js}}
{{flutter_build_config}}

// Version both scripts so an already open browser receives the published build.
for (const build of _flutter.buildConfig.builds) {
  if (build.compileTarget === 'dart2js') {
    build.mainJsPath = `${build.mainJsPath || 'main.dart.js'}?v=__OCULUM_BUILD__`;
  }
}

const loading = document.getElementById('oculum-loading');
const loadingMessage = document.getElementById('oculum-loading-message');
const showStartupError = () => {
  loadingMessage.textContent = 'L’Occhio non si è aperto. Controlla la connessione e riprova.';
  document.getElementById('oculum-retry').hidden = false;
};

async function connectResourceCache() {
  if (!('serviceWorker' in navigator) || !/^[0-9a-f]{40}$/.test('__OCULUM_BUILD__')) return;
  const client = navigator.serviceWorker;
  const controllerReady = async () => {
    await client.register(new URL('oculum_resource_worker.js', document.baseURI));
    await client.ready;
    if (!client.controller) {
      await new Promise(resolve => client.addEventListener('controllerchange', resolve, {once: true}));
    }
    const channel = new MessageChannel();
    await new Promise(resolve => {
      channel.port1.onmessage = resolve;
      client.controller.postMessage({type: 'oculum-release', commit: '__OCULUM_BUILD__'}, [channel.port2]);
    }).finally(() => channel.port1.close());
  };
  let timer;
  try {
    await Promise.race([controllerReady(), new Promise(resolve => { timer = setTimeout(resolve, 2500); })]);
  } catch (_) {
    // The browser can still load directly from Pages when service workers are unavailable.
  } finally {
    clearTimeout(timer);
  }
}

connectResourceCache().then(() => _flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      loading.remove();
    } catch (_) {
      showStartupError();
    }
  },
})).catch(showStartupError);
