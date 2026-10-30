import { describe, expect, it } from 'vitest';
import { buildLayout, pathLength, pointAt } from '../src/world/layout';
import { NavGrid } from '../src/world/navgrid';

describe('layout', () => {
  for (const scale of [1, 1.15, 1.3, 1.5]) {
    const L = buildLayout(scale);
    it(`places all 19 stations inside the hall without overlap (scale ${scale})`, () => {
      expect(L.stations).toHaveLength(19);
      for (const s of L.stations) {
        expect(s.footprint.x0).toBeGreaterThan(L.hall.x0);
        expect(s.footprint.x1).toBeLessThan(L.hall.x1);
      }
      for (const a of L.stations) for (const b of L.stations) {
        if (a === b) continue;
        const overlap = a.footprint.x0 < b.footprint.x1 && b.footprint.x0 < a.footprint.x1 &&
          a.footprint.z0 < b.footprint.z1 && b.footprint.z0 < a.footprint.z1;
        expect(overlap).toBe(false);
      }
    });

    it(`every station, NPC and the obeya board is reachable from spawn (scale ${scale})`, () => {
      const nav = new NavGrid(L.world, L.obstacles);
      const targets = [...L.stations.map((s) => s.interact), ...L.npcs.map((n) => ({ x: n.x, z: n.z + 1.2 })), ...L.boards];
      const unreachable = targets.filter((t) => !nav.findPath(L.spawn, t));
      expect(unreachable).toEqual([]);
    });
  }

  it('conveyor paths connect consecutive stations', () => {
    const L = buildLayout(1);
    expect(L.paths).toHaveLength(19);
    for (let i = 0; i < 18; i++) {
      const end = L.paths[i][L.paths[i].length - 1];
      expect(end.x).toBeCloseTo(L.stations[i + 1].buffer.x);
      expect(end.z).toBeCloseTo(L.stations[i + 1].buffer.z);
    }
    const p = L.paths[0];
    expect(pointAt(p, 0)).toMatchObject({ x: p[0].x, z: p[0].z });
    expect(pathLength(p)).toBeGreaterThan(5);
  });
});

describe('NavGrid', () => {
  it('routes around an obstacle', () => {
    const nav = new NavGrid({ x0: 0, z0: 0, x1: 20, z1: 20 }, [{ x0: 9, z0: 0, x1: 11, z1: 15 }]);
    const path = nav.findPath({ x: 2, z: 2 }, { x: 18, z: 2 })!;
    expect(path).not.toBeNull();
    expect(Math.max(...path.map((p) => p.z))).toBeGreaterThan(15);
  });
  it('returns null when walled off', () => {
    const nav = new NavGrid({ x0: 0, z0: 0, x1: 20, z1: 20 }, [{ x0: 9, z0: 0, x1: 11, z1: 20 }]);
    expect(nav.findPath({ x: 2, z: 2 }, { x: 18, z: 2 })).toBeNull();
  });
});
