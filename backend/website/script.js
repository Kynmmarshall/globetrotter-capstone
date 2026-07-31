document.getElementById('year').textContent = new Date().getFullYear();

if (window.AOS) {
  AOS.init({ duration: 700, once: true, offset: 60, easing: 'ease-out-cubic' });
}

// Hero background slideshow: cycles through real Yaoundé destination photos
// (rather than one static hero image forever), picking both the next image
// and its entrance animation at random each time so the rotation doesn't
// just repeat the same fade - see the .anim-* keyframes in style.css.
(function initHeroSlideshow() {
  const slides = document.querySelectorAll('.hero-bg-slide');
  if (slides.length < 2) return;
  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  const animations = ['anim-zoom', 'anim-slide-left', 'anim-slide-right', 'anim-blur', 'anim-rotate', 'anim-drop', 'anim-flip'];
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
})();

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
