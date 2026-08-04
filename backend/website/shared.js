function t(key, vars) {
  return window.tripIoI18n ? window.tripIoI18n.t(key, vars) : key;
}

function stopCard(destination) {
  const card = document.createElement('div');
  card.className = 'shared-stop-card glass';

  if (destination.image_url) {
    const img = document.createElement('img');
    img.src = destination.image_url;
    img.alt = destination.name;
    img.loading = 'lazy';
    card.appendChild(img);
  }

  const body = document.createElement('div');
  body.className = 'shared-stop-body';

  const name = document.createElement('h3');
  name.textContent = destination.name;
  body.appendChild(name);

  if (destination.location) {
    const location = document.createElement('p');
    location.className = 'shared-stop-location';
    location.textContent = destination.location;
    body.appendChild(location);
  }

  card.appendChild(body);
  return card;
}

async function loadSharedItinerary() {
  const params = new URLSearchParams(window.location.search);
  const token = params.get('token');
  const titleEl = document.getElementById('shared-title');
  const subEl = document.getElementById('shared-sub');
  const stopsEl = document.getElementById('shared-stops');
  const errorEl = document.getElementById('shared-error');

  if (!token) {
    titleEl.textContent = 'trip_io';
    errorEl.textContent = t('sharedLoadError');
    errorEl.hidden = false;
    return;
  }

  try {
    const res = await fetch(`/shared/itineraries/${encodeURIComponent(token)}`, {
      cache: 'no-store',
    });
    if (!res.ok) throw new Error(String(res.status));
    const itinerary = await res.json();

    document.title = `${itinerary.title} — trip_io`;
    titleEl.textContent = itinerary.title;

    const destinations = Array.isArray(itinerary.destinations) ? itinerary.destinations : [];
    subEl.textContent = t('sharedStopsSummary', { count: String(destinations.length) });

    if (destinations.length === 0) {
      const empty = document.createElement('p');
      empty.className = 'shared-empty';
      empty.textContent = t('sharedEmpty');
      stopsEl.appendChild(empty);
      return;
    }

    destinations.forEach((destination) => {
      stopsEl.appendChild(stopCard(destination));
    });
  } catch (err) {
    titleEl.textContent = 'trip_io';
    errorEl.textContent = t('sharedLoadError');
    errorEl.hidden = false;
  }
}

document.addEventListener('DOMContentLoaded', loadSharedItinerary);
