// Content types — mirror the YAML schemas in ../data. Engine-agnostic.

export type Outcome = 'CORRECT' | 'PLAUSIBLE' | 'WRONG';
export type Severity = 'low' | 'medium' | 'high' | 'critical';
export type Visibility = 'obvious' | 'subtle' | 'hidden';
/** Gemba tools that reveal clues — tagged per choice in the problem YAML (`tool:`). */
/** The 8 wastes (TIMWOODS). */
export type Waste =
  | 'transport' | 'inventory' | 'motion' | 'waiting' | 'overproduction' | 'overprocessing' | 'defects' | 'skills';
export type Tool = 'observe' | 'time' | 'count' | 'defects' | 'machine' | 'docs' | 'ask' | 'data';

export interface Choice {
  text: string;
  outcome: Outcome;
  evidence: string | null;
  hint: string;
  teaches: string[];
  tool: Tool;
}

export interface Fork {
  npc: string;
  prompt: string;
  choices: Choice[];
}

export interface WhyStep {
  why: string;
  choices: Choice[];
}

export interface EffectModifiers {
  avail: number;
  perf: number;
  quality: number;
}

export interface Problem {
  id: string;
  tier: number;
  name: string;
  category: string;
  waste: Waste;
  severity: Severity;
  visibility: Visibility;
  zoneId: string;
  stationId: string | null;
  symptoms: string[];
  rootCause: string;
  effectiveCountermeasures: string[];
  mismatchNote: string;
  effect: EffectModifiers;
  teaches: string[];
  investigation: Fork | null;
  fiveWhys: WhyStep[];
}

export interface QuizQuestion {
  question: string;
  npc: string;
  choices: { text: string; outcome: Outcome; feedback: string; teaches: string[] }[];
}

export interface Countermeasure {
  id: string;
  name: string;
  /** 1–4, or 0 for diagnostic tools */
  tier: number;
  category: string;
  description: string;
  prerequisites: string[];
  multipliers: { full: number; reduced: number; minimal: number };
  decayDays: number | null;
  quiz: QuizQuestion[];
}

export interface Mission {
  id: string;
  tier: number;
  title: string;
  description: string;
  sourceNpc: string;
  visibleAfter: string | null;
  problemIds: string[];
  completion: 'any' | 'all';
  hints: string[];
}

export interface Catalog {
  problems: Problem[];
  countermeasures: Countermeasure[];
  missions: Mission[];
  concepts: Record<string, string>;
}
