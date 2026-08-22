document.getElementById('year').textContent = new Date().getFullYear();

if (window.AOS) {
  AOS.init({ duration: 700, once: true, offset: 60, easing: 'ease-out-cubic' });
}

// Ambient star field: small glowing dots in the brand palette, drifting
// slowly and scattering away from the pointer as it gets close - an
// "anti-gravity" feel layered above .ambient-blobs. No-ops on pages
// without the #star-field canvas (only index.html has one). Respects
// prefers-reduced-motion the same way the hero slideshow does - a single
// static frame, no drift, no pointer reaction.
function initStarField() {
  const canvas = document.getElementById('star-field');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const reduceMotion =
    window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const PALETTE = ['#ffffff', '#14b8c4', '#1e88e5', '#f2a93b', '#ffc670', '#0a7e8c'];
  const POINTER_RADIUS = 160;
  // Idle cruise speed (px/sec) - always moving, not just an initial
  // velocity that friction decays toward a near-stop.
  const BASE_SPEED_MIN = 18;
  const BASE_SPEED_MAX = 42;
  // Speed a star eases toward the closer the pointer gets to it.
  const BOOST_SPEED_MIN = 70;
  const BOOST_SPEED_MAX = 160;
  const WANDER_TURN = 1.4; // max heading change per second while idle, radians
  const SPEED_EASE = 4; // how fast current speed chases its target, per second

  let width = 0;
  let height = 0;
  let dpr = 1;
  let stars = [];
  let rafId = null;
  let lastTime = 0;
  const pointer = { x: -9999, y: -9999, active: false };

  function starCount() {
    const area = width * height;
    return Math.max(100, Math.min(220, Math.round(area / 6000)));
  }

  function lerpAngle(a, b, t) {
    const twoPi = Math.PI * 2;
    let diff = (b - a) % twoPi;
    if (diff > Math.PI) diff -= twoPi;
    if (diff < -Math.PI) diff += twoPi;
    return a + diff * t;
  }

  function makeStar() {
    return {
      x: Math.random() * width,
      y: Math.random() * height,
      r: 0.8 + Math.random() * 1.8,
      color: PALETTE[Math.floor(Math.random() * PALETTE.length)],
      angle: Math.random() * Math.PI * 2,
      speed: 0,
      baseSpeed: BASE_SPEED_MIN + Math.random() * (BASE_SPEED_MAX - BASE_SPEED_MIN),
      boostSpeed: BOOST_SPEED_MIN + Math.random() * (BOOST_SPEED_MAX - BOOST_SPEED_MIN),
      twinklePhase: Math.random() * Math.PI * 2,
      twinkleSpeed: 0.6 + Math.random() * 1.2,
      baseAlpha: 0.45 + Math.random() * 0.5,
    };
  }

  function resize() {
    width = window.innerWidth;
    height = window.innerHeight;
    dpr = Math.max(1, Math.min(window.devicePixelRatio || 1, 2));
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    canvas.style.width = width + 'px';
    canvas.style.height = height + 'px';
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    const target = starCount();
    if (stars.length < target) {
      while (stars.length < target) stars.push(makeStar());
    } else {
      stars.length = target;
    }
  }

  function step(now) {
    const dt = lastTime ? Math.min((now - lastTime) / 1000, 0.05) : 0;
    lastTime = now;
    ctx.clearRect(0, 0, width, height);

    for (const s of stars) {
      // Idle wander - the heading drifts randomly over time instead of
      // holding a dead-straight line, which reads as mechanical.
      s.angle += (Math.random() - 0.5) * WANDER_TURN * dt;

      let targetSpeed = s.baseSpeed;
      if (pointer.active) {
        const dx = s.x - pointer.x;
        const dy = s.y - pointer.y;
        const distSq = dx * dx + dy * dy;
        if (distSq < POINTER_RADIUS * POINTER_RADIUS) {
          const dist = Math.sqrt(distSq) || 1;
          const proximity = 1 - dist / POINTER_RADIUS; // 0 at the edge, 1 at the cursor
          // Steer away from the pointer, blended in by proximity so it's a
          // smooth scatter rather than a snap to a new heading.
          s.angle = lerpAngle(s.angle, Math.atan2(dy, dx), proximity * 0.9);
          targetSpeed = s.baseSpeed + (s.boostSpeed - s.baseSpeed) * proximity;
        }
      }
      // Ease current speed toward its target instead of jumping straight
      // to it, so the speed-up/settle-down both read as motion, not a cut.
      s.speed += (targetSpeed - s.speed) * Math.min(1, SPEED_EASE * dt);

      s.x += Math.cos(s.angle) * s.speed * dt;
      s.y += Math.sin(s.angle) * s.speed * dt;

      // Wrap at the edges with a small margin so nothing visibly pops.
      const margin = 20;
      if (s.x < -margin) s.x = width + margin;
      if (s.x > width + margin) s.x = -margin;
      if (s.y < -margin) s.y = height + margin;
      if (s.y > height + margin) s.y = -margin;

      s.twinklePhase += s.twinkleSpeed * dt;
      const twinkle = 0.65 + 0.35 * Math.sin(s.twinklePhase);

      ctx.beginPath();
      ctx.fillStyle = s.color;
      ctx.globalAlpha = s.baseAlpha * twinkle;
      ctx.shadowColor = s.color;
      ctx.shadowBlur = s.r * 3;
      ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
    ctx.shadowBlur = 0;

    if (!reduceMotion) rafId = requestAnimationFrame(step);
  }

  resize();
  window.addEventListener('resize', resize);

  if (reduceMotion) {
    step(0);
    return;
  }

  window.addEventListener('pointermove', (e) => {
    pointer.x = e.clientX;
    pointer.y = e.clientY;
    pointer.active = true;
  });
  window.addEventListener('pointerleave', () => {
    pointer.active = false;
  });
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      if (rafId) cancelAnimationFrame(rafId);
      rafId = null;
      lastTime = 0;
    } else if (!rafId) {
      rafId = requestAnimationFrame(step);
    }
  });

  rafId = requestAnimationFrame(step);
}
initStarField();

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
  'majestic.jpg',
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
