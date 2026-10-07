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

_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      loading.remove();
    } catch (_) {
      showStartupError();
    }
  },
}).catch(showStartupError);
