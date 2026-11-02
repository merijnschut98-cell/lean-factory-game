import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { buildCatalog, parseProblems } from '../src/content/parse';

const data = (f: string) => readFileSync(new URL(`../../data/${f}`, import.meta.url), 'utf8');

export function loadRealCatalog(warnings: string[] = []) {
  return buildCatalog(
    {
      problems: [1, 2, 3, 4].map((t) => data(`problems_tier${t}.yaml`)),
      missions: [1, 2, 3, 4].map((t) => data(`missions_tier${t}.yaml`)),
      countermeasures: data('countermeasures_v1.yaml'),
      concepts: data('concepts.yaml'),
    },
    (w) => warnings.push(w),
  );
}

describe('content catalog (real YAML)', () => {
  const warnings: string[] = [];
  const cat = loadRealCatalog(warnings);

  it('loads every tier without warnings', () => {
    expect(warnings).toEqual([]);
    expect(cat.problems.filter((p) => p.tier === 1)).toHaveLength(25);
    expect(cat.problems.length).toBeGreaterThanOrEqual(60);
    expect(cat.countermeasures).toHaveLength(79);
    expect(Object.keys(cat.concepts).length).toBeGreaterThanOrEqual(190);
  });

  it('gives every problem a playable investigation fork', () => {
    const missing = cat.problems.filter((p) => !p.investigation).map((p) => p.id);
    expect(missing).toEqual([]);
  });

  it('every effective countermeasure name resolves to a catalog entry', () => {
    const names = new Set(cat.countermeasures.map((c) => c.name.toLowerCase()));
    const dangling = cat.problems.flatMap((p) =>
      p.effectiveCountermeasures.filter((n) => !names.has(n.toLowerCase())).map((n) => `${p.id}: ${n}`),
    );
    expect(dangling).toEqual([]);
  });

  it('missions only reference known problems', () => {
    const ids = new Set(cat.problems.map((p) => p.id));
    for (const m of cat.missions) for (const id of m.problemIds) expect(ids.has(id)).toBe(true);
    expect(cat.missions.filter((m) => m.tier === 1).length).toBeGreaterThan(0);
  });
});

describe('content validation', () => {
  it('skips malformed problems and reports them', () => {
    const warnings: string[] = [];
    const out = parseProblems({ problems: [{ name: 'no id' }, { id: 'X', name: 'ok', zone_id: 'z1' }] }, 1,
      (w) => warnings.push(w));
    expect(out.map((p) => p.id)).toEqual(['X']);
    expect(warnings).toHaveLength(1);
  });

  it('drops a fork with no correct answer', () => {
    const out = parseProblems({ problems: [{ id: 'X', name: 'n', zone_id: 'z1', dialogue: {
      investigation: { prompt: 'p', choices: [{ text: 'a', outcome: 'WRONG' }] } } }] }, 1, () => {});
    expect(out[0].investigation).toBeNull();
  });

  it('reports a missing top-level list', () => {
    const warnings: string[] = [];
    expect(parseProblems({ nope: [] }, 1, (w) => warnings.push(w))).toEqual([]);
    expect(warnings[0]).toMatch(/problems/);
  });
});
