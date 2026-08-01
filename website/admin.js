// Admin dashboard for the trip_io catalog. Talks to the same backend the
// app does; every /admin/* endpoint is gated server-side by require_admin,
// so hiding UI here is convenience, not the actual security boundary.
(function () {
  const TOKEN_KEY = 'trip_io_admin_token';

  const el = (id) => document.getElementById(id);
  const yearEl = el('year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  let token = localStorage.getItem(TOKEN_KEY);
  let currentStatus = 'pending';
  let editingId = null; // null while creating a brand-new destination

  // ---------- location picker map (editor dialog) ----------

  const YAOUNDE_CENTER = [11.5021, 3.8480]; // MapLibre wants [lng, lat]
  let locationMap = null;
  let locationMarker = null;

  function ensureLocationMap() {
    if (locationMap) return locationMap;
    locationMap = new maplibregl.Map({
      container: 'location-map',
      style: 'https://tiles.openfreemap.org/styles/liberty',
      center: YAOUNDE_CENTER,
      zoom: 11,
    });
    locationMap.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right');
    // Clicking the map is the primary way to set a point - the lat/lon text
    // inputs stay editable too, for precision or pasting known coordinates.
    locationMap.on('click', (e) => {
      el('f-lat').value = e.lngLat.lat.toFixed(6);
      el('f-lon').value = e.lngLat.lng.toFixed(6);
      placeMarker(e.lngLat.lat, e.lngLat.lng);
    });
    return locationMap;
  }

  function placeMarker(lat, lon) {
    const map = ensureLocationMap();
    if (locationMarker) {
      locationMarker.setLngLat([lon, lat]);
    } else {
      locationMarker = new maplibregl.Marker({ color: '#0A7E8C', draggable: true })
        .setLngLat([lon, lat])
        .addTo(map);
      locationMarker.on('dragend', () => {
        const pos = locationMarker.getLngLat();
        el('f-lat').value = pos.lat.toFixed(6);
        el('f-lon').value = pos.lng.toFixed(6);
      });
    }
  }

  function clearMarker() {
    if (locationMarker) {
      locationMarker.remove();
      locationMarker = null;
    }
  }

  // Keeps the marker in sync if an admin types/pastes coordinates directly
  // instead of clicking the map.
  function syncMarkerFromFields() {
    const latRaw = el('f-lat').value.trim();
    const lonRaw = el('f-lon').value.trim();
    const lat = Number(latRaw);
    const lon = Number(lonRaw);
    if (latRaw && lonRaw && Number.isFinite(lat) && Number.isFinite(lon)) {
      placeMarker(lat, lon);
    } else {
      clearMarker();
    }
  }

  function goToMyLocation() {
    if (!navigator.geolocation) {
      showError(el('edit-error'), 'Geolocation is not available in this browser.');
      return;
    }
    const btn = el('locate-btn');
    btn.classList.add('is-busy');
    navigator.geolocation.getCurrentPosition(
      (position) => {
        btn.classList.remove('is-busy');
        const { latitude, longitude } = position.coords;
        el('f-lat').value = latitude.toFixed(6);
        el('f-lon').value = longitude.toFixed(6);
        placeMarker(latitude, longitude);
        const map = ensureLocationMap();
        map.flyTo({ center: [longitude, latitude], zoom: 14 });
      },
      (err) => {
        btn.classList.remove('is-busy');
        showError(el('edit-error'), `Could not get your location: ${err.message}`);
      },
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  // ---------- image picker (editor dialog) ----------

  let pendingImageFile = null; // a newly chosen file awaiting upload on save

  function setImagePreview(url) {
    const img = el('f-image-preview');
    if (url) {
      img.src = url;
      img.hidden = false;
    } else {
      img.src = '';
      img.hidden = true;
    }
  }

  function showError(node, message) {
    node.textContent = message;
    node.hidden = !message;
  }

  async function api(path, options = {}) {
    // FormData (image uploads) must NOT get a manual Content-Type - the
    // browser sets its own multipart boundary, which we'd otherwise clobber.
    const isFormData = options.body instanceof FormData;
    const res = await fetch(path, {
      ...options,
      headers: {
        ...(isFormData ? {} : { 'Content-Type': 'application/json' }),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(options.headers || {}),
      },
    });
    if (res.status === 401 || res.status === 403) {
      // Either the token expired or this account isn't an admin - either
      // way the only useful next step is signing in again.
      signOut();
      throw new Error('Your session is not valid for admin access.');
    }
    if (!res.ok) {
      let detail = `Request failed (${res.status})`;
      try {
        const body = await res.json();
        if (body.detail) detail = body.detail;
      } catch (_) {
        // keep the status-code message
      }
      throw new Error(detail);
    }
    return res.status === 204 ? null : res.json();
  }

  function signOut() {
    token = null;
    localStorage.removeItem(TOKEN_KEY);
    el('dashboard').hidden = true;
    el('login-section').hidden = false;
    el('logout-btn').hidden = true;
  }

  async function signIn(username, password) {
    const res = await fetch('/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    });
    if (!res.ok) throw new Error('Invalid username or password.');
    const body = await res.json();
    token = body.access_token;

    // Confirm the account is actually an admin before showing the
    // dashboard, so a normal user gets a clear message instead of an
    // empty screen full of failing requests.
    const me = await api('/me');
    if (me.role !== 'admin') {
      token = null;
      throw new Error('That account does not have admin access.');
    }
    localStorage.setItem(TOKEN_KEY, token);
  }

  function enterDashboard() {
    el('login-section').hidden = true;
    el('dashboard').hidden = false;
    el('logout-btn').hidden = false;
    refresh();
  }

  function statusBadge(status) {
    const cls = { pending: 'is-pending', approved: 'is-approved', rejected: 'is-rejected' }[status] || '';
    return `<span class="admin-badge ${cls}">${status}</span>`;
  }

  function card(dest) {
    const status = dest.status || 'approved';
    const node = document.createElement('div');
    node.className = 'glass admin-item';

    const thumb = dest.image_url
      ? `<img class="admin-thumb" src="${dest.image_url}" alt="" loading="lazy" />`
      : `<div class="admin-thumb admin-thumb-empty">No image</div>`;

    // textContent-style escaping isn't available for an innerHTML template,
    // so user-supplied fields go through escapeHtml - a submitted name is
    // arbitrary user input and must never be treated as markup.
    node.innerHTML = `
      ${thumb}
      <div class="admin-item-body">
        <div class="admin-item-head">
          <h3>${escapeHtml(dest.name || '(untitled)')}</h3>
          ${statusBadge(status)}
        </div>
        <p class="admin-item-meta">${escapeHtml(dest.id)}${dest.submitted_by ? ` &middot; submitted by ${escapeHtml(dest.submitted_by)}` : ''}${dest.rating_count ? ` &middot; ★ ${dest.rating_average} (${dest.rating_count})` : ''}</p>
        ${dest.location ? `<p class="admin-item-meta">${escapeHtml(dest.location)}</p>` : ''}
        ${dest.description ? `<p class="admin-item-desc">${escapeHtml(dest.description)}</p>` : ''}
        <div class="admin-item-actions"></div>
      </div>
    `;

    const actions = node.querySelector('.admin-item-actions');
    if (status !== 'approved') {
      actions.appendChild(button('Approve', 'btn-primary', () => setStatus(dest.id, 'approved')));
    }
    if (status !== 'rejected') {
      actions.appendChild(button('Reject', 'btn-ghost', () => setStatus(dest.id, 'rejected')));
    }
    actions.appendChild(button('Edit', 'btn-ghost', () => openEditor(dest)));
    actions.appendChild(button('Delete', 'btn-ghost admin-danger', () => remove(dest)));
    return node;
  }

  function button(label, cls, onClick) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = `btn ${cls}`;
    b.textContent = label;
    b.addEventListener('click', onClick);
    return b;
  }

  function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, (c) => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
    }[c]));
  }

  async function refresh() {
    showError(el('dash-error'), '');
    const list = el('dest-list');
    list.innerHTML = '';
    try {
      const all = await api('/admin/destinations');
      const counts = { pending: 0, approved: 0, rejected: 0 };
      all.forEach((d) => {
        const s = d.status || 'approved';
        if (counts[s] !== undefined) counts[s] += 1;
      });
      el('count-pending').textContent = counts.pending;
      el('count-approved').textContent = counts.approved;
      el('count-rejected').textContent = counts.rejected;

      const shown = all.filter((d) => (d.status || 'approved') === currentStatus);
      el('dest-empty').hidden = shown.length > 0;
      shown.forEach((d) => list.appendChild(card(d)));
    } catch (err) {
      showError(el('dash-error'), err.message);
    }
  }

  async function setStatus(id, status) {
    try {
      await api(`/admin/destinations/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      });
      refresh();
    } catch (err) {
      showError(el('dash-error'), err.message);
    }
  }

  async function remove(dest) {
    const ok = window.confirm(
      `Delete "${dest.name}" permanently?\n\nThis also removes its ratings, comments and any users' saved favorites for it. This cannot be undone.`
    );
    if (!ok) return;
    try {
      await api(`/admin/destinations/${dest.id}`, { method: 'DELETE' });
      refresh();
    } catch (err) {
      showError(el('dash-error'), err.message);
    }
  }

  function openEditor(dest) {
    editingId = dest ? dest.id : null;
    el('edit-title').textContent = dest ? 'Edit destination' : 'New destination';
    el('f-name').value = dest?.name || '';
    el('f-description').value = dest?.description || '';
    el('f-location').value = dest?.location || '';
    el('f-lat').value = dest?.lat ?? '';
    el('f-lon').value = dest?.lon ?? '';
    el('f-tags').value = (dest?.tags || []).join(', ');
    pendingImageFile = null;
    el('f-image-file').value = '';
    setImagePreview(dest?.image_url || null);
    el('f-hours').value = dest?.opening_hours || '';
    el('f-fee').value = dest?.entry_fee || '';
    el('f-tips').value = dest?.tips || '';
    showError(el('edit-error'), '');
    el('edit-dialog').showModal();

    const map = ensureLocationMap();
    const hasPoint = typeof dest?.lat === 'number' && typeof dest?.lon === 'number';
    clearMarker();
    if (hasPoint) {
      placeMarker(dest.lat, dest.lon);
      map.setCenter([dest.lon, dest.lat]);
      map.setZoom(13);
    } else {
      map.setCenter(YAOUNDE_CENTER);
      map.setZoom(11);
    }
    // The map's container has zero size until the <dialog> is actually
    // shown, so MapLibre needs a nudge to recompute its canvas size once it
    // is - a same-tick resize() call sees the old (zero) layout.
    setTimeout(() => map.resize(), 50);
  }

  function parseOptionalFloat(rawValue, fieldLabel) {
    const trimmed = rawValue.trim();
    if (!trimmed) return { value: null, error: null };
    const parsed = Number(trimmed);
    if (!Number.isFinite(parsed)) {
      return { value: null, error: `${fieldLabel} must be a number.` };
    }
    return { value: parsed, error: null };
  }

  async function saveEditor() {
    const name = el('f-name').value.trim();
    if (!name) {
      showError(el('edit-error'), 'Name is required.');
      return;
    }
    const lat = parseOptionalFloat(el('f-lat').value, 'Latitude');
    const lon = parseOptionalFloat(el('f-lon').value, 'Longitude');
    if (lat.error || lon.error) {
      showError(el('edit-error'), lat.error || lon.error);
      return;
    }
    const payload = {
      name,
      description: el('f-description').value.trim() || null,
      location: el('f-location').value.trim() || null,
      lat: lat.value,
      lon: lon.value,
      tags: el('f-tags').value.split(',').map((t) => t.trim()).filter(Boolean),
      opening_hours: el('f-hours').value.trim() || null,
      entry_fee: el('f-fee').value.trim() || null,
      tips: el('f-tips').value.trim() || null,
    };
    try {
      const saved = editingId
        ? await api(`/admin/destinations/${editingId}`, {
            method: 'PATCH',
            body: JSON.stringify(payload),
          })
        : await api('/admin/destinations', {
            method: 'POST',
            body: JSON.stringify(payload),
          });

      // The image URL is server-generated (from the destination's name) -
      // this only ever runs once the destination itself (and so its id)
      // definitely exists, whether that's from an edit or a brand-new one.
      if (pendingImageFile) {
        const formData = new FormData();
        formData.append('file', pendingImageFile);
        await api(`/destinations/${saved.id}/image`, {
          method: 'POST',
          body: formData,
        });
      }

      el('edit-dialog').close();
      refresh();
    } catch (err) {
      showError(el('edit-error'), err.message);
    }
  }

  // ---------- wiring ----------

  el('login-form').addEventListener('submit', async (event) => {
    event.preventDefault();
    showError(el('login-error'), '');
    try {
      await signIn(el('login-username').value.trim(), el('login-password').value);
      el('login-password').value = '';
      enterDashboard();
    } catch (err) {
      showError(el('login-error'), err.message);
    }
  });

  el('logout-btn').addEventListener('click', signOut);
  el('new-btn').addEventListener('click', () => openEditor(null));
  el('edit-save').addEventListener('click', saveEditor);
  el('edit-cancel').addEventListener('click', () => el('edit-dialog').close());
  el('f-lat').addEventListener('change', syncMarkerFromFields);
  el('f-lon').addEventListener('change', syncMarkerFromFields);
  el('locate-btn').addEventListener('click', goToMyLocation);
  el('f-image-file').addEventListener('change', () => {
    const file = el('f-image-file').files[0] || null;
    pendingImageFile = file;
    if (file) setImagePreview(URL.createObjectURL(file));
  });

  document.querySelectorAll('.admin-tab').forEach((tab) => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.admin-tab').forEach((t) => t.classList.remove('is-active'));
      tab.classList.add('is-active');
      currentStatus = tab.dataset.status;
      refresh();
    });
  });

  // Resume a previous session if the stored token is still valid.
  if (token) {
    api('/me')
      .then((me) => {
        if (me.role === 'admin') enterDashboard();
        else signOut();
      })
      .catch(() => signOut());
  }
})();
