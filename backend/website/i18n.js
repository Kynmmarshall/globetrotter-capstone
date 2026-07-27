// Lightweight EN/FR i18n for the static website (separate from the Flutter
// app's own ARB-based localization). Elements opt in via data-i18n="key";
// this only ever sets textContent, never innerHTML, since some strings can
// come from user-controllable-ish contexts (Matomo section names) even
// though most are static copy.
(function () {
  const translations = {
    en: {
      navGetApp: 'Get the app',
      navExplore: 'Explore Yaoundé',
      navFeatures: 'Features',
      navStats: 'Stats',
      navApi: 'API',
      navCommunity: 'Community',

      heroTagline:
        'Plan faster. Travel smarter. Discover the landmarks, culture and nature of Yaoundé, Cameroon — with an itinerary planner that builds your day for you.',
      heroGetApp: 'Get the app',
      heroLaunchWeb: 'Launch web app',
      heroStatSpots: 'Yaoundé spots',
      heroStatPlatforms: 'Platforms',
      heroStatBilingual: 'Bilingual',

      downloadsEyebrow: 'Get the app',
      downloadsTitle: 'Available on your device',
      downloadsDesc: 'Download the native app, or launch it straight from your browser — no install required.',
      windowsTitle: 'Windows',
      windowsDesc: 'Native desktop app for Windows 10 and 11.',
      windowsMeta: '.exe package',
      windowsBtn: 'Download for Windows',
      androidTitle: 'Android',
      androidDesc: 'Install the APK directly on your phone or tablet.',
      androidMeta: '.apk package',
      androidBtn: 'Download for Android',
      webTitle: 'Web App',
      webDesc: 'No download — runs right in your browser.',
      webMeta: 'Chrome, Edge, Safari, Firefox',
      webBtn: 'Launch web app',

      exploreEyebrow: 'Explore',
      exploreTitle: 'Built around Yaoundé',
      exploreDesc: "Every destination in the app is a real, hand-picked spot in Cameroon's capital.",

      featuresEyebrow: 'Why trip_io',
      featuresTitle: 'Everything you need for a day in Yaoundé',
      feature1Title: 'Curated Yaoundé spots',
      feature1Desc: 'Landmarks, culture, markets and nature — with real photos, descriptions and locations.',
      feature2Title: 'Auto-generated itineraries',
      feature2Desc: 'Pick your stops and how much time you have — trip_io builds a timed schedule for you.',
      feature3Title: 'English & French',
      feature3Desc: "Fully localized for Cameroon's two official languages.",
      feature4Title: 'Fast & free',
      feature4Desc: 'Open source, easy to browse, works on desktop, mobile and web.',

      communityTitle: 'Join the trip_io community',
      communityDesc: 'Get updates, share tips and connect with other travellers exploring Yaoundé.',
      communityBtn: 'Join on WhatsApp',

      footerBuilt: 'Built for Yaoundé, Cameroon.',
      comingSoon: 'Coming soon',
      menuLabel: 'Menu',

      statsTitle: 'trip_io by the numbers',
      statsTagline: 'Real usage data pulled live from the app, refreshed every few minutes.',
      statsRefresh: 'Refresh',
      statsUpdatedAt: 'Updated {time}',
      kpiTotalUsers: 'Total travellers',
      kpiActiveToday: 'Active today',
      kpiActiveWeek: 'Active this week',
      chartDailyTitle: 'Daily active users',
      chartDailySub: 'Last 14 days',
      chartSectionsTitle: 'Most-visited sections',
      chartSectionsSub: 'This week',
      tableViewAsTable: 'View as table',
      tableDate: 'Date',
      tableActiveUsers: 'Active users',
      tableSection: 'Section',
      tableVisits: 'Visits',
      chartEmpty: 'Not enough data yet — check back once the app has some real usage.',
      chartLoadError: 'Could not load stats right now.',
      sectionDestinations: 'Destinations',
      sectionRecommendations: 'Recommendations',
      sectionItineraries: 'Itineraries',
      sectionProfile: 'Profile',
    },
    fr: {
      navGetApp: "Télécharger l'app",
      navExplore: 'Explorer Yaoundé',
      navFeatures: 'Fonctionnalités',
      navStats: 'Statistiques',
      navApi: 'API',
      navCommunity: 'Communauté',

      heroTagline:
        'Planifiez plus vite. Voyagez plus intelligemment. Découvrez les monuments, la culture et la nature de Yaoundé, Cameroun — avec un planificateur qui organise votre journée pour vous.',
      heroGetApp: "Télécharger l'app",
      heroLaunchWeb: "Lancer l'app web",
      heroStatSpots: 'Lieux à Yaoundé',
      heroStatPlatforms: 'Plateformes',
      heroStatBilingual: 'Bilingue',

      downloadsEyebrow: "Télécharger l'app",
      downloadsTitle: 'Disponible sur votre appareil',
      downloadsDesc: "Téléchargez l'app native, ou lancez-la directement depuis votre navigateur — sans installation.",
      windowsTitle: 'Windows',
      windowsDesc: 'Application native pour Windows 10 et 11.',
      windowsMeta: 'Paquet .exe',
      windowsBtn: 'Télécharger pour Windows',
      androidTitle: 'Android',
      androidDesc: "Installez l'APK directement sur votre téléphone ou tablette.",
      androidMeta: 'Paquet .apk',
      androidBtn: 'Télécharger pour Android',
      webTitle: 'App Web',
      webDesc: 'Aucun téléchargement — fonctionne directement dans votre navigateur.',
      webMeta: 'Chrome, Edge, Safari, Firefox',
      webBtn: "Lancer l'app web",

      exploreEyebrow: 'Explorer',
      exploreTitle: 'Conçu autour de Yaoundé',
      exploreDesc: "Chaque destination de l'app est un lieu réel, sélectionné à la main dans la capitale du Cameroun.",

      featuresEyebrow: 'Pourquoi trip_io',
      featuresTitle: "Tout ce qu'il vous faut pour une journée à Yaoundé",
      feature1Title: 'Lieux sélectionnés à Yaoundé',
      feature1Desc: 'Monuments, culture, marchés et nature — avec de vraies photos, descriptions et localisations.',
      feature2Title: 'Itinéraires générés automatiquement',
      feature2Desc: 'Choisissez vos arrêts et votre temps disponible — trip_io construit un planning chronométré pour vous.',
      feature3Title: 'Anglais et français',
      feature3Desc: 'Entièrement localisé pour les deux langues officielles du Cameroun.',
      feature4Title: 'Rapide et gratuit',
      feature4Desc: 'Open source, facile à parcourir, fonctionne sur ordinateur, mobile et web.',

      communityTitle: 'Rejoignez la communauté trip_io',
      communityDesc: "Recevez des actualités, partagez des astuces et échangez avec d'autres voyageurs qui explorent Yaoundé.",
      communityBtn: 'Rejoindre sur WhatsApp',

      footerBuilt: 'Conçu pour Yaoundé, Cameroun.',
      comingSoon: 'Bientôt disponible',
      menuLabel: 'Menu',

      statsTitle: 'trip_io en chiffres',
      statsTagline: "Données d'utilisation réelles, mises à jour automatiquement toutes les quelques minutes.",
      statsRefresh: 'Actualiser',
      statsUpdatedAt: 'Mis à jour à {time}',
      kpiTotalUsers: 'Voyageurs au total',
      kpiActiveToday: "Actifs aujourd'hui",
      kpiActiveWeek: 'Actifs cette semaine',
      chartDailyTitle: 'Utilisateurs actifs par jour',
      chartDailySub: '14 derniers jours',
      chartSectionsTitle: 'Sections les plus visitées',
      chartSectionsSub: 'Cette semaine',
      tableViewAsTable: 'Voir sous forme de tableau',
      tableDate: 'Date',
      tableActiveUsers: 'Utilisateurs actifs',
      tableSection: 'Section',
      tableVisits: 'Visites',
      chartEmpty: "Pas encore assez de données — revenez une fois que l'app aura été utilisée.",
      chartLoadError: 'Impossible de charger les statistiques pour le moment.',
      sectionDestinations: 'Destinations',
      sectionRecommendations: 'Recommandations',
      sectionItineraries: 'Itinéraires',
      sectionProfile: 'Profil',
    },
  };

  const STORAGE_KEY = 'trip_io_lang';

  function detectDefault() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved === 'en' || saved === 'fr') return saved;
    return navigator.language && navigator.language.toLowerCase().startsWith('fr') ? 'fr' : 'en';
  }

  let currentLang = detectDefault();

  function t(key, vars) {
    const dict = translations[currentLang] || translations.en;
    let value = dict[key] ?? translations.en[key] ?? key;
    if (vars) {
      Object.keys(vars).forEach((varKey) => {
        value = value.replace(`{${varKey}}`, vars[varKey]);
      });
    }
    return value;
  }

  function applyTranslations() {
    document.documentElement.lang = currentLang;
    document.querySelectorAll('[data-i18n]').forEach((node) => {
      node.textContent = t(node.getAttribute('data-i18n'));
    });
    document.querySelectorAll('[data-i18n-aria-label]').forEach((node) => {
      node.setAttribute('aria-label', t(node.getAttribute('data-i18n-aria-label')));
    });
    document.querySelectorAll('.lang-btn').forEach((btn) => {
      const active = btn.dataset.lang === currentLang;
      btn.classList.toggle('is-active', active);
      btn.setAttribute('aria-pressed', String(active));
    });
    document.dispatchEvent(new CustomEvent('i18n:changed', { detail: { lang: currentLang } }));
  }

  function setLang(lang) {
    if (lang !== 'en' && lang !== 'fr') return;
    currentLang = lang;
    localStorage.setItem(STORAGE_KEY, lang);
    applyTranslations();
  }

  function init() {
    applyTranslations();
    document.querySelectorAll('.lang-btn').forEach((btn) => {
      btn.addEventListener('click', () => setLang(btn.dataset.lang));
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Exposed so script.js/stats.js can translate strings they generate
  // dynamically (badges, chart labels, empty states) and react to language
  // switches via the "i18n:changed" event.
  window.tripIoI18n = {
    t,
    get lang() {
      return currentLang;
    },
  };
})();
