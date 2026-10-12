// Investigation by doing: gemba tools reveal clues, questions earn (or lose)
// operator trust, and the player builds the root cause from evidence.
//
// Clues come from the authored YAML: an investigation/5-Whys choice that was
// CORRECT becomes a *key* clue, a PLAUSIBLE one becomes a true-but-misleading
// red herring. Deeper 5-Whys clues stay hidden until the shallower key clue is
// found — the 5 Whys as an investigation, not a quiz.

import type { Problem, Tool, Waste } from '../content/types';

export interface ToolDef {
  label: string;
  icon: string;
  /** Simulated minutes the action takes. */
  minutes: number;
  blurb: string;
  /** Can this tool expose problems a quick look misses? */
  deep: boolean;
}

export const TOOLS: Record<Tool, ToolDef> = {
  observe: { label: 'Observe the work', icon: '👁', minutes: 15, deep: false, blurb: 'Stand in the circle. Watch what actually happens.' },
  time: { label: 'Time study', icon: '⏱', minutes: 60, deep: true, blurb: 'Stopwatch on ten cycles. Hard data on cycle time and variation.' },
  count: { label: 'Count WIP & material', icon: '📦', minutes: 20, deep: false, blurb: 'Count what sits in and around the station.' },
  defects: { label: 'Sort the scrap bin', icon: '🗑', minutes: 30, deep: true, blurb: 'Categorise rejects. What fails, and how often?' },
  machine: { label: 'Check equipment', icon: '🔧', minutes: 30, deep: true, blurb: 'Inspect the machine, fixtures and maintenance log.' },
  docs: { label: 'Review standards & records', icon: '📄', minutes: 20, deep: false, blurb: 'Work instructions, specs, logs, ownership.' },
  data: { label: 'Analyse the data', icon: '📈', minutes: 45, deep: true, blurb: 'Pull MES / quality data and look for patterns.' },
  ask: { label: 'Talk to the operator', icon: '🗣', minutes: 15, deep: false, blurb: 'The people doing the work know the most.' },
};

export const STATION_TOOLS: Tool[] = ['observe', 'time', 'count', 'defects', 'machine', 'docs', 'data'];

export interface Clue {
  id: string;
  problemId: string;
  tool: Tool;
  text: string;
  /** True for evidence that points at the real cause. */
  key: boolean;
  /** 0 = surface finding, n = n-th "why" deeper. */
  depth: number;
  /** Coach reflection, shown in the debrief. */
  note: string;
  teaches: string[];
}

export function buildClues(p: Problem): Clue[] {
  const out: Clue[] = [];
  const add = (depth: number, choices: Problem['fiveWhys'][number]['choices'], useTextAsFact: boolean) => {
    choices.forEach((c, i) => {
      if (c.outcome === 'WRONG') return;
      const text = c.evidence ?? (useTextAsFact ? c.text : null);
      if (!text) return;
      out.push({
        id: `${p.id}:${depth}:${i}`, problemId: p.id, tool: c.tool, text,
        key: c.outcome === 'CORRECT', depth, note: c.hint, teaches: c.teaches,
      });
    });
  };
  if (p.investigation) add(0, p.investigation.choices, false);
  p.fiveWhys.forEach((w, k) => add(k + 1, w.choices, true));
  return out;
}

// ── The 8 wastes (TIMWOODS) ──────────────────────────────────────────────────

export const WASTES: Record<Waste, { letter: string; label: string; look: string }> = {
  transport: { letter: 'T', label: 'Transport', look: 'Material moved further or more often than needed' },
  inventory: { letter: 'I', label: 'Inventory', look: 'Piles of material waiting between steps' },
  motion: { letter: 'M', label: 'Motion', look: 'People walking, searching, reaching' },
  waiting: { letter: 'W', label: 'Waiting', look: 'People or machines idle — for parts, approval, repair, information' },
  overproduction: { letter: 'O', label: 'Overproduction', look: 'Making more or earlier than the next step needs' },
  overprocessing: { letter: 'O', label: 'Over-processing', look: 'Steps, checks or reports that add no customer value' },
  defects: { letter: 'D', label: 'Defects', look: 'Scrap, rework, escapes, re-inspection' },
  skills: { letter: 'S', label: 'Skills', look: 'People’s knowledge and ideas left unused' },
};

// ── Operator conversations ───────────────────────────────────────────────────

export type QuestionKind = 'open' | 'closed' | 'blame' | 'repair';
export interface Question {
  id: string;
  text: string;
  kind: QuestionKind;
}

export const QUESTIONS: Question[] = [
  { id: 'walk', kind: 'open', text: 'Walk me through your job, step by step.' },
  { id: 'obstacle', kind: 'open', text: 'What makes this job harder than it should be?' },
  { id: 'last', kind: 'open', text: 'Can you show me what happened the last time something went wrong?' },
  { id: 'standard', kind: 'closed', text: 'Do you follow the standard work?' },
  { id: 'ok', kind: 'closed', text: 'Is everything running OK today?' },
  { id: 'behind', kind: 'blame', text: 'Why is this station always behind?' },
  { id: 'who', kind: 'blame', text: 'Who made the mistake on the last bad unit?' },
  { id: 'thanks', kind: 'repair', text: 'Explain why you’re here — to fix the process, not to judge people — and thank them.' },
];

export const CLOSED_REPLIES = ['“Yeah. Mostly.”', '“Sure, it’s fine.”', '“Yes.” (They wait for you to leave.)'];
export const BLAME_REPLIES = [
  '“…We do our best.” They turn back to their work and avoid your eyes.',
  '“Not my call.” Arms crossed. This conversation is over.',
];
export const GUARDED_REPLY = '“It’s fine. Everything’s fine.” After that last question, they’re not opening up.';
export const REPAIR_REPLY = 'They relax a little. “Alright… what do you want to know?”';

// ── Root cause bank ──────────────────────────────────────────────────────────

/** Stable hash for deterministic shuffles (same problem → same option order). */
function hash(s: string): number {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 16777619);
  return h >>> 0;
}

/**
 * Candidate root causes for the A3: the real one, plausible-sounding causes
 * from the 5 Whys, and real root causes of *other* problems in the tier.
 * Returns the options and the index of the true root cause.
 */
export function causeOptions(p: Problem, all: Problem[], n = 5): { options: string[]; correct: number } {
  const plausible = p.fiveWhys.flatMap((w) => w.choices.filter((c) => c.outcome === 'PLAUSIBLE').map((c) => c.text));
  const others = all
    .filter((o) => o.id !== p.id && o.tier === p.tier && o.rootCause)
    .sort((a, b) => Number(b.category === p.category) - Number(a.category === p.category) || hash(p.id + a.id) - hash(p.id + b.id))
    .map((o) => o.rootCause);
  const distractors = [...plausible.slice(0, 2), ...others].slice(0, n - 1);
  const options = [p.rootCause, ...distractors].sort((a, b) => hash(p.id + a) - hash(p.id + b));
  return { options, correct: options.indexOf(p.rootCause) };
}

// ── Prediction (Toyota Kata: "what do you expect?") ──────────────────────────

export type Metric = 'cycle' | 'downtime' | 'quality' | 'flow';
export const METRICS: Record<Metric, string> = {
  cycle: 'Cycle time drops (faster, steadier work)',
  downtime: 'Fewer stoppages (higher availability)',
  quality: 'Fewer defects (less scrap and rework)',
  flow: 'Better flow (less waiting, less WIP)',
};

/** The KPI this problem actually hurts most. */
export function expectedMetric(p: Problem): Metric {
  const { avail, perf, quality } = p.effect;
  const a = Math.abs(avail), q = Math.abs(quality) * 3, c = Math.abs(perf);
  if (a + q + c === 0) return 'flow';
  if (q >= a && q >= c) return 'quality';
  return a > c ? 'downtime' : 'cycle';
}
