document.getElementById('year').textContent = new Date().getFullYear();

// Live destination count, pulled straight from the API so the number
// never goes stale relative to what's actually in the app.
fetch('/destinations')
  .then((res) => (res.ok ? res.json() : Promise.reject(res.status)))
  .then((data) => {
    const el = document.getElementById('stat-destinations');
    if (el) el.textContent = Array.isArray(data) ? data.length : '—';
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
  badge.textContent = 'Coming soon';
  link.appendChild(badge);
}

document.querySelectorAll('[data-download]').forEach(checkAvailability);

// The header's quick "Launch web app" link mirrors the download card's
// availability check, so it doesn't send visitors to a blank page either.
const heroWebLink = document.getElementById('hero-web-link');
if (heroWebLink) {
  checkAvailability(heroWebLink);
}

// Simple fade-in-on-scroll for section content.
const revealTargets = document.querySelectorAll('.reveal');
if ('IntersectionObserver' in window && revealTargets.length) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in-view');
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15 }
  );
  revealTargets.forEach((el) => observer.observe(el));
} else {
  revealTargets.forEach((el) => el.classList.add('in-view'));
}
