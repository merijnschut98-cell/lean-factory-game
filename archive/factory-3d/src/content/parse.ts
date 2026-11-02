// Parses raw YAML documents into typed content. Pure functions — no Vite or
// DOM dependencies — so tests can feed them the real files from disk.
//
// Content is authored by hand, so every entry is validated: an entry with a
// missing required field is skipped with a warning instead of crashing the game.

import { parse } from 'yaml';
import type {
  Catalog, Choice, Countermeasure, Fork, Mission, Outcome, Problem, QuizQuestion,
  Severity, Tool, Visibility, Waste, WhyStep,
} from './types';

type Raw = Record<string, unknown>;
export type Warn = (msg: string) => void;

const OUTCOMES: Outcome[] = ['CORRECT', 'PLAUSIBLE', 'WRONG'];
const SEVERITIES: Severity[] = ['low', 'medium', 'high', 'critical'];
const VISIBILITIES: Visibility[] = ['obvious', 'subtle', 'hidden'];
const WASTES: Waste[] = ['transport', 'inventory', 'motion', 'waiting', 'overproduction', 'overprocessing', 'defects', 'skills'];
const TOOLS: Tool[] = ['observe', 'time', 'count', 'defects', 'machine', 'docs', 'ask', 'data'];

const isObj = (v: unknown): v is Raw => typeof v === 'object' && v !== null && !Array.isArray(v);
const str = (v: unknown, fallback = ''): string =>
  typeof v === 'string' ? v.trim().replace(/\s+/g, ' ') : fallback;
const num = (v: unknown, fallback = 0): number =>
  typeof v === 'number' && Number.isFinite(v) ? v : fallback;
const strList = (v: unknown): string[] =>
  Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string').map((x) => str(x)) : [];
const oneOf = <T extends string>(v: unknown, allowed: T[], fallback: T): T =>
  allowed.includes(v as T) ? (v as T) : fallback;

function listUnder(doc: unknown, key: string, source: string, warn: Warn): Raw[] {
  if (!isObj(doc) || !Array.isArray(doc[key])) {
    warn(`${source}: expected a top-level '${key}' list`);
    return [];
  }
  return (doc[key] as unknown[]).filter(isObj);
}

function parseChoice(raw: unknown): Choice | null {
  if (!isObj(raw) || !str(raw.text)) return null;
  return {
    text: str(raw.text),
    outcome: oneOf(raw.outcome, OUTCOMES, 'WRONG'),
    evidence: str(raw.evidence) || null,
    hint: str(raw.hint),
    teaches: strList(raw.teaches),
    tool: oneOf(raw.tool, TOOLS, 'observe'),
  };
}

function parseChoices(raw: unknown): Choice[] {
  return Array.isArray(raw) ? raw.map(parseChoice).filter((c): c is Choice => c !== null) : [];
}

/** A fork is only playable if it has a correct answer to find. */
function hasCorrect(choices: Choice[]): boolean {
  return choices.some((c) => c.outcome === 'CORRECT');
}

function parseFork(raw: unknown): Fork | null {
  if (!isObj(raw)) return null;
  const choices = parseChoices(raw.choices);
  if (!str(raw.prompt) || !hasCorrect(choices)) return null;
  return { npc: str(raw.npc, 'Team Leader'), prompt: str(raw.prompt), choices };
}

function parseWhys(raw: unknown): WhyStep[] {
  if (!Array.isArray(raw)) return [];
  return raw.flatMap((w) => {
    if (!isObj(w)) return [];
    const choices = parseChoices(w.choices);
    return str(w.why) && hasCorrect(choices) ? [{ why: str(w.why), choices }] : [];
  });
}

export function parseProblems(doc: unknown, tier: number, warn: Warn): Problem[] {
  const out: Problem[] = [];
  for (const p of listUnder(doc, 'problems', `problems_tier${tier}`, warn)) {
    const id = str(p.id);
    const zoneId = str(p.zone_id);
    if (!id || !str(p.name) || !zoneId) {
      warn(`problems_tier${tier}: skipping entry without id/name/zone_id (${id || '?'})`);
      continue;
    }
    const mods = isObj(p.effect_modifiers) ? p.effect_modifiers : {};
    const dialogue = isObj(p.dialogue) ? p.dialogue : {};
    out.push({
      id,
      tier,
      name: str(p.name),
      category: str(p.category, 'Waste'),
      waste: oneOf(p.waste, WASTES, 'waiting'),
      severity: oneOf(p.severity, SEVERITIES, 'medium'),
      visibility: oneOf(p.visibility, VISIBILITIES, 'obvious'),
      zoneId,
      stationId: str(p.station_id) || null,
      symptoms: strList(p.symptoms),
      rootCause: str(p.root_cause),
      effectiveCountermeasures: strList(p.effective_countermeasures),
      mismatchNote: str(p.mismatch_note),
      effect: {
        avail: num(mods.avail_delta),
        perf: num(mods.perf_delta),
        quality: num(mods.quality_delta),
      },
      teaches: strList(p.teaches),
      investigation: parseFork(dialogue.investigation),
      fiveWhys: parseWhys(dialogue.five_whys),
    });
  }
  return out;
}

function parseQuiz(raw: unknown): QuizQuestion[] {
  if (!Array.isArray(raw)) return [];
  return raw.flatMap((q) => {
    if (!isObj(q) || !str(q.question)) return [];
    const choices = (Array.isArray(q.choices) ? q.choices : []).flatMap((c) =>
      isObj(c) && str(c.text)
        ? [{
            text: str(c.text),
            outcome: oneOf(c.outcome, OUTCOMES, 'WRONG'),
            feedback: str(c.feedback),
            teaches: strList(c.teaches),
          }]
        : [],
    );
    return choices.some((c) => c.outcome === 'CORRECT')
      ? [{ question: str(q.question), npc: str(q.npc, 'Team Leader'), choices }]
      : [];
  });
}

export function parseCountermeasures(doc: unknown, warn: Warn): Countermeasure[] {
  const out: Countermeasure[] = [];
  for (const c of listUnder(doc, 'countermeasures', 'countermeasures', warn)) {
    const id = str(c.id);
    if (!id || !str(c.name)) {
      warn(`countermeasures: skipping entry without id/name (${id || '?'})`);
      continue;
    }
    const req = isObj(c.maturity_requirement) ? c.maturity_requirement : {};
    const eff = isObj(c.effectiveness) ? c.effectiveness : {};
    const mult = isObj(eff.multipliers) ? eff.multipliers : {};
    const decay = isObj(c.decay) ? c.decay : {};
    out.push({
      id,
      name: str(c.name),
      tier: c.tier === 'diagnostic' ? 0 : num(c.tier, 1),
      category: str(c.category, 'other'),
      description: str(c.description),
      prerequisites: strList(req.prerequisites),
      multipliers: {
        full: num(mult.full, 0.8),
        reduced: num(mult.reduced, 0.4),
        minimal: num(mult.minimal, 0.15),
      },
      decayDays: decay.enabled === true && typeof decay.days === 'number' ? decay.days : null,
      quiz: parseQuiz(c.implementation_quiz),
    });
  }
  return out;
}

export function parseMissions(doc: unknown, tier: number, warn: Warn): Mission[] {
  const out: Mission[] = [];
  for (const m of listUnder(doc, 'missions', `missions_tier${tier}`, warn)) {
    const id = str(m.id);
    const problemIds = strList(m.problem_ids);
    if (!id || !str(m.title) || problemIds.length === 0) {
      warn(`missions_tier${tier}: skipping entry without id/title/problem_ids (${id || '?'})`);
      continue;
    }
    out.push({
      id,
      tier,
      title: str(m.title),
      description: str(m.description),
      sourceNpc: str(m.source_npc, 'Team Leader'),
      visibleAfter: str(m.visible_after) || null,
      problemIds,
      completion: m.completion_condition === 'all' ? 'all' : 'any',
      hints: strList(m.hints),
    });
  }
  return out;
}

export function parseConcepts(doc: unknown, warn: Warn): Record<string, string> {
  if (!isObj(doc) || !isObj(doc.concepts)) {
    warn('concepts: expected a top-level concepts mapping');
    return {};
  }
  return Object.fromEntries(Object.entries(doc.concepts).map(([k, v]) => [k, str(v)]));
}

export interface RawContent {
  problems: string[]; // index i = tier i+1
  missions: string[];
  countermeasures: string;
  concepts: string;
}

/** Parse every content file. Missions pointing at unknown problems are dropped. */
export function buildCatalog(raw: RawContent, warn: Warn = console.warn): Catalog {
  const problems = raw.problems.flatMap((text, i) => parseProblems(parse(text), i + 1, warn));
  const known = new Set(problems.map((p) => p.id));
  const missions = raw.missions
    .flatMap((text, i) => parseMissions(parse(text), i + 1, warn))
    .map((m) => ({ ...m, problemIds: m.problemIds.filter((id) => known.has(id)) }))
    .filter((m) => m.problemIds.length > 0);
  return {
    problems,
    missions,
    countermeasures: parseCountermeasures(parse(raw.countermeasures), warn),
    concepts: parseConcepts(parse(raw.concepts), warn),
  };
}
