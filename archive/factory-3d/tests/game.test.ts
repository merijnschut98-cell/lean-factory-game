import { describe, expect, it } from 'vitest';
import { SiteGame, newProfile, siteByTier, type ProblemRt } from '../src/sim/game';
import { SHIFT_SECONDS } from '../src/sim/line';
import { causeOptions, expectedMetric, STATION_TOOLS } from '../src/sim/investigation';
import { effectiveness, scorePdca } from '../src/sim/pdca';
import { parseSave, SAVE_VERSION } from '../src/sim/save';
import { beltIndex } from '../src/sim/progression';
import { loadRealCatalog } from './content.test';

const catalog = loadRealCatalog();
const newGame = () => new SiteGame(catalog, siteByTier(1), newProfile());

function firstActive(g: SiteGame): ProblemRt {
  g.acceptMission('M-T1-001');
  return [...g.problems.values()].find((r) => r.phase === 'active')!;
}

/** Investigate like a good player: every tool and open question until nothing new appears. */
function investigate(g: SiteGame, id: string) {
  const st = g.rt(id).stationId;
  for (let round = 0; round < 5; round++) {
    for (const t of STATION_TOOLS) g.useTool(st, t);
    g.ask(st, 'walk');
    g.ask(st, 'obstacle');
  }
}

function rightCm(g: SiteGame, id: string) {
  const p = g.problem(id);
  return g.availableCountermeasures().find((c) => p.effectiveCountermeasures.includes(c.name) && c.tier <= g.maturity)!;
}

/** Drive one problem through the whole loop the way an expert would. */
function solve(g: SiteGame, id: string, standardize = true) {
  investigate(g, id);
  const p = g.problem(id);
  const keys = g.clues.get(id)!.filter((c) => c.key && g.found.has(c.id)).map((c) => c.id);
  const res = g.submitA3(id, {
    waste: p.waste, cause: causeOptions(p, g.siteProblems()).correct, evidence: keys, cmId: rightCm(g, id).id, prediction: expectedMetric(p),
  });
  expect(res).toEqual({ ok: true });
  g.advance(SHIFT_SECONDS / 4 + 10);
  expect(g.check(id)?.passed).toBe(true);
  return g.act(id, standardize)!;
}

describe('missions', () => {
  it('first mission is offered by its NPC, accepting it activates problems (max 3)', () => {
    const g = newGame();
    expect(g.missionsOfferedBy('Team Leader').map((m) => m.id)).toContain('M-T1-001');
    g.acceptMission('M-T1-001');
    const open = [...g.problems.values()].filter((r) => r.phase === 'active');
    expect(open.length).toBeGreaterThan(0);
    expect(open.length).toBeLessThanOrEqual(3);
  });

  it('active problems degrade their station', () => {
    const g = newGame();
    const before = g.flow.station('coil_winding')!.perf;
    g.acceptMission('M-T1-001');
    expect(g.flow.station('coil_winding')!.perf).toBeLessThan(before);
  });
});

describe('investigation', () => {
  it('tools reveal clues only after the problem is spotted, and only one "why" deeper per use', () => {
    const g = newGame();
    const r = g.rt('T1-003'); // has investigation + two 5 Whys steps
    r.phase = 'active';
    const st = r.stationId;
    const clues = g.clues.get('T1-003')!;
    const deep = clues.filter((c) => c.key && c.depth === 2)[0];
    expect(deep).toBeDefined();
    for (const t of STATION_TOOLS) g.useTool(st, t);
    expect(g.found.has(deep.id)).toBe(false);
    investigate(g, 'T1-003');
    expect(clues.filter((c) => c.key).every((c) => g.found.has(c.id))).toBe(true);
  });

  it('a quick look misses hidden problems; a deep tool finds them', () => {
    const g = newGame();
    const hidden = g.siteProblems().find((p) => p.visibility === 'hidden')!;
    const r = g.rt(hidden.id);
    r.phase = 'active';
    expect(g.useTool(r.stationId, 'observe').spotted).not.toContain(hidden.id);
    expect(g.hasHiddenSignal(r.stationId)).toBe(true);
    expect(g.useTool(r.stationId, 'time').spotted).toContain(hidden.id);
  });

  it('closed questions teach nothing; blaming questions shut the operator down until repaired', () => {
    const g = newGame();
    const r = g.rt('T1-001');
    r.phase = 'spotted';
    const st = r.stationId;
    expect(g.ask(st, 'standard').clue).toBeNull();
    g.ask(st, 'behind');
    expect(g.trustAt(st)).toBe(-1);
    expect(g.ask(st, 'walk').reply).toMatch(/not opening up/);
    g.ask(st, 'thanks');
    expect(g.trustAt(st)).toBe(0);
    expect(g.rt('T1-001').blamed).toBe(true);
  });

  it('every tier-1 problem has at least one key clue reachable by its tools', () => {
    const g = newGame();
    const none = g.siteProblems().filter((p) => !g.clues.get(p.id)!.some((c) => c.key && c.depth === 0));
    expect(none.map((p) => p.id)).toEqual([]);
  });

  it('the A3 refuses a plan without evidence', () => {
    const g = newGame();
    const r = firstActive(g);
    g.useTool(r.stationId, 'observe');
    const res = g.submitA3(r.id, { waste: 'waiting', cause: 0, evidence: [], cmId: rightCm(g, r.id).id, prediction: 'cycle' });
    expect(res.ok).toBe(false);
  });
});

describe('PDCA loop', () => {
  it('an expert run resolves the problem with a top score and pays out', () => {
    const g = newGame();
    const r = firstActive(g);
    // Scout a neighbour in the zone too.
    const zone = g.flow.station(r.stationId)!.def.zoneId;
    const neighbour = g.flow.stations.find((s) => s.def.zoneId === zone && s.def.id !== r.stationId)!;
    g.useTool(neighbour.def.id, 'observe');
    const score = solve(g, r.id);
    expect(g.rt(r.id).phase).toBe('resolved');
    expect(score.rootCause).toBeGreaterThanOrEqual(4);
    expect(score.total).toBeGreaterThanOrEqual(16);
    expect(g.profile.xp).toBeGreaterThan(0);
    expect(g.profile.concepts).toContain('A3');
  });

  it('a mismatched countermeasure fails Check and sends you back to the gemba', () => {
    const g = newGame();
    const r = firstActive(g);
    investigate(g, r.id);
    const p = g.problem(r.id);
    const wrong = g.availableCountermeasures().find((c) => !p.effectiveCountermeasures.includes(c.name))!;
    const ev = g.foundClues().map((c) => c.id);
    g.submitA3(r.id, { waste: 'waiting', cause: 0, evidence: ev, cmId: wrong.id, prediction: 'cycle' });
    g.advance(SHIFT_SECONDS / 4 + 10);
    const res = g.check(r.id)!;
    expect(res.passed).toBe(false);
    expect(g.rt(r.id).phase).toBe('spotted');
    expect(g.rt(r.id).tried).toContain(wrong.id);
  });

  it('a lucky fix with the wrong root cause passes Check but scores low on root cause', () => {
    const g = newGame();
    const r = firstActive(g);
    investigate(g, r.id);
    const p = g.problem(r.id);
    const correct = causeOptions(p, g.siteProblems()).correct;
    g.submitA3(r.id, { waste: p.waste, cause: (correct + 1) % 5, evidence: [g.foundClues()[0].id], cmId: rightCm(g, r.id).id, prediction: 'flow' });
    g.advance(SHIFT_SECONDS / 4 + 10);
    const res = g.check(r.id)!;
    expect(res.passed).toBe(true);
    expect(res.causeCorrect).toBe(false);
    expect(g.act(r.id, true)!.rootCause).toBe(1);
  });

  it('an unstandardized fix with decay comes back', () => {
    const g = newGame();
    g.acceptMission('M-T1-001');
    const r = g.rt('T1-001');
    r.phase = 'active';
    investigate(g, 'T1-001');
    const fiveS = catalog.countermeasures.find((c) => c.name === '5S System')!;
    g.submitA3('T1-001', { waste: 'inventory', cause: 0, evidence: g.foundClues().map((c) => c.id), cmId: fiveS.id, prediction: 'cycle' });
    g.advance(SHIFT_SECONDS / 4 + 10);
    g.check('T1-001');
    g.act('T1-001', false);
    expect(g.rt('T1-001').recurAt).not.toBeNull();
    g.advance(12 * SHIFT_SECONDS);
    expect(g.rt('T1-001').phase).toBe('active');
  });
});

describe('effectiveness and score', () => {
  const p = catalog.problems.find((x) => x.id === 'T1-001')!;
  const byName = (n: string) => catalog.countermeasures.find((c) => c.name === n)!;
  it('full for the right tool at the right maturity, mismatch otherwise', () => {
    expect(effectiveness(p, byName('5S System'), 1).level).toBe('full');
    expect(effectiveness(p, catalog.countermeasures.find((c) => c.tier === 3)!, 1).level).toBe('mismatch');
  });
  it('scores range 6..25', () => {
    const best = scorePdca({ keyFound: 2, keyTotal: 2, scoutedZone: true, blamed: false, causeCorrect: true, keyLinked: 2,
      herringsLinked: 0, eff: 0.8, failedChecks: 0, predictionRight: true, standardized: true,
      wasteRight: true, capacityGain: 0.05, atConstraint: true, constraintName: 'Burn-In' });
    const worst = scorePdca({ keyFound: 0, keyTotal: 3, scoutedZone: false, blamed: true, causeCorrect: false, keyLinked: 0,
      herringsLinked: 4, eff: 0.1, failedChecks: 3, predictionRight: false, standardized: false,
      wasteRight: false, capacityGain: 0, atConstraint: false, constraintName: 'Burn-In' });
    expect(best.total).toBe(25);
    expect(worst.total).toBeLessThanOrEqual(6);
    expect(worst.notes.join(' ')).toMatch(/Burn-In/);
    expect(worst.notes.length).toBeGreaterThan(3);
  });
  it('cause options are stable and contain the real root cause once', () => {
    const a = causeOptions(p, catalog.problems);
    expect(a.options.filter((o) => o === p.rootCause)).toHaveLength(1);
    expect(causeOptions(p, catalog.problems)).toEqual(a);
    expect(a.options.length).toBe(5);
  });
});

describe('save / load', () => {
  it('round-trips a site through JSON', () => {
    const g = newGame();
    const r = firstActive(g);
    solve(g, r.id);
    g.ask(r.stationId, 'behind');
    const text = JSON.stringify({ v: SAVE_VERSION, currentTier: 1, profile: g.profile, sites: { 1: g.toSave() } });
    const save = parseSave(text)!;
    expect(save.sites['1']).toBeDefined();
    const g2 = new SiteGame(catalog, siteByTier(1), save.profile);
    g2.load(save.sites['1']);
    expect(g2.rt(r.id).phase).toBe('resolved');
    expect(g2.found.size).toBe(g.found.size);
    expect(g2.trustAt(r.stationId)).toBe(-1);
    expect(g2.flow.day).toBe(g.flow.day);
  });

  it('rejects corrupt saves without throwing', () => {
    expect(parseSave('{nope')).toBeNull();
    expect(parseSave(JSON.stringify({ v: 99 }))).toBeNull();
    expect(parseSave(JSON.stringify({ v: SAVE_VERSION, currentTier: 1, profile: { credits: 'x' }, sites: {} }))).toBeNull();
    expect(parseSave(null)).toBeNull();
  });

  it('drops individual corrupt site entries', () => {
    const s = parseSave(JSON.stringify({ v: SAVE_VERSION, currentTier: 1, profile: newProfile(), sites: { 1: { time: -5 } } }));
    expect(s?.sites).toEqual({});
  });
});

describe('belts', () => {
  it('maps xp to belts', () => {
    expect(beltIndex(0)).toBe(0);
    expect(beltIndex(1200)).toBe(1);
    expect(beltIndex(99999)).toBe(4);
  });
});

describe('content solvability', () => {
  it('every problem has a fitting countermeasure the site can apply at full effect', () => {
    const unsolvable = catalog.problems.filter((p) => !catalog.countermeasures.some(
      (c) => c.tier >= 1 && c.tier <= p.tier && p.effectiveCountermeasures.some((n) => n.toLowerCase() === c.name.toLowerCase()),
    )).map((p) => p.id);
    expect(unsolvable).toEqual([]);
  });
});

describe('value chain and bottleneck', () => {
  it('line capacity is set by the constraint, and only improving the constraint raises it', () => {
    const g = newGame();
    const { perShift, constraint } = g.flow.lineCapacity();
    expect(constraint.def.id).toBe('burn_in');
    const other = g.flow.station('deck_cutting')!;
    other.mods.set('x', { avail: 0.05, perf: 0.05, quality: 0 });
    expect(g.flow.lineCapacity().perShift).toBeCloseTo(perShift, 6);
    constraint.mods.set('x', { avail: 0.05, perf: 0.05, quality: 0 });
    expect(g.flow.lineCapacity().perShift).toBeGreaterThan(perShift);
  });

  it('scrap downstream of the bottleneck costs line output', () => {
    const g = newGame();
    const before = g.flow.lineCapacity().perShift;
    g.flow.setModifier('final_qa', 'x', { avail: 0, perf: 0, quality: -0.1 });
    expect(g.flow.lineCapacity().perShift).toBeLessThan(before);
  });

  it('stacked problems can move the bottleneck', () => {
    const g = newGame();
    expect(g.flow.bottleneck.def.id).toBe('burn_in');
    g.acceptMission('M-T1-001');
    expect(g.flow.bottleneck.def.id).toBe('coil_winding');
  });

  it('fixing a non-bottleneck scores low on flow impact and says why', () => {
    const g = newGame();
    g.acceptMission('M-T1-001');
    const constraint = g.flow.bottleneck.def.id;
    const r = [...g.problems.values()].find((x) => x.phase === 'active' && x.stationId !== constraint)!;
    const score = solve(g, r.id);
    expect(score.impact).toBeLessThanOrEqual(2);
    expect(score.notes.join(' ')).toMatch(/non-bottleneck|ships nothing/);
  });

  it('naming the wrong waste costs root-cause points', () => {
    const g = newGame();
    const r = firstActive(g);
    investigate(g, r.id);
    const p = g.problem(r.id);
    const keys = g.clues.get(r.id)!.filter((c) => c.key && g.found.has(c.id)).map((c) => c.id);
    g.submitA3(r.id, { waste: p.waste === 'motion' ? 'transport' : 'motion', cause: causeOptions(p, g.siteProblems()).correct,
      evidence: keys, cmId: rightCm(g, r.id).id, prediction: expectedMetric(p) });
    g.advance(SHIFT_SECONDS / 4 + 10);
    expect(g.check(r.id)!.wasteRight).toBe(false);
    expect(g.act(r.id, true)!.notes.join(' ')).toMatch(/waste/i);
  });
});
