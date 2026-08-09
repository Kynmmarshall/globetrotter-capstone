document.getElementById('year').textContent = new Date().getFullYear();

if (window.AOS) {
  AOS.init({ duration: 700, once: true, offset: 60, easing: 'ease-out-cubic' });
}

// Hero background slideshow: cycles through real Yaoundé destination photos
// (rather than one static hero image forever), picking both the next image
// and its entrance animation at random each time so the rotation doesn't
// just repeat the same fade - see the .anim-* keyframes in style.css.
// Called once buildHeroSlideshow() below has injected the actual slide
// elements - there's nothing to cycle through before that.
function initHeroSlideshow() {
  const slides = document.querySelectorAll('.hero-bg-slide');
  if (slides.length < 2) return;
  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  const animations = ['anim-cube', 'anim-flip', 'anim-vortex', 'anim-curtain', 'anim-fall', 'anim-swing', 'anim-iris', 'anim-blur'];
  let current = 0;

  function pickNextIndex() {
    let next = Math.floor(Math.random() * slides.length);
    while (next === current) {
      next = Math.floor(Math.random() * slides.length);
    }
    return next;
  }

  function showSlide(index) {
    const outgoing = slides[current];
    const incoming = slides[index];
    const animation = animations[Math.floor(Math.random() * animations.length)];

    outgoing.classList.remove('is-active');
    incoming.classList.remove(...animations);
    // Forces a reflow so the animation replays even if this slide happened
    // to get the same animation class as last time it was shown.
    void incoming.offsetWidth;
    incoming.classList.add(animation, 'is-active');

    current = index;
  }

  setInterval(() => showSlide(pickNextIndex()), 3200);
}

// Counts a stat value up from 0 to its target once it scrolls into view,
// rather than just appearing - reads the target from data-count-to so the
// destinations count (set async below, from the live API) animates too.
function animateCountUp(el) {
  const target = Number(el.dataset.countTo);
  if (!Number.isFinite(target)) return;
  const duration = 1000;
  const start = performance.now();
  function tick(now) {
    const progress = Math.min((now - start) / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    el.textContent = String(Math.round(target * eased));
    if (progress < 1) requestAnimationFrame(tick);
    else el.textContent = String(target);
  }
  requestAnimationFrame(tick);
}

// stat-destinations is excluded here and handled separately below: its
// real value only arrives once the /destinations fetch resolves, which
// often happens after this observer would already have fired using a
// meaningless placeholder target.
const countTargets = document.querySelectorAll('[data-count-to]:not(#stat-destinations)');
if ('IntersectionObserver' in window && countTargets.length) {
  const countObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          animateCountUp(entry.target);
          countObserver.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.6 }
  );
  countTargets.forEach((el) => countObserver.observe(el));
}

// Fisher-Yates - used to vary the order the curated hero images play in
// between page loads, same "at random" spirit as the slideshow's own
// animation picking above, rather than always opening on the same image.
function shuffled(items) {
  const arr = items.slice();
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

// Hand-picked highlight reel for the hero background - deliberately a
// small, curated subset rather than all 101 destinations, so the very
// first thing a visitor sees is consistently strong. Filenames are served
// straight off recommendation_service's /static/destinations mount (same
// as every other destination image on the site), so re-uploading a photo
// under one of these names through the admin dashboard updates the hero
// automatically without touching this list.
const CURATED_HERO_IMAGES = [
  'bar_panoramique.jpg',
  'basilica.png',
  'blackitude_museum.png',
  'cathedrale_notre_dame_des_victoires.jpg',
  'briqueterie_soya.jpg',
  'grande_mosquee_de_yaounde.jpg',
  'v_gaming.png',
  'Stade_Paul_Biya.jpg',
  'reunification_monument.png',
  'pizzeria_glacier_grill_dolcezza.jpg',
  'mvog_betsi_zoo.png',
  'monument_de_l_independance.jpg',
  'majestic_cinema.jpg',
  'cez_fitness_club.jpg',
  'albatros_premium_hotel.jpg',
  'bois_d_ebene.jpg',
  'black_and_white_sportsbar.jpg',
  'the_fifty_five.png',
  'yaounde_roundabout_ilovemycountrycameroon.jpg',
  'sindz_palace_hotel.jpg',
];

// Builds the hero background slideshow from the curated list above. Doesn't
// need to wait on the /destinations fetch below since it isn't drawing from
// live data - runs immediately so the hero doesn't sit empty during that
// round trip.
function buildHeroSlideshow() {
  const heroEl = document.getElementById('hero-slideshow');
  if (!heroEl) return;
  shuffled(CURATED_HERO_IMAGES).forEach((filename, i) => {
    const slide = document.createElement('div');
    slide.className = i === 0 ? 'hero-bg-slide is-active' : 'hero-bg-slide';
    slide.style.backgroundImage = `url('/static/destinations/${filename}')`;
    heroEl.appendChild(slide);
  });
  initHeroSlideshow();
}
buildHeroSlideshow();

// Live destination count, pulled straight from the API so the number
// never goes stale relative to what's actually in the app. Animated once
// the real value is known, rather than racing the generic observer above
// with a placeholder target.
fetch('/destinations')
  .then((res) => (res.ok ? res.json() : Promise.reject(res.status)))
  .then((data) => {
    const el = document.getElementById('stat-destinations');
    if (!el) return;
    const count = Array.isArray(data) ? data.length : null;
    if (count === null) {
      el.textContent = '—';
      return;
    }
    el.dataset.countTo = String(count);
    animateCountUp(el);
  })
  .catch(() => {
    // Leave the placeholder dash in place if the API isn't reachable.
  });

// Grey out / label download buttons whose files haven't been uploaded
// yet, instead of leaving dead links for visitors to click.
async function checkAvailability(link) {
  const url = link.getAttribute('href');
  try {
    const res = await fetch(url, { method: 'HEAD' });
    if (res.ok) return;
  } catch (err) {
    // fall through to "unavailable" below
  }
  link.dataset.unavailable = 'true';
  const badge = document.createElement('span');
  badge.className = 'badge';
  // data-i18n (not a one-off textContent set) so this badge keeps up if the
  // visitor switches language after it's already been inserted.
  badge.dataset.i18n = 'comingSoon';
  badge.textContent = window.tripIoI18n ? window.tripIoI18n.t('comingSoon') : 'Coming soon';
  link.appendChild(badge);
}

document.querySelectorAll('[data-download]').forEach(checkAvailability);

// The header's quick "Launch web app" link mirrors the download card's
// availability check, so it doesn't send visitors to a blank page either.
const heroWebLink = document.getElementById('hero-web-link');
if (heroWebLink) {
  checkAvailability(heroWebLink);
}

// Mobile nav menu: the nav-links row is hidden below 720px (see style.css),
// so this toggle is the only way to reach any nav link - including Stats -
// on a phone.
const navToggle = document.getElementById('nav-toggle');
const navLinks = document.getElementById('nav-links');
if (navToggle && navLinks) {
  navToggle.addEventListener('click', () => {
    const isOpen = navLinks.classList.toggle('is-open');
    navToggle.setAttribute('aria-expanded', String(isOpen));
  });
  // Tapping a link should close the menu too, not leave it open behind
  // whatever section/page it just navigated to.
  navLinks.querySelectorAll('a').forEach((link) => {
    link.addEventListener('click', () => {
      navLinks.classList.remove('is-open');
      navToggle.setAttribute('aria-expanded', 'false');
    });
  });
}
