const SVG_NS = 'http://www.w3.org/2000/svg';

function el(tag, attrs) {
  const node = document.createElementNS(SVG_NS, tag);
  for (const key in attrs) node.setAttribute(key, attrs[key]);
  return node;
}

// Rounds a max value up to a "nice" tick step (1/2/5 * 10^n), never a fixed
// increment that would produce ugly gridline values like 7 or 13.
function niceStep(maxValue, tickCount) {
  if (maxValue <= 0) return 1;
  const roughStep = maxValue / tickCount;
  const magnitude = Math.pow(10, Math.floor(Math.log10(roughStep)));
  const residual = roughStep / magnitude;
  let niceResidual;
  if (residual > 5) niceResidual = 10;
  else if (residual > 2) niceResidual = 5;
  else if (residual > 1) niceResidual = 2;
  else niceResidual = 1;
  return niceResidual * magnitude;
}

function formatDate(iso) {
  const d = new Date(iso + 'T00:00:00');
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function showEmpty(wrap, message) {
  wrap.innerHTML = '';
  const div = document.createElement('div');
  div.className = 'chart-empty';
  div.textContent = message;
  wrap.appendChild(div);
}

function makeTooltip(wrap) {
  const tip = document.createElement('div');
  tip.className = 'chart-tooltip';
  wrap.appendChild(tip);
  return tip;
}

function positionTooltip(tip, wrap, svg, svgX, svgY, viewBox) {
  const wrapRect = wrap.getBoundingClientRect();
  const svgRect = svg.getBoundingClientRect();
  const scaleX = svgRect.width / viewBox[2];
  const scaleY = svgRect.height / viewBox[3];
  const left = svgRect.left - wrapRect.left + svgX * scaleX;
  const top = svgRect.top - wrapRect.top + svgY * scaleY;
  tip.style.left = `${left}px`;
  tip.style.top = `${top}px`;
}

// ---------- Line chart: daily active users ----------

function renderLineChart(wrap, tableBody, series) {
  if (!series.length) {
    showEmpty(wrap, 'Not enough data yet — check back once the app has some real usage.');
    return;
  }

  series.forEach((point) => {
    const row = document.createElement('tr');
    const dateCell = document.createElement('td');
    dateCell.textContent = formatDate(point.date);
    const countCell = document.createElement('td');
    countCell.textContent = String(point.count);
    row.append(dateCell, countCell);
    tableBody.appendChild(row);
  });

  const width = 640;
  const height = 220;
  const marginLeft = 34;
  const marginRight = 12;
  const marginTop = 16;
  const marginBottom = 28;
  const plotWidth = width - marginLeft - marginRight;
  const plotHeight = height - marginTop - marginBottom;

  const maxCount = Math.max(...series.map((p) => p.count));
  const step = niceStep(maxCount, 4);
  const niceMax = Math.max(step, Math.ceil((maxCount || 1) / step) * step);

  const xAt = (i) =>
    marginLeft + (series.length === 1 ? plotWidth / 2 : (i / (series.length - 1)) * plotWidth);
  const yAt = (v) => marginTop + plotHeight - (v / niceMax) * plotHeight;

  const svg = el('svg', { viewBox: `0 0 ${width} ${height}`, role: 'img', 'aria-label': 'Daily active users, last 14 days' });

  // Gridlines + y-axis labels (nice ticks only, recessive).
  const gridGroup = el('g', { class: 'chart-grid' });
  for (let v = 0; v <= niceMax; v += step) {
    const y = yAt(v);
    gridGroup.appendChild(el('line', { x1: marginLeft, x2: width - marginRight, y1: y, y2: y }));
    const label = el('text', { class: 'chart-axis-label', x: marginLeft - 8, y: y + 3, 'text-anchor': 'end' });
    label.textContent = String(v);
    svg.appendChild(label);
  }
  svg.appendChild(gridGroup);

  // Area fill under the line.
  const areaPoints = series.map((p, i) => `${xAt(i)},${yAt(p.count)}`).join(' L ');
  const areaPath = `M ${xAt(0)},${yAt(0)} L ${areaPoints} L ${xAt(series.length - 1)},${yAt(0)} Z`;
  svg.appendChild(el('path', { class: 'chart-area', d: areaPath }));

  // The line itself.
  const linePath = `M ${series.map((p, i) => `${xAt(i)},${yAt(p.count)}`).join(' L ')}`;
  svg.appendChild(el('path', { class: 'chart-line', d: linePath }));

  // Sparse x-axis labels: first, middle, last only.
  const labelIdxs = new Set([0, Math.floor((series.length - 1) / 2), series.length - 1]);
  labelIdxs.forEach((i) => {
    const label = el('text', { class: 'chart-axis-label', x: xAt(i), y: height - 6, 'text-anchor': 'middle' });
    label.textContent = formatDate(series[i].date);
    svg.appendChild(label);
  });

  // End-dot with a surface-color ring, per the mark spec.
  const lastIdx = series.length - 1;
  svg.appendChild(
    el('circle', { class: 'chart-dot', cx: xAt(lastIdx), cy: yAt(series[lastIdx].count), r: 5 })
  );

  // Crosshair (hidden until hover) + one wide hit rect that tracks the
  // nearest point, per the "crosshair finds the X" interaction rule.
  const crosshair = el('line', {
    class: 'chart-crosshair',
    x1: xAt(0), x2: xAt(0), y1: marginTop, y2: height - marginBottom,
    style: 'opacity:0',
  });
  svg.appendChild(crosshair);
  const hoverDot = el('circle', { class: 'chart-dot', r: 5, style: 'opacity:0' });
  svg.appendChild(hoverDot);

  const hit = el('rect', {
    class: 'chart-hit', x: marginLeft, y: marginTop, width: plotWidth, height: plotHeight,
  });
  svg.appendChild(hit);

  wrap.innerHTML = '';
  wrap.appendChild(svg);
  const tooltip = makeTooltip(wrap);
  const viewBox = [0, 0, width, height];

  function onMove(evt) {
    const svgRect = svg.getBoundingClientRect();
    const relX = ((evt.clientX - svgRect.left) / svgRect.width) * width;
    let nearest = 0;
    let nearestDist = Infinity;
    series.forEach((_, i) => {
      const d = Math.abs(xAt(i) - relX);
      if (d < nearestDist) {
        nearestDist = d;
        nearest = i;
      }
    });
    const point = series[nearest];
    crosshair.setAttribute('x1', xAt(nearest));
    crosshair.setAttribute('x2', xAt(nearest));
    crosshair.style.opacity = '1';
    hoverDot.setAttribute('cx', xAt(nearest));
    hoverDot.setAttribute('cy', yAt(point.count));
    hoverDot.style.opacity = '1';

    tooltip.innerHTML = '';
    const valueSpan = document.createElement('span');
    valueSpan.className = 'tt-value';
    valueSpan.textContent = String(point.count);
    const labelSpan = document.createElement('span');
    labelSpan.className = 'tt-label';
    labelSpan.textContent = formatDate(point.date);
    tooltip.append(valueSpan, labelSpan);
    tooltip.classList.add('is-visible');
    positionTooltip(tooltip, wrap, svg, xAt(nearest), yAt(point.count), viewBox);
  }

  function onLeave() {
    crosshair.style.opacity = '0';
    hoverDot.style.opacity = '0';
    tooltip.classList.remove('is-visible');
  }

  hit.addEventListener('pointermove', onMove);
  hit.addEventListener('pointerleave', onLeave);
}

// ---------- Bar chart: most-visited sections ----------

function renderBarChart(wrap, tableBody, rows) {
  if (!rows.length) {
    showEmpty(wrap, 'Not enough data yet — check back once the app has some real usage.');
    return;
  }

  rows.forEach((row) => {
    const tr = document.createElement('tr');
    const nameCell = document.createElement('td');
    nameCell.textContent = row.name;
    const countCell = document.createElement('td');
    countCell.textContent = String(row.count);
    tr.append(nameCell, countCell);
    tableBody.appendChild(tr);
  });

  const width = 640;
  const barThickness = 20;
  const gap = 10;
  const rowHeight = barThickness + gap;
  const marginLeft = 120;
  const marginRight = 46;
  const marginTop = 6;
  const height = marginTop + rows.length * rowHeight;
  const plotWidth = width - marginLeft - marginRight;
  const maxCount = Math.max(...rows.map((r) => r.count), 1);

  const svg = el('svg', { viewBox: `0 0 ${width} ${height}`, role: 'img', 'aria-label': 'Most-visited sections this week' });
  const tooltip = makeTooltip(wrap);
  const viewBox = [0, 0, width, height];

  rows.forEach((row, i) => {
    const y = marginTop + i * rowHeight;
    const barLen = Math.max((row.count / maxCount) * plotWidth, 2);
    const r = Math.min(4, barThickness / 2, barLen);
    const x0 = marginLeft;
    const x1 = marginLeft + barLen;

    const path =
      `M ${x0},${y} ` +
      `L ${x1 - r},${y} ` +
      `A ${r},${r} 0 0 1 ${x1},${y + r} ` +
      `L ${x1},${y + barThickness - r} ` +
      `A ${r},${r} 0 0 1 ${x1 - r},${y + barThickness} ` +
      `L ${x0},${y + barThickness} Z`;

    const bar = el('path', { class: 'chart-bar', d: path });
    svg.appendChild(bar);

    const nameLabel = el('text', {
      class: 'chart-bar-label', x: marginLeft - 10, y: y + barThickness / 2 + 4, 'text-anchor': 'end',
    });
    nameLabel.textContent = row.name;
    svg.appendChild(nameLabel);

    // Value at the bar's tip when it fits; otherwise it's tooltip-only, per
    // "a value pushed off its mark lives in the tooltip".
    const fitsInline = plotWidth - barLen > 28;
    if (fitsInline) {
      const valueLabel = el('text', {
        class: 'chart-bar-value', x: x1 + 8, y: y + barThickness / 2 + 4,
      });
      valueLabel.textContent = String(row.count);
      svg.appendChild(valueLabel);
    }

    const hitHeight = barThickness + gap;
    const hit = el('rect', {
      class: 'chart-hit', x: marginLeft, y: y - gap / 2, width: plotWidth + marginRight, height: hitHeight,
    });
    hit.addEventListener('pointerenter', () => {
      bar.classList.add('is-active');
      tooltip.innerHTML = '';
      const valueSpan = document.createElement('span');
      valueSpan.className = 'tt-value';
      valueSpan.textContent = String(row.count);
      const labelSpan = document.createElement('span');
      labelSpan.className = 'tt-label';
      labelSpan.textContent = row.name;
      tooltip.append(valueSpan, labelSpan);
      tooltip.classList.add('is-visible');
      positionTooltip(tooltip, wrap, svg, x1, y + barThickness / 2, viewBox);
    });
    hit.addEventListener('pointerleave', () => {
      bar.classList.remove('is-active');
      tooltip.classList.remove('is-visible');
    });
    svg.appendChild(hit);
  });

  wrap.innerHTML = '';
  wrap.appendChild(svg);
  wrap.appendChild(tooltip);
}

// ---------- Fetch + wire up ----------

const AUTO_REFRESH_MS = 60 * 1000;

function setKpi(id, value) {
  const node = document.getElementById(id);
  if (node) node.textContent = value === null || value === undefined ? '—' : String(value);
}

function setUpdatedAt(date) {
  const node = document.getElementById('updated-at');
  if (!node) return;
  node.textContent = `Updated ${date.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })}`;
}

async function loadStats() {
  const refreshBtn = document.getElementById('refresh-btn');
  if (refreshBtn) {
    refreshBtn.classList.add('is-loading');
    refreshBtn.disabled = true;
  }

  try {
    const res = await fetch('/stats/public', { cache: 'no-store' });
    if (!res.ok) throw res.status;
    const data = await res.json();

    setKpi('kpi-total-users', data.total_users);
    setKpi('kpi-active-today', data.active_today);
    setKpi('kpi-active-week', data.active_this_week);

    const lineWrap = document.getElementById('line-chart-wrap');
    const lineTableBody = document.querySelector('#line-chart-table tbody');
    if (lineWrap && lineTableBody) {
      lineTableBody.innerHTML = '';
      renderLineChart(lineWrap, lineTableBody, data.daily_active || []);
    }

    const barWrap = document.getElementById('bar-chart-wrap');
    const barTableBody = document.querySelector('#bar-chart-table tbody');
    if (barWrap && barTableBody) {
      barTableBody.innerHTML = '';
      renderBarChart(barWrap, barTableBody, data.top_sections || []);
    }

    setUpdatedAt(new Date());
  } catch (err) {
    ['kpi-total-users', 'kpi-active-today', 'kpi-active-week'].forEach((id) => setKpi(id, null));
    const lineWrap = document.getElementById('line-chart-wrap');
    const barWrap = document.getElementById('bar-chart-wrap');
    if (lineWrap) showEmpty(lineWrap, 'Could not load stats right now.');
    if (barWrap) showEmpty(barWrap, 'Could not load stats right now.');
  } finally {
    if (refreshBtn) {
      refreshBtn.classList.remove('is-loading');
      refreshBtn.disabled = false;
    }
  }
}

document.getElementById('refresh-btn')?.addEventListener('click', loadStats);

// Auto-refresh while the tab is actually visible - no point polling a
// backgrounded tab, and it avoids piling up requests if someone leaves it
// open for hours.
setInterval(() => {
  if (document.visibilityState === 'visible') loadStats();
}, AUTO_REFRESH_MS);

loadStats();
