// Player progression: Six Sigma belts (from XP) and factory sites (one per tier).

export interface Belt {
  name: string;
  xp: number;
  color: string;
  unlocks: string;
}

export const BELTS: Belt[] = [
  { name: 'White Belt', xp: 0, color: '#f2efe6', unlocks: 'Gemba walks, PDCA problem solving' },
  { name: 'Yellow Belt', xp: 1200, color: '#f2c94c', unlocks: 'Obeya room: push vs pull (CONWIP) line design' },
  { name: 'Green Belt', xp: 3500, color: '#5fbf6b', unlocks: 'Second site: Rotterdam Assembly' },
  { name: 'Black Belt', xp: 7000, color: '#333', unlocks: 'Third site: Stuttgart Precision' },
  { name: 'Master Black Belt', xp: 12000, color: '#7a4fd6', unlocks: 'Fourth site: Shenzhen Gigafactory' },
];

export function beltIndex(xp: number): number {
  let idx = 0;
  BELTS.forEach((b, i) => {
    if (xp >= b.xp) idx = i;
  });
  return idx;
}

/** 0..1 progress towards the next belt (1 at the top belt). */
export function beltProgress(xp: number): number {
  const i = beltIndex(xp);
  const next = BELTS[i + 1];
  if (!next) return 1;
  return (xp - BELTS[i].xp) / (next.xp - BELTS[i].xp);
}

export interface Site {
  tier: number;
  name: string;
  city: string;
  blurb: string;
  /** Belt index required to unlock. */
  beltRequired: number;
  /** Visual theme for the 3D build. */
  theme: { floor: string; wall: string; accent: string; size: number };
}

export const SITES: Site[] = [
  {
    tier: 1, name: 'Eindhoven Pilot Plant', city: 'Eindhoven, NL', beltRequired: 0,
    blurb: 'A young hoverboard plant drowning in firefighting. Build a stable foundation: 5S, standard work, basic quality.',
    theme: { floor: '#b9b2a3', wall: '#d9d4c7', accent: '#e0a030', size: 1 },
  },
  {
    tier: 2, name: 'Rotterdam Assembly', city: 'Rotterdam, NL', beltRequired: 2,
    blurb: 'Stable but blind. Make problems visible: andon, daily management, visual control.',
    theme: { floor: '#a9b3b8', wall: '#cfd8dc', accent: '#2f80ed', size: 1.15 },
  },
  {
    tier: 3, name: 'Stuttgart Precision', city: 'Stuttgart, DE', beltRequired: 3,
    blurb: 'Visible problems, but no flow. Pull systems, SMED, line balancing, TPM.',
    theme: { floor: '#9fa8a0', wall: '#d5dbd2', accent: '#27ae60', size: 1.3 },
  },
  {
    tier: 4, name: 'Shenzhen Gigafactory', city: 'Shenzhen, CN', beltRequired: 4,
    blurb: 'World-class ambitions. SPC, DOE, FMEA, DMAIC — Six Sigma at scale.',
    theme: { floor: '#a59fb0', wall: '#d8d2e0', accent: '#9b51e0', size: 1.5 },
  },
];

export const siteUnlocked = (site: Site, xp: number): boolean => beltIndex(xp) >= site.beltRequired;
