// Tiny DOM helpers — no framework, so the UI stays light and portable.

type Child = Node | string | number | null | undefined | false;
type Attrs = Record<string, string | number | boolean | EventListener | undefined>;

/** Create an element: h('div.card#id', { onclick }, child, ...). */
export function h(spec: string, attrs: Attrs | Child = {}, ...children: Child[]): HTMLElement {
  const [tagAndClasses, id] = spec.split('#');
  const [tag, ...classes] = tagAndClasses.split('.');
  const el = document.createElement(tag || 'div');
  if (classes.length) el.className = classes.join(' ');
  if (id) el.id = id;
  if (attrs instanceof Node || typeof attrs !== 'object' || attrs === null) {
    children.unshift(attrs as Child);
  } else {
    for (const [k, v] of Object.entries(attrs)) {
      if (v === undefined || v === false) continue;
      if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v as EventListener);
      else if (k === 'html') el.innerHTML = String(v);
      else if (k === 'style') el.setAttribute('style', String(v));
      else el.setAttribute(k, v === true ? '' : String(v));
    }
  }
  for (const c of children) {
    if (c === null || c === undefined || c === false) continue;
    el.append(c instanceof Node ? c : String(c));
  }
  return el;
}

export const fmtPct = (v: number, digits = 0) => `${(v * 100).toFixed(digits)}%`;
export const fmtMin = (sec: number) => (sec >= 3600 ? `${(sec / 3600).toFixed(1)} h` : `${Math.round(sec / 60)} min`);

/** Clock text for a sim time: shifts run 06:00–14:00. */
export function clock(simTime: number, shiftSeconds: number): string {
  const t = (simTime % shiftSeconds) + 6 * 3600;
  const hh = Math.floor(t / 3600), mm = Math.floor((t % 3600) / 60);
  return `${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}`;
}

/** Horizontal bar with a takt-style marker. */
export function bar(value: number, max: number, color: string, marker?: number): HTMLElement {
  const el = h('div.bar');
  el.append(h('i', { style: `width:${Math.min(100, (value / max) * 100)}%;background:${color}` }));
  if (marker !== undefined) el.append(h('b', { style: `left:${Math.min(100, (marker / max) * 100)}%` }));
  return el;
}
