// Game rules for one factory site: missions → problems → investigation → A3 →
// experiment → Check → Act. Owns the FlowSim. The 3D world and UI call the
// player actions below and drain `events`; nothing here knows Three.js or the DOM.

import type { Catalog, Countermeasure, Mission, Problem, Tool, Waste } from '../content/types';
import { FlowSim, type DaySummary, type StationRt } from './flow';
import { SHIFT_SECONDS, stationForProblem } from './line';
import {
  BLAME_REPLIES, CLOSED_REPLIES, GUARDED_REPLY, QUESTIONS, REPAIR_REPLY, TOOLS, WASTES,
  buildClues, causeOptions, expectedMetric, type Clue, type Metric, type QuestionKind,
} from './investigation';
import {
  CHECK_PASS, cmCost, creditsFor, effectiveness, scaleEffect, scorePdca, stationBonus, xpFor,
  type FitLevel, type PdcaScore,
} from './pdca';
import { SITES, beltIndex, type Site } from './progression';

export type Phase = 'dormant' | 'active' | 'spotted' | 'doing' | 'checkReady' | 'resolved';
export const OPEN_PHASES: Phase[] = ['active', 'spotted', 'doing', 'checkReady'];

export interface A3 {
  waste: Waste;
  cause: number;
  evidence: string[];
  cmId: string;
  prediction: Metric;
}

export interface ProblemRt {
  id: string;
  phase: Phase;
  stationId: string;
  toolsUsed: Tool[];
  blamed: boolean;
  a3: A3 | null;
  eff: number;
  level: FitLevel | null;
  tried: string[];
  failedChecks: number;
  checkAt: number;
  baseline: { ect: number; quality: number; capacity: number; constraint: string } | null;
  standardized: boolean;
  recurAt: number | null;
  score: PdcaScore | null;
}

export type MissionStatus = 'locked' | 'offered' | 'active' | 'done';
export interface MissionRt {
  id: string;
  status: MissionStatus;
  hintsShown: number;
  activeSince: number;
}

export interface Profile {
  credits: number;
  xp: number;
  concepts: string[];
  resolved: number;
}

export type Tone = 'info' | 'good' | 'warn' | 'bad';
export type GameEvent =
  | { kind: 'toast'; text: string; tone: Tone }
  | { kind: 'day'; summary: DaySummary }
  | { kind: 'belt'; belt: number }
  | { kind: 'missionDone'; missionId: string };

export interface ToolResult {
  spotted: string[];
  clues: Clue[];
  /** A quick look found nothing, but something here needs a deeper tool. */
  hiddenSignal: boolean;
}

export interface AskResult {
  kind: QuestionKind;
  reply: string;
  clue: Clue | null;
  trust: number;
}

export interface Snapshot {
  ect: number;
  quality: number;
  /** Whole-line good units per shift. */
  capacity: number;
  constraint: string;
}

export interface CheckResult {
  passed: boolean;
  before: Snapshot;
  after: Snapshot;
  level: FitLevel;
  predicted: Metric;
  actual: Metric;
  causeCorrect: boolean;
  wasteRight: boolean;
  lesson: string;
}

const MAX_OPEN = 3;
const HINT_EVERY = SHIFT_SECONDS / 3;
const CHECK_DELAY = SHIFT_SECONDS / 4;
export const STANDARDIZE_COST = 60;
const SEVERITY_RANK = { critical: 0, high: 1, medium: 2, low: 3 } as const;

export class SiteGame {
  readonly flow: FlowSim;
  readonly problems = new Map<string, ProblemRt>();
  readonly missions = new Map<string, MissionRt>();
  readonly history: DaySummary[] = [];
  readonly observed = new Set<string>();
  /** Clue ids the player has uncovered (key clues and red herrings). */
  readonly found = new Set<string>();
  /** Operator trust per station: below 0 they stop sharing. */
  readonly trust = new Map<string, number>();
  readonly clues = new Map<string, Clue[]>();
  events: GameEvent[] = [];
  private replyCounter = 0;

  constructor(
    readonly catalog: Catalog,
    readonly site: Site,
    readonly profile: Profile,
    seed = site.tier * 101,
  ) {
    this.flow = new FlowSim(seed);
    this.flow.onDayEnd = (s) => {
      this.history.push(s);
      if (this.history.length > 14) this.history.shift();
      this.events.push({ kind: 'day', summary: s });
    };
    for (const p of this.siteProblems()) {
      this.problems.set(p.id, newProblemRt(p));
      this.clues.set(p.id, buildClues(p));
    }
    for (const m of this.siteMissions()) {
      this.missions.set(m.id, { id: m.id, status: 'locked', hintsShown: 0, activeSince: 0 });
    }
    this.refreshMissions();
  }

  // ── Lookups ──────────────────────────────────────────────────────────────
  siteProblems(): Problem[] {
    return this.catalog.problems.filter((p) => p.tier === this.site.tier);
  }
  siteMissions(): Mission[] {
    return this.catalog.missions.filter((m) => m.tier === this.site.tier);
  }
  problem(id: string): Problem {
    const p = this.catalog.problems.find((x) => x.id === id);
    if (!p) throw new Error(`Unknown problem ${id}`);
    return p;
  }
  mission(id: string): Mission {
    const m = this.catalog.missions.find((x) => x.id === id);
    if (!m) throw new Error(`Unknown mission ${id}`);
    return m;
  }
  cm(id: string): Countermeasure {
    const c = this.catalog.countermeasures.find((x) => x.id === id);
    if (!c) throw new Error(`Unknown countermeasure ${id}`);
    return c;
  }
  rt(id: string): ProblemRt {
    const r = this.problems.get(id);
    if (!r) throw new Error(`Problem ${id} is not part of this site`);
    return r;
  }
  station(id: string): StationRt | undefined {
    return this.flow.station(id);
  }
  stationName(id: string): string {
    return this.station(id)?.def.name ?? id;
  }
  openAt(stationId: string): ProblemRt[] {
    return [...this.problems.values()].filter((r) => r.stationId === stationId && OPEN_PHASES.includes(r.phase));
  }
  /** Problems the player knows about (spotted or later, not yet resolved). */
  known(): ProblemRt[] {
    return [...this.problems.values()].filter((r) => OPEN_PHASES.includes(r.phase) && r.phase !== 'active');
  }
  resolved(): ProblemRt[] {
    return [...this.problems.values()].filter((r) => r.phase === 'resolved');
  }
  missionsOfferedBy(role: string): MissionRt[] {
    return [...this.missions.values()].filter((m) => m.status === 'offered' && this.mission(m.id).sourceNpc === role);
  }
  activeMissions(): MissionRt[] {
    return [...this.missions.values()].filter((m) => m.status === 'active');
  }
  get maturity(): number {
    const all = this.siteProblems().length;
    return Math.min(4, this.site.tier + (all > 0 && this.resolved().length / all >= 0.6 ? 1 : 0));
  }
  /** Countermeasures the player may choose from at this site (no diagnostics). */
  availableCountermeasures(): Countermeasure[] {
    return this.catalog.countermeasures.filter((c) => c.tier >= 1 && c.tier <= Math.min(4, this.site.tier + 1));
  }
  /** Station + whole-line numbers, for before/after comparisons. */
  snapshot(stationId: string): Snapshot {
    const st = this.station(stationId);
    const line = this.flow.lineCapacity();
    return {
      ect: st?.effectiveCt ?? 0,
      quality: st?.quality ?? 1,
      capacity: line.perShift,
      constraint: line.constraint.def.id,
    };
  }

  trustAt(stationId: string): number {
    return this.trust.get(stationId) ?? 0;
  }
  /** Every clue uncovered so far, across all problems (what the A3 can cite). */
  foundClues(): Clue[] {
    return [...this.clues.values()].flat().filter((c) => this.found.has(c.id));
  }
  causeOptions(id: string): string[] {
    return causeOptions(this.problem(id), this.siteProblems()).options;
  }

  private toast(text: string, tone: Tone = 'info'): void {
    this.events.push({ kind: 'toast', text, tone });
  }
  learn(tags: string[]): void {
    for (const t of tags) if (!this.profile.concepts.includes(t)) this.profile.concepts.push(t);
  }

  // ── Time ─────────────────────────────────────────────────────────────────
  advance(seconds: number): void {
    this.flow.advance(seconds);
    const now = this.flow.time;
    for (const r of this.problems.values()) {
      if (r.phase === 'doing' && now >= r.checkAt) {
        r.phase = 'checkReady';
        this.toast(`Your experiment at ${this.stationName(r.stationId)} has run long enough. Go and Check the results.`);
      }
      if (r.phase === 'resolved' && r.recurAt !== null && now >= r.recurAt) this.recur(r);
    }
    for (const m of this.activeMissions()) {
      const due = Math.floor((now - m.activeSince) / HINT_EVERY) + 1;
      m.hintsShown = Math.min(this.mission(m.id).hints.length, Math.max(m.hintsShown, due));
    }
  }

  // ── Missions ─────────────────────────────────────────────────────────────
  refreshMissions(): void {
    for (const m of this.missions.values()) {
      if (m.status !== 'locked') continue;
      const def = this.mission(m.id);
      const pre = def.visibleAfter ? this.missions.get(def.visibleAfter) : undefined;
      // Predecessors from another tier belong to an earlier site: treat as met.
      if (!pre || pre.status === 'done') {
        m.status = 'offered';
        this.toast(`${def.sourceNpc} wants a word with you: “${def.title}”`);
      }
    }
  }

  acceptMission(id: string): void {
    const m = this.missions.get(id);
    if (!m || m.status !== 'offered') return;
    m.status = 'active';
    m.activeSince = this.flow.time;
    m.hintsShown = 1;
    this.activateProblems();
  }

  /** Ask the mission's NPC for the next hint. */
  requestHint(id: string): string | null {
    const m = this.missions.get(id);
    if (!m || m.status !== 'active') return null;
    const hints = this.mission(id).hints;
    m.hintsShown = Math.min(hints.length, m.hintsShown + 1);
    return hints[m.hintsShown - 1] ?? null;
  }

  private activateProblems(): void {
    const open = () => [...this.problems.values()].filter((r) => OPEN_PHASES.includes(r.phase)).length;
    const queue = this.activeMissions()
      .flatMap((m) => this.mission(m.id).problemIds)
      .filter((id) => this.problems.get(id)?.phase === 'dormant')
      .map((id) => this.problem(id))
      .sort((a, b) => SEVERITY_RANK[a.severity] - SEVERITY_RANK[b.severity]);
    for (const p of queue) {
      if (open() >= MAX_OPEN) break;
      const r = this.rt(p.id);
      r.phase = 'active';
      this.applyProblemEffect(r);
    }
  }

  private applyProblemEffect(r: ProblemRt): void {
    this.flow.setModifier(r.stationId, `p:${r.id}`, scaleEffect(this.problem(r.id).effect, 1 - r.eff));
  }

  // ── Plan: Go & See ───────────────────────────────────────────────────────
  private spot(stationId: string, deep: boolean): string[] {
    this.observed.add(stationId);
    const spotted: string[] = [];
    for (const r of this.openAt(stationId)) {
      if (r.phase !== 'active') continue;
      if (this.problem(r.id).visibility === 'hidden' && !deep) continue;
      r.phase = 'spotted';
      spotted.push(r.id);
    }
    if (spotted.length) this.learn(['gemba']);
    return spotted;
  }

  /** A clue can be found once the key clue one "why" shallower is known. */
  private revealable(c: Clue): boolean {
    if (this.found.has(c.id)) return false;
    if (c.depth === 0) return true;
    return (this.clues.get(c.problemId) ?? []).some((k) => k.key && k.depth === c.depth - 1 && this.found.has(k.id));
  }

  private reveal(c: Clue): Clue {
    this.found.add(c.id);
    this.learn(c.teaches);
    return c;
  }

  /** Spend time at a station with a gemba tool. The caller advances the clock. */
  useTool(stationId: string, tool: Tool): ToolResult {
    const spotted = this.spot(stationId, TOOLS[tool].deep);
    const clues: Clue[] = [];
    for (const r of this.openAt(stationId)) {
      if (r.phase === 'active') continue;
      if (!r.toolsUsed.includes(tool)) r.toolsUsed.push(tool);
      // Single pass: one tool use goes one "why" deeper, not all the way down.
      const ready = (this.clues.get(r.id) ?? []).filter((c) => c.tool === tool && this.revealable(c));
      clues.push(...ready.map((c) => this.reveal(c)));
    }
    if (tool === 'time') this.learn(['time_study']);
    if (tool === 'defects' || tool === 'data') this.learn(['pareto']);
    return { spotted, clues, hiddenSignal: !spotted.length && this.hasHiddenSignal(stationId) };
  }

  hasHiddenSignal(stationId: string): boolean {
    return this.openAt(stationId).some((r) => r.phase === 'active' && this.problem(r.id).visibility === 'hidden');
  }

  /** Talk to the operator. How you ask decides what you learn. */
  ask(stationId: string, questionId: string): AskResult {
    const q = QUESTIONS.find((x) => x.id === questionId);
    if (!q) throw new Error(`Unknown question ${questionId}`);
    const trust = this.trustAt(stationId);
    const pick = (lines: string[]) => lines[this.replyCounter++ % lines.length];
    if (q.kind === 'blame') {
      this.trust.set(stationId, Math.max(-2, trust - 1));
      for (const r of this.openAt(stationId)) r.blamed = true;
      this.learn(['respect_for_people']);
      return { kind: q.kind, reply: pick(BLAME_REPLIES), clue: null, trust: this.trustAt(stationId) };
    }
    if (q.kind === 'repair') {
      this.trust.set(stationId, Math.min(1, trust + 1));
      this.learn(['respect_for_people']);
      return { kind: q.kind, reply: trust < 0 ? REPAIR_REPLY : '“No worries. Happy to help.”', clue: null, trust: this.trustAt(stationId) };
    }
    if (q.kind === 'closed') {
      this.learn(['open_questions']);
      return { kind: q.kind, reply: pick(CLOSED_REPLIES), clue: null, trust };
    }
    if (trust < 0) return { kind: q.kind, reply: GUARDED_REPLY, clue: null, trust };
    this.spot(stationId, false);
    this.learn(['open_questions']);
    const clue = this.openAt(stationId)
      .filter((r) => r.phase !== 'active')
      .flatMap((r) => (this.clues.get(r.id) ?? []).filter((c) => c.tool === 'ask' && this.revealable(c)))
      .sort((a, b) => a.depth - b.depth)[0];
    for (const r of this.openAt(stationId)) if (r.phase !== 'active' && !r.toolsUsed.includes('ask')) r.toolsUsed.push('ask');
    if (clue) return { kind: q.kind, reply: `“${clue.text}”`, clue: this.reveal(clue), trust };
    return { kind: q.kind, reply: this.operatorView(stationId, questionId), clue: null, trust };
  }

  /** What an operator would truthfully say about their station right now. */
  private operatorView(stationId: string, questionId: string): string {
    const st = this.station(stationId);
    if (!st) return '“Nothing to tell, really.”';
    const sh = st.share;
    if (questionId === 'walk') {
      return `“I take a unit from the pallet, do my ${Math.round(st.def.ct / 60)} minutes of work, and send it up the conveyor. ` +
        `${st.def.operators > 1 ? 'We split the steps between us.' : 'It’s just me on this one.'}”`;
    }
    if (sh.down > 0.12) return '“The machine stops on us a lot. Then we wait for maintenance — sometimes half an hour.”';
    if (sh.starved > 0.3) return '“Honestly? Half the shift I’m waiting for parts from upstream.”';
    if (sh.blocked > 0.1) return '“I can’t send units on — the next station is full, so I just stand here.”';
    if (st.scrapToday > 1) return `“We’ve had ${st.scrapToday} rejects today. Nobody really knows why.”`;
    if (st.queue.length > 8) return '“Look at that pile. We never catch up, no matter what we do.”';
    return '“It’s been an ordinary day. Stay a while and watch — you’ll see how it goes.”';
  }

  // ── Plan → Do: the A3 ────────────────────────────────────────────────────
  submitA3(id: string, a3: A3): { ok: true } | { ok: false; reason: string } {
    const r = this.rt(id);
    if (r.phase !== 'spotted') return { ok: false, reason: 'This problem is not ready for a countermeasure.' };
    const options = this.causeOptions(id);
    if (!(a3.waste in WASTES)) return { ok: false, reason: 'Name the waste you see.' };
    if (!Number.isInteger(a3.cause) || a3.cause < 0 || a3.cause >= options.length) {
      return { ok: false, reason: 'Pick the root cause you believe in.' };
    }
    const evidence = a3.evidence.filter((e) => this.found.has(e));
    if (evidence.length === 0) return { ok: false, reason: 'An A3 without evidence is an opinion. Link at least one fact you found.' };
    const cm = this.availableCountermeasures().find((c) => c.id === a3.cmId);
    if (!cm) return { ok: false, reason: 'Choose a countermeasure.' };
    const cost = cmCost(cm);
    if (this.profile.credits < cost) return { ok: false, reason: `Not enough credits (${cost} needed).` };

    this.profile.credits -= cost;
    r.baseline = this.snapshot(r.stationId);
    const e = effectiveness(this.problem(id), cm, this.maturity);
    r.a3 = { ...a3, evidence };
    r.eff = e.eff;
    r.level = e.level;
    r.phase = 'doing';
    r.checkAt = this.flow.time + CHECK_DELAY;
    this.applyProblemEffect(r);
    if (e.eff >= CHECK_PASS) this.flow.setModifier(r.stationId, `cm:${r.id}`, stationBonus(cm, e.eff));
    this.learn(['A3', 'kata_prediction']);
    return { ok: true };
  }

  // ── Check ────────────────────────────────────────────────────────────────
  check(id: string): CheckResult | null {
    const r = this.rt(id);
    if (r.phase !== 'checkReady' || !r.a3) return null;
    const p = this.problem(id);
    const cm = this.cm(r.a3.cmId);
    const before = r.baseline ?? this.snapshot(r.stationId);
    const after = this.snapshot(r.stationId);
    const passed = r.eff >= CHECK_PASS;
    const level = r.level ?? 'mismatch';
    const causeCorrect = causeOptions(p, this.siteProblems()).correct === r.a3.cause;
    let lesson = causeCorrect
      ? `${cm.name} addressed the root cause, and you can explain why it worked.`
      : `The numbers moved — but the root cause on your A3 is not the real one. A fix you can't explain can't be standardized.`;
    this.learn(['PDCA']);
    const wasteRight = r.a3.waste === p.waste;
    this.learn(['eight_wastes', `waste_${p.waste}`]);
    if (passed && before.constraint !== r.stationId && after.capacity - before.capacity < before.capacity * 0.01) {
      lesson += ` But look at the line: it still ships about ${Math.round(after.capacity)} boards a shift, because ${this.stationName(after.constraint)} sets the pace.`;
      this.learn(['bottleneck_focus', 'theory_of_constraints']);
    }
    const result = { passed, before, after, level, predicted: r.a3.prediction, actual: expectedMetric(p), causeCorrect, wasteRight, lesson };
    if (passed) return result;

    r.failedChecks++;
    r.tried.push(r.a3.cmId);
    r.eff = 0;
    r.level = null;
    r.phase = 'spotted';
    this.flow.clearModifier(r.stationId, `cm:${r.id}`);
    this.applyProblemEffect(r);
    lesson = level === 'mismatch'
      ? `${cm.name} did not touch the real cause. ${p.mismatchNote} Go back to the gemba — what did you miss?`
      : `${cm.name} is the right idea, but this plant isn't mature enough to sustain it yet (Tier ${cm.tier}). Build the foundation first.`;
    return { ...result, lesson };
  }

  // ── Act ──────────────────────────────────────────────────────────────────
  act(id: string, standardize: boolean): PdcaScore | null {
    const r = this.rt(id);
    if (r.phase !== 'checkReady' || !r.a3) return null;
    if (standardize && this.profile.credits < STANDARDIZE_COST) standardize = false;
    if (standardize) this.profile.credits -= STANDARDIZE_COST;
    const p = this.problem(id);
    const cm = this.cm(r.a3.cmId);
    const clues = this.clues.get(id) ?? [];
    const keys = clues.filter((c) => c.key);
    const zone = this.station(r.stationId)?.def.zoneId;
    const base = r.baseline;
    const score = scorePdca({
      keyFound: keys.filter((c) => this.found.has(c.id)).length,
      keyTotal: keys.length,
      scoutedZone: [...this.observed].some((s) => s !== r.stationId && this.station(s)?.def.zoneId === zone),
      blamed: r.blamed,
      causeCorrect: causeOptions(p, this.siteProblems()).correct === r.a3.cause,
      keyLinked: r.a3.evidence.filter((e) => keys.some((k) => k.id === e)).length,
      herringsLinked: r.a3.evidence.filter((e) => !keys.some((k) => k.id === e)).length,
      eff: r.eff,
      failedChecks: r.failedChecks,
      predictionRight: r.a3.prediction === expectedMetric(p),
      standardized: standardize,
      wasteRight: r.a3.waste === p.waste,
      capacityGain: base ? (this.flow.lineCapacity().perShift - base.capacity) / base.capacity : 0,
      atConstraint: base?.constraint === r.stationId,
      constraintName: this.stationName(base?.constraint ?? r.stationId),
    });
    r.score = score;
    r.standardized = standardize;
    r.phase = 'resolved';
    r.recurAt = !standardize && cm.decayDays ? this.flow.time + Math.max(2, cm.decayDays / 3) * SHIFT_SECONDS : null;
    this.flow.clearModifier(r.stationId, `p:${r.id}`);
    this.learn([...p.teaches, ...(standardize ? ['standard_work'] : [])]);

    const belt = beltIndex(this.profile.xp);
    this.profile.credits += creditsFor(score, p.severity);
    this.profile.xp += xpFor(score, p.tier);
    this.profile.resolved++;
    if (beltIndex(this.profile.xp) > belt) this.events.push({ kind: 'belt', belt: beltIndex(this.profile.xp) });

    this.completeMissions();
    this.activateProblems();
    return score;
  }

  private completeMissions(): void {
    for (const m of this.activeMissions()) {
      const def = this.mission(m.id);
      const done = def.problemIds.map((id) => this.problems.get(id)?.phase === 'resolved');
      if (def.completion === 'all' ? done.every(Boolean) : done.some(Boolean)) {
        m.status = 'done';
        this.events.push({ kind: 'missionDone', missionId: m.id });
      }
    }
    this.refreshMissions();
  }

  private recur(r: ProblemRt): void {
    const name = this.problem(r.id).name;
    this.flow.clearModifier(r.stationId, `cm:${r.id}`);
    Object.assign(r, newProblemRt(this.problem(r.id)), { phase: 'active' });
    this.applyProblemEffect(r);
    this.toast(`“${name}” is back. The fix was never standardized — Sustain is the hardest S.`, 'bad');
  }

  // ── Save / load ──────────────────────────────────────────────────────────
  toSave(): SiteSave {
    return {
      time: this.flow.time,
      day: this.flow.day,
      shippedTotal: this.flow.shippedTotal,
      releaseMode: this.flow.releaseMode,
      conwipLimit: this.flow.conwipLimit,
      problems: [...this.problems.values()].map((r) => structuredClone(r)),
      missions: [...this.missions.values()].map((m) => ({ ...m })),
      observed: [...this.observed],
      found: [...this.found],
      trust: [...this.trust.entries()],
      history: [...this.history],
    };
  }

  /** Restore saved state. Unknown ids (content changed since saving) are ignored. */
  load(s: SiteSave): void {
    this.flow.time = s.time;
    this.flow.day = s.day;
    this.flow.shippedTotal = s.shippedTotal;
    this.flow.releaseMode = s.releaseMode;
    this.flow.conwipLimit = s.conwipLimit;
    for (const saved of s.problems) {
      const r = this.problems.get(saved.id);
      if (!r) continue;
      Object.assign(r, saved, { stationId: r.stationId });
      if (OPEN_PHASES.includes(r.phase)) this.applyProblemEffect(r);
      if (r.a3 && r.eff >= CHECK_PASS && r.phase !== 'spotted') {
        const cm = this.catalog.countermeasures.find((c) => c.id === r.a3?.cmId);
        if (cm) this.flow.setModifier(r.stationId, `cm:${r.id}`, stationBonus(cm, r.eff));
      }
    }
    for (const m of s.missions) {
      const rt = this.missions.get(m.id);
      if (rt) Object.assign(rt, m);
    }
    s.observed.forEach((o) => this.observed.add(o));
    s.found.forEach((f) => this.found.add(f));
    s.trust.forEach(([k, v]) => this.trust.set(k, v));
    this.history.splice(0, this.history.length, ...s.history);
    this.refreshMissions();
    this.events = [];
  }
}

export interface SiteSave {
  time: number;
  day: number;
  shippedTotal: number;
  releaseMode: 'push' | 'conwip';
  conwipLimit: number;
  problems: ProblemRt[];
  missions: MissionRt[];
  observed: string[];
  found: string[];
  trust: [string, number][];
  history: DaySummary[];
}

function newProblemRt(p: Problem): ProblemRt {
  return {
    id: p.id, phase: 'dormant', stationId: stationForProblem(p.zoneId, p.stationId),
    toolsUsed: [], blamed: false, a3: null, eff: 0, level: null, tried: [], failedChecks: 0,
    checkAt: 0, baseline: null, standardized: false, recurAt: null, score: null,
  };
}

export const newProfile = (): Profile => ({ credits: 500, xp: 0, concepts: [], resolved: 0 });
export const siteByTier = (tier: number): Site => SITES.find((s) => s.tier === tier) ?? SITES[0];
