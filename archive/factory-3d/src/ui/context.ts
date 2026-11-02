// What every panel needs from the running app.
import type { SiteGame } from '../sim/game';
import type { World } from '../world/world';
import type { Modals } from './modal';

export interface Ctx {
  game: SiteGame;
  world: World;
  modals: Modals;
  /** Spend simulated minutes doing something (with an animation), then continue. */
  spendTime(minutes: number, label: string, done: () => void): void;
  /** Show a floor beacon at a station and guide the player there. */
  guideTo(stationId: string | null): void;
  toast(text: string, tone?: 'info' | 'good' | 'warn' | 'bad'): void;
  save(): void;
  /** Re-render HUD bits that depend on game state. */
  refresh(): void;
}
