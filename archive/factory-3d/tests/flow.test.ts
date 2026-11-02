import { describe, expect, it } from 'vitest';
import { FlowSim, WIP_CEILING } from '../src/sim/flow';
import { DEMAND_PER_SHIFT, SHIFT_SECONDS } from '../src/sim/line';

function runDays(sim: FlowSim, days: number) {
  const out: number[] = [];
  sim.onDayEnd = (s) => out.push(s.shipped);
  sim.advance(days * SHIFT_SECONDS);
  return out;
}

describe('FlowSim baseline', () => {
  it('ships below demand at start, limited by the bottleneck', () => {
    const sim = new FlowSim(3);
    const shipped = runDays(sim, 3);
    const avg = shipped.reduce((a, b) => a + b, 0) / shipped.length;
    expect(avg).toBeGreaterThan(DEMAND_PER_SHIFT * 0.5);
    expect(avg).toBeLessThan(DEMAND_PER_SHIFT);
    expect(sim.bottleneck.def.id).toBe('burn_in');
  });

  it('piles WIP up in front of the bottleneck', () => {
    const sim = new FlowSim(5);
    sim.advance(2 * SHIFT_SECONDS);
    const bn = sim.bottleneck;
    const others = sim.stations.filter((s) => s !== bn).map((s) => s.queue.length);
    expect(bn.queue.length).toBeGreaterThan(Math.max(...others.slice(bn.index)));
  });

  it('never releases beyond the WIP ceiling', () => {
    const sim = new FlowSim(1);
    sim.setModifier('burn_in', 'test', { avail: -0.6, perf: -0.6, quality: 0 });
    sim.advance(10 * SHIFT_SECONDS);
    expect(sim.wip).toBeLessThanOrEqual(WIP_CEILING + sim.stations.length);
  });

  it('is deterministic for a given seed', () => {
    const a = new FlowSim(42), b = new FlowSim(42);
    a.advance(SHIFT_SECONDS);
    b.advance(SHIFT_SECONDS);
    expect(a.shippedToday + a.wip).toBe(b.shippedToday + b.wip);
    expect(a.shippedTotal).toBe(b.shippedTotal);
  });
});

describe('FlowSim modifiers', () => {
  it('a quality problem creates scrap; removing it recovers', () => {
    const sim = new FlowSim(9);
    sim.setModifier('integration_3', 'p', { avail: 0, perf: 0, quality: -0.2 });
    sim.advance(SHIFT_SECONDS * 0.9);
    expect(sim.station('integration_3')!.scrapToday).toBeGreaterThan(2);
    sim.clearModifier('integration_3', 'p');
    expect(sim.station('integration_3')!.quality).toBeCloseTo(0.985);
  });

  it('improving the bottleneck raises output', () => {
    const base = new FlowSim(11);
    const better = new FlowSim(11);
    better.setModifier('burn_in', 'cm', { avail: 0.05, perf: 0.08, quality: 0 });
    const b = runDays(base, 3).reduce((x, y) => x + y, 0);
    const g = runDays(better, 3).reduce((x, y) => x + y, 0);
    expect(g).toBeGreaterThan(b);
  });

  it('a WIP cap blocks the upstream station', () => {
    const sim = new FlowSim(2);
    sim.stations[16].wipCap = 1;
    sim.setModifier('flight_test', 'slow', { avail: -0.4, perf: -0.4, quality: 0 });
    sim.advance(SHIFT_SECONDS);
    expect(sim.stations[15].share.blocked).toBeGreaterThan(0.05);
  });
});

describe('FlowSim release modes', () => {
  it('CONWIP caps WIP and cuts lead time without losing much output (Little\'s law)', () => {
    const push = new FlowSim(4);
    const pull = new FlowSim(4);
    pull.releaseMode = 'conwip';
    pull.conwipLimit = 28;
    const a = runDays(push, 4).slice(1).reduce((x, y) => x + y, 0);
    const b = runDays(pull, 4).slice(1).reduce((x, y) => x + y, 0);
    expect(pull.wip).toBeLessThanOrEqual(28);
    expect(pull.avgLeadTime).toBeLessThan(push.avgLeadTime);
    expect(b).toBeGreaterThan(a * 0.85);
  });
});
