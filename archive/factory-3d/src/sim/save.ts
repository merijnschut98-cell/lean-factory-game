// Save-file schema and validation. Saves come from browser storage, which the
// player (or an old build) can corrupt, so nothing is trusted until checked.

import type { Profile, SiteSave } from './game';

export const SAVE_VERSION = 1;

export interface SaveFile {
  v: number;
  currentTier: number;
  profile: Profile;
  sites: Record<string, SiteSave>;
}

type Raw = Record<string, unknown>;
const isObj = (v: unknown): v is Raw => typeof v === 'object' && v !== null && !Array.isArray(v);
const isNum = (v: unknown): v is number => typeof v === 'number' && Number.isFinite(v);

function validProfile(p: unknown): p is Profile {
  return isObj(p) && isNum(p.credits) && isNum(p.xp) && isNum(p.resolved) &&
    Array.isArray(p.concepts) && p.concepts.every((c) => typeof c === 'string');
}

function validSite(s: unknown): s is SiteSave {
  return isObj(s) && isNum(s.time) && s.time >= 0 && isNum(s.day) && s.day >= 1 && isNum(s.shippedTotal) &&
    (s.releaseMode === 'push' || s.releaseMode === 'conwip') && isNum(s.conwipLimit) &&
    Array.isArray(s.problems) && s.problems.every((p) => isObj(p) && typeof p.id === 'string' && typeof p.phase === 'string') &&
    Array.isArray(s.missions) && s.missions.every((m) => isObj(m) && typeof m.id === 'string' && typeof m.status === 'string') &&
    Array.isArray(s.observed) && Array.isArray(s.history) &&
    Array.isArray(s.found) && s.found.every((f) => typeof f === 'string') &&
    Array.isArray(s.trust) && s.trust.every((t) => Array.isArray(t) && typeof t[0] === 'string' && isNum(t[1]));
}

/** Parse and validate a save. Returns null (never throws) when it is unusable. */
export function parseSave(text: string | null): SaveFile | null {
  if (!text) return null;
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    return null;
  }
  if (!isObj(raw) || raw.v !== SAVE_VERSION || !isNum(raw.currentTier) || !validProfile(raw.profile) || !isObj(raw.sites)) {
    return null;
  }
  const sites: Record<string, SiteSave> = {};
  for (const [k, v] of Object.entries(raw.sites)) if (validSite(v)) sites[k] = v;
  return { v: SAVE_VERSION, currentTier: raw.currentTier, profile: raw.profile, sites };
}
