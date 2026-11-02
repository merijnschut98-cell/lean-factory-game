// Unit-level flow simulation of the line. Engine-agnostic: the 3D world only
// *reads* this state (queues, transits, station states) to draw it.
//
// Each station: input queue → process one unit → transit to the next queue.
// Push release at the dock (one kit per takt, like an MRP schedule), so WIP
// physically piles up in front of the slowest station — the lesson is visible.

import { Rng } from './rng';
import { SHIFT_SECONDS, STATIONS, TAKT, type StationDef } from './line';
import type { EffectModifiers } from '../content/types';

export interface Unit {
  id: number;
  born: number;
}

export type StationState = 'working' | 'starved' | 'blocked' | 'down';

export interface Transit {
  unit: Unit;
  from: number;
  /** Index of the destination station, or -1 for shipping. */
  to: number;
  t: number;
  dur: number;
}

export interface DaySummary {
  day: number;
  shipped: number;
  scrapped: number;
  wip: number;
  leadTimeH: number;
  oee: number;
}

const MTTR = 900; // mean repair time, sim seconds
const CYCLE_VARIATION = 0.15;
const DEFAULT_TRANSIT = 45;
/** Circuit breaker: the dock stops releasing when the floor is this full. */
export const WIP_CEILING = 160;
/** Time constant for the rolling state breakdown, sim seconds. */
const EMA_TAU = SHIFT_SECONDS / 2;
const MAX_STEP = 5;

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

export class StationRt {
  readonly queue: Unit[] = [];
  current: Unit | null = null;
  remaining = 0;
  /** Sampled duration of the unit in process (for progress display). */
  duration = 0;
  finished = false;
  downLeft = 0;
  state: StationState = 'starved';
  /** Kanban / standard-WIP limit on this station's input (null = push, unlimited). */
  wipCap: number | null = null;
  readonly mods = new Map<string, EffectModifiers>();
  /** Rolling share of time in each state. */
  readonly share: Record<StationState, number> = { working: 0, starved: 1, blocked: 0, down: 0 };
  madeToday = 0;
  scrapToday = 0;
  breakdownsToday = 0;
  readonly cycleSamples: number[] = [];

  constructor(readonly def: StationDef, readonly index: number) {}

  private total(): EffectModifiers {
    let a = 0, p = 0, q = 0;
    for (const m of this.mods.values()) {
      a += m.avail;
      p += m.perf;
      q += m.quality;
    }
    return { avail: a, perf: p, quality: q };
  }

  get avail(): number {
    return clamp(this.def.avail + this.total().avail, 0.3, 0.995);
  }
  get perf(): number {
    return clamp(this.def.perf + this.total().perf, 0.3, 1.0);
  }
  get quality(): number {
    return clamp(this.def.quality + this.total().quality, 0.5, 0.9995);
  }
  get oee(): number {
    return this.avail * this.perf * this.quality;
  }
  /** Expected seconds per good unit including downtime — compare against takt. */
  get effectiveCt(): number {
    return this.def.ct / (this.avail * this.perf);
  }
  get progress(): number {
    return this.current && this.duration > 0 ? clamp(1 - this.remaining / this.duration, 0, 1) : 0;
  }
}

export class FlowSim {
  readonly stations: StationRt[];
  readonly transits: Transit[] = [];
  time = 0;
  day = 1;
  shippedToday = 0;
  shippedTotal = 0;
  scrapTotal = 0;
  releaseInterval = TAKT;
  /** Push = release on schedule (MRP). CONWIP = release only when WIP drops below the limit. */
  releaseMode: 'push' | 'conwip' = 'push';
  conwipLimit = 30;
  readonly recentLeadTimes: number[] = [];
  onDayEnd: ((s: DaySummary) => void) | null = null;
  onShip: ((u: Unit) => void) | null = null;

  private nextUnitId = 1;
  private releaseTimer = 0;
  private transitTimes: number[];
  private readonly rng: Rng;

  constructor(seed = 7, defs: StationDef[] = STATIONS) {
    this.rng = new Rng(seed);
    this.stations = defs.map((d, i) => new StationRt(d, i));
    this.transitTimes = defs.map(() => DEFAULT_TRANSIT);
    for (const st of this.stations) {
      for (let k = 0; k < st.def.startWip; k++) st.queue.push(this.newUnit(-this.rng.next() * SHIFT_SECONDS));
    }
  }

  private newUnit(born = this.time): Unit {
    return { id: this.nextUnitId++, born };
  }

  /** Walking/conveyor time from station i to i+1, set by the 3D layout. */
  setTransitTimes(times: number[]): void {
    this.transitTimes = this.stations.map((_, i) => times[i] ?? DEFAULT_TRANSIT);
  }

  station(id: string): StationRt | undefined {
    return this.stations.find((s) => s.def.id === id);
  }

  setModifier(stationId: string, source: string, mod: EffectModifiers): void {
    this.station(stationId)?.mods.set(source, mod);
  }

  clearModifier(stationId: string, source: string): void {
    this.station(stationId)?.mods.delete(source);
  }

  get wip(): number {
    let n = this.transits.length;
    for (const s of this.stations) n += s.queue.length + (s.current ? 1 : 0);
    return n;
  }

  get bottleneck(): StationRt {
    return this.lineCapacity().constraint;
  }

  get avgLeadTime(): number {
    const lt = this.recentLeadTimes;
    return lt.length ? lt.reduce((a, b) => a + b, 0) / lt.length : 0;
  }

  /**
   * Theoretical good units per shift for the whole line, and the station that
   * limits it. A station's capacity only counts after the scrap of every step
   * downstream of it — so quality losses after the bottleneck cost real output.
   */
  lineCapacity(): { perShift: number; constraint: StationRt } {
    let best = Infinity;
    let constraint = this.stations[0];
    let downstreamYield = 1;
    for (let i = this.stations.length - 1; i >= 0; i--) {
      const st = this.stations[i];
      downstreamYield *= st.quality;
      const cap = (SHIFT_SECONDS / st.effectiveCt) * downstreamYield;
      if (cap < best) {
        best = cap;
        constraint = st;
      }
    }
    return { perShift: best, constraint };
  }

  /** Rolled throughput yield — chance a unit passes every station first time. */
  get rty(): number {
    return this.stations.reduce((p, s) => p * s.quality, 1);
  }

  get avgOee(): number {
    return this.stations.reduce((a, s) => a + s.oee, 0) / this.stations.length;
  }

  /** Units the plan expected by now in the current shift. */
  get planToNow(): number {
    return Math.floor((this.time % SHIFT_SECONDS) / TAKT);
  }

  private inbound(i: number): number {
    let n = this.stations[i].queue.length;
    for (const t of this.transits) if (t.to === i) n++;
    return n;
  }

  advance(seconds: number): void {
    let left = seconds;
    while (left > 1e-9) {
      const dt = Math.min(MAX_STEP, left);
      this.step(dt);
      left -= dt;
    }
  }

  private step(dt: number): void {
    this.time += dt;
    this.release(dt);
    this.moveTransits(dt);
    for (const st of this.stations) this.stepStation(st, dt);
    const k = 1 - Math.exp(-dt / EMA_TAU);
    for (const st of this.stations) {
      for (const key of Object.keys(st.share) as StationState[]) {
        st.share[key] += ((st.state === key ? 1 : 0) - st.share[key]) * k;
      }
    }
    if (this.time >= this.day * SHIFT_SECONDS) this.endDay();
  }

  private release(dt: number): void {
    if (this.releaseMode === 'conwip') {
      while (this.wip < this.conwipLimit) this.stations[0].queue.push(this.newUnit());
      return;
    }
    this.releaseTimer += dt;
    while (this.releaseTimer >= this.releaseInterval) {
      this.releaseTimer -= this.releaseInterval;
      if (this.wip < WIP_CEILING) this.stations[0].queue.push(this.newUnit());
    }
  }

  private moveTransits(dt: number): void {
    for (let i = this.transits.length - 1; i >= 0; i--) {
      const tr = this.transits[i];
      tr.t += dt;
      if (tr.t < tr.dur) continue;
      this.transits.splice(i, 1);
      if (tr.to < 0) this.ship(tr.unit);
      else this.stations[tr.to].queue.push(tr.unit);
    }
  }

  private ship(u: Unit): void {
    this.shippedToday++;
    this.shippedTotal++;
    this.recentLeadTimes.push(this.time - u.born);
    if (this.recentLeadTimes.length > 20) this.recentLeadTimes.shift();
    this.onShip?.(u);
  }

  private stepStation(st: StationRt, dt: number): void {
    if (st.downLeft > 0) {
      st.downLeft -= dt;
      st.state = 'down';
      return;
    }
    if (st.current && st.finished) {
      this.tryPass(st);
      if (st.current) {
        st.state = 'blocked';
        return;
      }
    }
    if (!st.current) {
      const u = st.queue.shift();
      if (!u) {
        st.state = 'starved';
        return;
      }
      st.current = u;
      st.duration = this.rng.around(st.def.ct / st.perf, CYCLE_VARIATION);
      st.remaining = st.duration;
    }
    st.state = 'working';
    // Breakdowns happen only while running: MTBF chosen so uptime ≈ availability.
    const mtbf = (MTTR * st.avail) / (1 - st.avail);
    if (this.rng.next() < dt / mtbf) {
      st.downLeft = this.rng.exp(MTTR);
      st.breakdownsToday++;
      return;
    }
    st.remaining -= dt;
    if (st.remaining > 0) return;
    st.cycleSamples.push(st.duration);
    if (st.cycleSamples.length > 20) st.cycleSamples.shift();
    if (this.rng.next() > st.quality) {
      st.scrapToday++;
      this.scrapTotal++;
      st.current = null;
      return;
    }
    st.madeToday++;
    st.finished = true;
    this.tryPass(st);
  }

  private tryPass(st: StationRt): void {
    const to = st.index + 1 < this.stations.length ? st.index + 1 : -1;
    if (to >= 0) {
      const cap = this.stations[to].wipCap;
      if (cap !== null && this.inbound(to) >= cap) return;
    }
    this.transits.push({ unit: st.current as Unit, from: st.index, to, t: 0, dur: this.transitTimes[st.index] });
    st.current = null;
    st.finished = false;
  }

  private endDay(): void {
    const summary: DaySummary = {
      day: this.day,
      shipped: this.shippedToday,
      scrapped: this.stations.reduce((a, s) => a + s.scrapToday, 0),
      wip: this.wip,
      leadTimeH: this.avgLeadTime / 3600,
      oee: this.avgOee,
    };
    this.day++;
    this.shippedToday = 0;
    for (const s of this.stations) {
      s.madeToday = 0;
      s.scrapToday = 0;
      s.breakdownsToday = 0;
    }
    this.onDayEnd?.(summary);
  }
}
