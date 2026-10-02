{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: { canvasKitBaseUrl: new URL('canvaskit/', document.baseURI).href },
  onEntrypointLoaded: async (initializer) => {
    const runner = await initializer.initializeEngine();
    await runner.runApp();
    document.getElementById('loading')?.remove();
  }
}).catch(() => {
  document.getElementById('loading').textContent = 'Lumen could not start. Please reload while online.';
});

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register(new URL('lumen-sw.js', document.baseURI)).catch(error => console.warn('Offline setup unavailable', error));
}
