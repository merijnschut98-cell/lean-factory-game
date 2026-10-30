// PDCA rules: countermeasure effectiveness, station bonuses and the problem score.
// Pure functions so they can be unit-tested and ported as-is.

import type { Countermeasure, EffectModifiers, Problem, Severity } from '../content/types';

export type FitLevel = 'full' | 'reduced' | 'minimal' | 'none' | 'mismatch';

export interface Effectiveness {
  eff: number;
  level: FitLevel;
}

/** A countermeasure must clear this effectiveness to pass the Check step. */
export const CHECK_PASS = 0.5;
const MISMATCH_EFF = 0.1;
const NONE_EFF = 0.05;

export const cmFits = (problem: Problem, cm: Countermeasure): boolean =>
  problem.effectiveCountermeasures.some((n) => n.toLowerCase() === cm.name.toLowerCase());

/**
 * How well a countermeasure works on a problem. The right tool at a maturity
 * the plant can't sustain yet only half-works — that is the lesson of tiers.
 */
export function effectiveness(problem: Problem, cm: Countermeasure, maturity: number): Effectiveness {
  if (!cmFits(problem, cm)) return { eff: MISMATCH_EFF, level: 'mismatch' };
  const gap = cm.tier - maturity;
  if (gap <= 0) return { eff: cm.multipliers.full, level: 'full' };
  if (gap === 1) return { eff: cm.multipliers.reduced, level: 'reduced' };
  if (gap === 2) return { eff: cm.multipliers.minimal, level: 'minimal' };
  return { eff: NONE_EFF, level: 'none' };
}

export const cmCost = (cm: Countermeasure): number => Math.max(1, cm.tier) * 100;

/** Lasting station improvement a successful countermeasure leaves behind (A, P, Q). */
const CATEGORY_BONUS: Record<string, [number, number, number]> = {
  workplace_organization: [0.01, 0.03, 0.002],
  process_standardization: [0.01, 0.035, 0.003],
  quality: [0.005, 0.01, 0.006],
  visual_management: [0.005, 0.025, 0.002],
  maintenance: [0.04, 0.02, 0.001],
  flow: [0.01, 0.04, 0.001],
  people: [0.01, 0.03, 0.002],
  safety: [0.02, 0.01, 0.001],
};
const DEFAULT_BONUS: [number, number, number] = [0.015, 0.02, 0.002];

export function stationBonus(cm: Countermeasure, eff: number): EffectModifiers {
  const [a, p, q] = CATEGORY_BONUS[cm.category] ?? DEFAULT_BONUS;
  return { avail: a * eff, perf: p * eff, quality: q * eff };
}

export const scaleEffect = (e: EffectModifiers, k: number): EffectModifiers => ({
  avail: e.avail * k,
  perf: e.perf * k,
  quality: e.quality * k,
});

// ── Score ────────────────────────────────────────────────────────────────────

export interface PdcaInputs {
  /** Key clues uncovered for this problem, out of all key clues it has. */
  keyFound: number;
  keyTotal: number;
  /** Observed at least one other station in the same zone. */
  scoutedZone: boolean;
  /** Asked an operator a blaming question while this problem was open. */
  blamed: boolean;
  causeCorrect: boolean;
  /** Evidence linked on the A3: real clues vs red herrings. */
  keyLinked: number;
  herringsLinked: number;
  eff: number;
  failedChecks: number;
  predictionRight: boolean;
  standardized: boolean;
  wasteRight: boolean;
  /** Relative change in whole-line capacity caused by the fix (0.05 = +5%). */
  capacityGain: number;
  /** Was the station the line's constraint when the fix went in? */
  atConstraint: boolean;
  constraintName: string;
}

export interface PdcaScore {
  plan: number;
  rootCause: number;
  countermeasure: number;
  checkAct: number;
  impact: number;
  total: number;
  notes: string[];
}

const clamp15 = (v: number) => Math.max(1, Math.min(5, Math.round(v)));

export function scorePdca(i: PdcaInputs): PdcaScore {
  const notes: string[] = [];
  const coverage = i.keyTotal > 0 ? i.keyFound / i.keyTotal : 1;
  const plan = clamp15(1 + coverage * 3 + (i.scoutedZone ? 1 : 0) - (i.blamed ? 1 : 0));
  if (coverage < 1) notes.push(`Go & See: you uncovered ${i.keyFound} of ${i.keyTotal} key facts. Another tool or another “why” would have shown more.`);
  if (!i.scoutedZone) notes.push('Go & See: walk the neighbouring stations too — causes often sit upstream.');
  if (i.blamed) notes.push('Respect for people: a blaming question shut an operator down. Problems live in the process, not the person.');

  const rootCause = i.causeCorrect ? clamp15(2 + Math.min(2, i.keyLinked) + (i.wasteRight ? 1 : 0) - i.herringsLinked) : 1;
  if (!i.wasteRight) notes.push('Waste: you named a different waste than the one at the gemba. Learn to see TIMWOODS.');
  if (!i.causeCorrect) notes.push('Root cause: your A3 named the wrong cause. Ask “why” again until the evidence explains the symptom.');
  else if (i.herringsLinked > 0) notes.push('Root cause: right cause, but some evidence you linked was a red herring — true, yet not causal.');
  else if (i.keyLinked === 0) notes.push('Root cause: right answer, thin evidence. Link the facts that prove it.');

  const base = i.eff >= 0.7 ? 5 : i.eff >= CHECK_PASS ? 4 : 2;
  const countermeasure = clamp15(base - i.failedChecks);
  if (i.failedChecks > 0) notes.push('Countermeasure: an earlier experiment failed Check — that is PDCA working, but it cost time and credits.');

  const checkAct = clamp15(2 + (i.predictionRight ? 1 : 0) + (i.standardized ? 2 : 0));
  if (!i.predictionRight) notes.push('Check: the result differed from your prediction. That gap is where the learning is (Kata).');
  if (!i.standardized) notes.push('Act: without a new standard, the gain will erode. Sustain is the hardest S.');

  const impact = i.capacityGain >= 0.03 ? 5 : i.capacityGain >= 0.01 ? 4 : i.capacityGain > 0.002 ? 2 : 1;
  if (impact <= 2) {
    notes.push(i.atConstraint
      ? 'Flow impact: you worked on the constraint, but the gain was small. Look for its biggest loss next.'
      : `Flow impact: the station improved, but the line still waits on ${i.constraintName}. Improving a non-bottleneck ships nothing extra.`);
  } else notes.push('Flow impact: the whole line can now ship more. That is improvement that counts.');

  const total = plan + rootCause + countermeasure + checkAct + impact;
  return { plan, rootCause, countermeasure, checkAct, impact, total, notes };
}

const CREDIT_BASE: Record<Severity, number> = { low: 120, medium: 180, high: 240, critical: 320 };

export const MAX_SCORE = 25;
export const creditsFor = (s: PdcaScore, sev: Severity): number => Math.round((CREDIT_BASE[sev] * s.total) / MAX_SCORE);
export const xpFor = (s: PdcaScore, tier: number): number => s.total * 10 * tier;
