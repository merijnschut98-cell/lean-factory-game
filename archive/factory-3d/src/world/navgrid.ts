// Walkability grid + A* for click-to-move and NPC routing.
import type { Rect } from './layout';

const CELL = 0.5;
const SQRT2 = Math.SQRT2;

export class NavGrid {
  readonly w: number;
  readonly h: number;
  private readonly blocked: Uint8Array;

  constructor(readonly bounds: Rect, obstacles: Rect[], inflate = 0.45) {
    this.w = Math.ceil((bounds.x1 - bounds.x0) / CELL);
    this.h = Math.ceil((bounds.z1 - bounds.z0) / CELL);
    this.blocked = new Uint8Array(this.w * this.h);
    for (const o of obstacles) this.block(o, inflate);
  }

  block(o: Rect, inflate = 0.45): void {
    const [cx0, cz0] = this.cell(o.x0 - inflate, o.z0 - inflate);
    const [cx1, cz1] = this.cell(o.x1 + inflate, o.z1 + inflate);
    for (let z = Math.max(0, cz0); z <= Math.min(this.h - 1, cz1); z++) {
      for (let x = Math.max(0, cx0); x <= Math.min(this.w - 1, cx1); x++) this.blocked[z * this.w + x] = 1;
    }
  }

  cell(x: number, z: number): [number, number] {
    return [Math.floor((x - this.bounds.x0) / CELL), Math.floor((z - this.bounds.z0) / CELL)];
  }

  center(cx: number, cz: number): { x: number; z: number } {
    return { x: this.bounds.x0 + (cx + 0.5) * CELL, z: this.bounds.z0 + (cz + 0.5) * CELL };
  }

  walkableCell(cx: number, cz: number): boolean {
    return cx >= 0 && cz >= 0 && cx < this.w && cz < this.h && this.blocked[cz * this.w + cx] === 0;
  }

  walkable(x: number, z: number): boolean {
    const [cx, cz] = this.cell(x, z);
    return this.walkableCell(cx, cz);
  }

  /** Nearest walkable cell centre to a point (spiral search). */
  nearestWalkable(x: number, z: number): { x: number; z: number } | null {
    const [cx, cz] = this.cell(x, z);
    for (let r = 0; r < 40; r++) {
      for (let dz = -r; dz <= r; dz++) {
        for (let dx = -r; dx <= r; dx++) {
          if (Math.max(Math.abs(dx), Math.abs(dz)) !== r) continue;
          if (this.walkableCell(cx + dx, cz + dz)) return this.center(cx + dx, cz + dz);
        }
      }
    }
    return null;
  }

  /** A* path between two world points (8-connected, smoothed). Null if unreachable. */
  findPath(from: { x: number; z: number }, to: { x: number; z: number }): { x: number; z: number }[] | null {
    const start = this.nearestWalkable(from.x, from.z);
    const goal = this.nearestWalkable(to.x, to.z);
    if (!start || !goal) return null;
    const [sx, sz] = this.cell(start.x, start.z);
    const [gx, gz] = this.cell(goal.x, goal.z);
    const N = this.w * this.h;
    const g = new Float32Array(N).fill(Infinity);
    const parent = new Int32Array(N).fill(-1);
    const closed = new Uint8Array(N);
    const heap = new MinHeap();
    const si = sz * this.w + sx;
    const gi = gz * this.w + gx;
    const hfn = (x: number, z: number) => {
      const dx = Math.abs(x - gx), dz = Math.abs(z - gz);
      return Math.max(dx, dz) + (SQRT2 - 1) * Math.min(dx, dz);
    };
    g[si] = 0;
    heap.push(si, hfn(sx, sz));
    while (heap.size) {
      const cur = heap.pop();
      if (cur === gi) break;
      if (closed[cur]) continue;
      closed[cur] = 1;
      const cx = cur % this.w, cz = (cur / this.w) | 0;
      for (let dz = -1; dz <= 1; dz++) {
        for (let dx = -1; dx <= 1; dx++) {
          if (!dx && !dz) continue;
          const nx = cx + dx, nz = cz + dz;
          if (!this.walkableCell(nx, nz)) continue;
          // No corner cutting.
          if (dx && dz && (!this.walkableCell(cx + dx, cz) || !this.walkableCell(cx, cz + dz))) continue;
          const ni = nz * this.w + nx;
          const ng = g[cur] + (dx && dz ? SQRT2 : 1);
          if (ng < g[ni]) {
            g[ni] = ng;
            parent[ni] = cur;
            heap.push(ni, ng + hfn(nx, nz));
          }
        }
      }
    }
    if (parent[gi] === -1 && gi !== si) return null;
    const cells: number[] = [];
    for (let c = gi; c !== -1; c = parent[c]) cells.push(c);
    cells.reverse();
    const pts = cells.map((c) => this.center(c % this.w, (c / this.w) | 0));
    pts[pts.length - 1] = goal;
    return this.smooth(pts);
  }

  /** Remove waypoints that have line of sight past them (string pulling). */
  private smooth(pts: { x: number; z: number }[]): { x: number; z: number }[] {
    if (pts.length < 3) return pts;
    const out = [pts[0]];
    let anchor = 0;
    for (let i = 2; i < pts.length; i++) {
      if (!this.lineClear(pts[anchor], pts[i])) {
        out.push(pts[i - 1]);
        anchor = i - 1;
      }
    }
    out.push(pts[pts.length - 1]);
    return out;
  }

  lineClear(a: { x: number; z: number }, b: { x: number; z: number }): boolean {
    const d = Math.hypot(b.x - a.x, b.z - a.z);
    const n = Math.ceil(d / (CELL * 0.5));
    for (let i = 1; i < n; i++) {
      const t = i / n;
      if (!this.walkable(a.x + (b.x - a.x) * t, a.z + (b.z - a.z) * t)) return false;
    }
    return true;
  }
}

class MinHeap {
  private ids: number[] = [];
  private keys: number[] = [];
  get size(): number {
    return this.ids.length;
  }
  push(id: number, key: number): void {
    this.ids.push(id);
    this.keys.push(key);
    let i = this.ids.length - 1;
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (this.keys[p] <= key) break;
      this.swap(i, p);
      i = p;
    }
  }
  pop(): number {
    const top = this.ids[0];
    const lastId = this.ids.pop() as number;
    const lastKey = this.keys.pop() as number;
    if (this.ids.length) {
      this.ids[0] = lastId;
      this.keys[0] = lastKey;
      let i = 0;
      for (;;) {
        const l = 2 * i + 1, r = l + 1;
        let m = i;
        if (l < this.ids.length && this.keys[l] < this.keys[m]) m = l;
        if (r < this.ids.length && this.keys[r] < this.keys[m]) m = r;
        if (m === i) break;
        this.swap(i, m);
        i = m;
      }
    }
    return top;
  }
  private swap(a: number, b: number): void {
    [this.ids[a], this.ids[b]] = [this.ids[b], this.ids[a]];
    [this.keys[a], this.keys[b]] = [this.keys[b], this.keys[a]];
  }
}
