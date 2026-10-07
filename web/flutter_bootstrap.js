{{flutter_js}}
{{flutter_build_config}}

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
