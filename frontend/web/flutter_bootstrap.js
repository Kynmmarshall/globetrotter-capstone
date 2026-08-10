{{flutter_js}}
{{flutter_build_config}}

// Custom bootstrap (instead of the default generated one) purely so we get
// a hook to remove the #trip-io-splash overlay (see index.html) once
// Flutter has actually rendered something - without this, that overlay
// would just sit there forever since nothing else ever touches it.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    const splash = document.getElementById('trip-io-splash');
    if (splash) {
      splash.classList.add('trip-io-splash-hide');
      splash.addEventListener('transitionend', () => splash.remove(), {
        once: true,
      });
    }
  },
});
