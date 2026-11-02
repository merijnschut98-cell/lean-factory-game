/** Small seeded PRNG (mulberry32) so simulations are reproducible in tests. */
export class Rng {
  private s: number;
  constructor(seed = 1) {
    this.s = seed >>> 0;
  }
  next(): number {
    this.s = (this.s + 0x6d2b79f5) >>> 0;
    let t = this.s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
  /** Exponentially distributed sample with the given mean. */
  exp(mean: number): number {
    return -Math.log(1 - this.next()) * mean;
  }
  /** Uniform in [mean·(1−spread), mean·(1+spread)]. */
  around(mean: number, spread: number): number {
    return mean * (1 + spread * (this.next() * 2 - 1));
  }
  pick<T>(items: readonly T[]): T {
    return items[Math.floor(this.next() * items.length)];
  }
}
