/* yourwobb -> Rebrickable CSV exporter.
 *
 * Lookup tables (GDS_TO_RB, LEGO_COLOR_TO_RB, NAME_TO_RB, RB_COLOR_META) come
 * from data.js, generated from brick-lib's conversion tables.
 */

/* ------------------------------------------------------------------ *
 * scrapeCart() runs in the PAGE (MAIN world) via chrome.scripting.
 * It must be fully self-contained: no references to popup-scope vars.
 * It returns { items:[...], meta:{...} } — plain, serializable data.
 * ------------------------------------------------------------------ */
function scrapeCart() {
  const clean = (s) => (s || '').replace(/\s+/g, ' ').trim();
  const lis = Array.from(document.querySelectorAll('.product_info_list li'));

  // The DOM caps the quantity badge at "99+". The page keeps the real numbers
  // in a global cart object (_GET_C_SETTING_('cart').items), in the same order
  // as the <li> rows — so we read exact counts from there when available.
  let cartItems = null;
  try {
    if (typeof _GET_C_SETTING_ === 'function') {
      const c = _GET_C_SETTING_('cart');
      if (c && Array.isArray(c.items)) cartItems = c.items;
    }
  } catch (e) { /* not on a page that exposes it */ }

  const rows = lis.map((li) => {
    const skuEl = li.querySelector('.sku');
    const nameEl = li.querySelector('.product_name');
    const numEl = li.querySelector('.order_product_num');

    // Colour lives in the .order_product_sku whose text begins with "Color".
    let colorText = '';
    li.querySelectorAll('.order_product_sku').forEach((el) => {
      const t = clean(el.textContent);
      if (/^color\s*[:：]/i.test(t)) colorText = t;
    });

    const sku = clean(skuEl ? skuEl.textContent : '');
    const title = clean(nameEl ? nameEl.textContent : (li.querySelector('img') ? li.querySelector('img').alt : ''));

    // Part number: SKU is "GDS-<code>-<colorSuffix>" (e.g. GDS-90531-040,
    // GDS-M255-090). Strip the trailing "-<digits>"; fall back to a GDS token.
    let part = '';
    const m = /^(GDS-[A-Za-z0-9]+)-\d+$/.exec(sku);
    if (m) {
      part = m[1].toUpperCase();
    } else {
      const t = /GDS-[A-Za-z0-9]+/i.exec(sku || title);
      if (t) part = t[0].toUpperCase();
    }

    // Colour text is "Color: <Name> <legoColorId>" (the trailing id is LEGO's).
    let colorName = '';
    let legoColorId = '';
    const cm = /color\s*[:：]\s*(.*?)(?:\s+(\d+))?\s*$/i.exec(colorText);
    if (cm) { colorName = clean(cm[1]); legoColorId = cm[2] || ''; }

    const numTxt = clean(numEl ? numEl.textContent : '');
    const qtyCapped = /\+/.test(numTxt);
    let qty = parseInt(numTxt.replace(/[^\d]/g, ''), 10);
    if (isNaN(qty)) qty = null;

    return { sku, title, part, colorText, colorName, legoColorId, qty, qtyCapped };
  });

  // Recover exact quantities from the cart object. We don't assume the field
  // name — we find the integer property that equals the DOM number on every
  // uncapped row, then trust it for the capped ones too.
  let qtyField = null;
  if (cartItems && cartItems.length === rows.length && rows.length > 0) {
    const sample = cartItems.find((x) => x && typeof x === 'object') || {};
    const candidates = Object.keys(sample).filter((k) =>
      cartItems.every((it) => it && Number.isInteger(it[k]) && it[k] >= 0));
    const preferred = ['quantity', 'qty', 'num', 'nums', 'number', 'buy_number',
      'buynum', 'count', 'amount', 'goods_num', 'sku_num', 'product_num'];
    const ordered = candidates.slice().sort((a, b) => {
      const ia = preferred.indexOf(a.toLowerCase());
      const ib = preferred.indexOf(b.toLowerCase());
      return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
    });
    const uncapped = rows.map((r, i) => ({ r, i })).filter((o) => !o.r.qtyCapped && o.r.qty != null);
    for (const k of ordered) {
      if (uncapped.length === 0) { qtyField = k; break; }
      if (uncapped.every((o) => cartItems[o.i][k] === o.r.qty)) { qtyField = k; break; }
    }
    if (qtyField) {
      rows.forEach((r, i) => {
        const v = cartItems[i][qtyField];
        if (Number.isInteger(v) && v >= 0) { r.qty = v; r.qtyCapped = false; }
      });
    }
  }

  return {
    items: rows,
    meta: {
      url: location.href,
      liCount: lis.length,
      hadCartObject: !!cartItems,
      cartItemCount: cartItems ? cartItems.length : 0,
      qtyField: qtyField,
    },
  };
}

/* ------------------------------------------------------------------ *
 * Conversion (popup scope — uses the data.js tables).
 * ------------------------------------------------------------------ */
function colorToRb(it) {
  if (it.legoColorId && LEGO_COLOR_TO_RB[it.legoColorId]) return LEGO_COLOR_TO_RB[it.legoColorId];
  const n = (it.colorName || '').toLowerCase().trim();
  if (n && NAME_TO_RB[n]) return NAME_TO_RB[n];
  if (n && NAME_TO_RB[n.replace(/-/g, ' ')]) return NAME_TO_RB[n.replace(/-/g, ' ')];
  return '9999';
}

function convert(items) {
  const merged = new Map(); // "part|color" -> row
  const unmappedParts = [];
  const unmappedColors = [];
  const capped = [];

  for (const it of items) {
    if (!it.part) continue;
    const rbPart = GDS_TO_RB[it.part];
    if (!rbPart) { unmappedParts.push(it); continue; }

    const rbColor = colorToRb(it);
    if (rbColor === '9999') unmappedColors.push(it);
    if (it.qtyCapped) capped.push(it);

    const qty = (Number.isInteger(it.qty) && it.qty > 0) ? it.qty : (it.qtyCapped ? 100 : 1);
    const key = rbPart + '|' + rbColor;
    const cur = merged.get(key);
    if (cur) {
      cur.qty += qty;
    } else {
      merged.set(key, {
        part: rbPart, color: rbColor, qty,
        gds: it.part, colorName: it.colorName, legoColorId: it.legoColorId,
      });
    }
  }
  return { rows: Array.from(merged.values()), unmappedParts, unmappedColors, capped };
}

function buildCsv(rows) {
  const lines = ['Part,Color,Quantity'];
  for (const r of rows) lines.push(`${r.part},${r.color},${r.qty}`);
  return lines.join('\n');
}

/* ------------------------------------------------------------------ *
 * UI
 * ------------------------------------------------------------------ */
const $ = (id) => document.getElementById(id);
let lastCsv = null;
let lastScan = null;

function setStatus(msg) { $('status').textContent = msg; }

async function getActiveTab() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  return tab;
}

function esc(s) { return (s || '').replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c])); }

function render(scan) {
  const { rows, unmappedParts, unmappedColors, capped } = convert(scan.items);
  lastScan = scan;
  lastCsv = buildCsv(rows);

  const pieces = rows.reduce((s, r) => s + r.qty, 0);
  $('s-lines').textContent = rows.length;
  $('s-pieces').textContent = pieces;
  $('s-mapped').textContent = `${scan.items.filter((i) => i.part && GDS_TO_RB[i.part]).length}/${scan.items.filter((i) => i.part).length}`;

  // Warnings
  const w = [];
  if (unmappedParts.length) {
    const list = unmappedParts.map((i) => `<li>${esc(i.part)} — ${esc(i.title)}</li>`).join('');
    w.push(`<div class="warn-box"><b>${unmappedParts.length} part(s) not in the GoBricks table</b> — not written to the CSV:<ul>${list}</ul></div>`);
  }
  if (unmappedColors.length) {
    const list = unmappedColors.map((i) => `<li>${esc(i.colorText || i.colorName)}</li>`).join('');
    w.push(`<div class="warn-box"><b>${unmappedColors.length} colour(s) not recognised</b> — exported as 9999 (Any Color):<ul>${list}</ul></div>`);
  }
  const stillCapped = capped.filter((i) => i.qtyCapped);
  if (stillCapped.length) {
    w.push(`<div class="warn-box"><b>${stillCapped.length} quantity(ies) showed "99+"</b> and the exact count could not be read — defaulted to 100. Verify these in Rebrickable.</div>`);
  } else if (capped.length) {
    w.push(`<div class="warn-box">${capped.length} quantity(ies) were capped at "99+" in the page but recovered exactly from the cart data.</div>`);
  }
  $('warnings').innerHTML = w.join('');

  // Preview table
  const body = rows.map((r) => {
    const meta = RB_COLOR_META[r.color];
    const sw = meta && meta.rgb ? `<span class="sw" style="background:#${esc(meta.rgb)}"></span>` : '';
    const cname = meta ? meta.name : (r.color === '9999' ? 'Any Color' : r.color);
    return `<tr><td>${esc(r.gds)}</td><td>${esc(r.part)}</td><td>${sw}${esc(cname)} <span style="color:var(--text2)">(${esc(r.color)})</span></td><td class="num">${r.qty}</td></tr>`;
  }).join('');
  $('tbody').innerHTML = body;

  $('results').classList.remove('hidden');
  $('download').disabled = rows.length === 0;
  $('copy').disabled = rows.length === 0;

  const src = scan.meta.hadCartObject && scan.meta.qtyField
    ? `exact quantities read from cart data (field "${scan.meta.qtyField}")`
    : 'quantities read from the page';
  setStatus(`Found ${scan.meta.liCount} line item(s); ${src}. Ready to download.`);
}

async function scan() {
  $('scan').disabled = true;
  setStatus('Scanning…');
  try {
    const tab = await getActiveTab();
    if (!tab || !tab.id) { setStatus('No active tab.'); return; }
    const injection = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      world: 'MAIN',
      func: scrapeCart,
    });
    const res = injection && injection[0] && injection[0].result;
    if (!res || !res.items || res.items.length === 0) {
      setStatus('No cart items found on this page.\nMake sure you are on your yourwobb cart or checkout page (the item list must be visible), then Scan again.');
      $('results').classList.add('hidden');
      return;
    }
    render(res);
  } catch (e) {
    setStatus('Could not read this page.\n' + (e && e.message ? e.message : e) +
      '\n\nOpen your yourwobb cart/checkout page in the active tab and try again.');
  } finally {
    $('scan').disabled = false;
  }
}

function dateStamp() {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}${m}${day}`;
}

async function download() {
  if (!lastCsv) return;
  const url = 'data:text/csv;charset=utf-8,' + encodeURIComponent(lastCsv);
  try {
    await chrome.downloads.download({
      url,
      filename: `yourwobb_rebrickable_${dateStamp()}.csv`,
      saveAs: true,
    });
  } catch (e) {
    setStatus('Download failed: ' + (e && e.message ? e.message : e));
  }
}

async function copyCsv() {
  if (!lastCsv) return;
  try { await navigator.clipboard.writeText(lastCsv); setStatus('CSV copied to clipboard.'); }
  catch (e) { setStatus('Copy failed: ' + (e && e.message ? e.message : e)); }
}

async function copyDebug() {
  try {
    const tab = await getActiveTab();
    const injection = await chrome.scripting.executeScript({
      target: { tabId: tab.id }, world: 'MAIN', func: scrapeCart,
    });
    const res = injection && injection[0] && injection[0].result;
    const payload = { meta: res ? res.meta : null, items: res ? res.items : null,
                      convertedCsvPreview: lastCsv ? lastCsv.split('\n').slice(0, 5) : null };
    await navigator.clipboard.writeText(JSON.stringify(payload, null, 2));
    setStatus('Debug info copied to clipboard.');
  } catch (e) {
    setStatus('Debug copy failed: ' + (e && e.message ? e.message : e));
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const v = $('ver');
  if (v) v.textContent = 'v' + chrome.runtime.getManifest().version;
  $('scan').addEventListener('click', scan);
  $('download').addEventListener('click', download);
  $('copy').addEventListener('click', copyCsv);
  $('dbg').addEventListener('click', copyDebug);
});
