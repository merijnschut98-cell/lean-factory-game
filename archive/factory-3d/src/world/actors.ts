// NPCs: team leaders and office staff you can talk to, plus ambient walkers
// (a material handler doing milk runs, a maintenance tech answering andon calls).
import * as THREE from 'three';
import { CSS2DObject } from 'three/examples/jsm/renderers/CSS2DRenderer.js';
import type { SiteGame } from '../sim/game';
import { Character, randomLook, type Look } from './character';
import type { Layout, NpcPlace } from './layout';
import type { NavGrid } from './navgrid';
import { PALETTE } from './materials';

const ROLE_LOOK: Record<string, Partial<Look>> = {
  'Team Leader': { shirt: '#2f6fb0', vest: PALETTE.safetyYellow, helmet: '#f4f4f4' },
  'Lean Coach': { shirt: '#7a3b8f', glasses: true },
  Scheduler: { shirt: '#c27c2c' },
  'Quality Lead': { shirt: '#3c8d4f', glasses: true },
  'IT Engineer': { shirt: '#5a4fa8' },
  Controller: { shirt: '#2a7f7a' },
  'HR Manager': { shirt: '#c0583c' },
  'Maintenance Lead': { shirt: '#6a5a2c', vest: PALETTE.safetyOrange, helmet: '#2f6fb0' },
};

export const ROLE_COLOR: Record<string, string> = {
  'Team Leader': '#2f6fb0', 'Lean Coach': '#7a3b8f', Scheduler: '#c27c2c', 'Quality Lead': '#3c8d4f',
  'IT Engineer': '#5a4fa8', Controller: '#2a7f7a', 'HR Manager': '#c0583c', 'Maintenance Lead': '#8a6a1c',
};

export interface Npc {
  place: NpcPlace;
  char: Character;
  badge: HTMLDivElement;
}

/** Simple path follower shared by ambient walkers. */
class Walker {
  path: { x: number; z: number }[] = [];
  wait = 0;
  constructor(readonly char: Character, private speed: number) {}
  get idle(): boolean {
    return this.path.length === 0 && this.wait <= 0;
  }
  update(dt: number): void {
    const r = this.char.root;
    if (this.wait > 0) {
      this.wait -= dt;
      this.char.update(dt, 0);
      return;
    }
    const target = this.path[0];
    if (!target) {
      this.char.update(dt, 0);
      return;
    }
    const dx = target.x - r.position.x, dz = target.z - r.position.z;
    const d = Math.hypot(dx, dz);
    if (d < 0.15) {
      this.path.shift();
      this.char.update(dt, 0);
      return;
    }
    const step = Math.min(d, this.speed * dt);
    r.position.x += (dx / d) * step;
    r.position.z += (dz / d) * step;
    const yaw = Math.atan2(dx, dz);
    let diff = yaw - r.rotation.y;
    diff = Math.atan2(Math.sin(diff), Math.cos(diff));
    r.rotation.y += diff * Math.min(1, dt * 10);
    this.char.update(dt, this.speed);
  }
}

export class Actors {
  readonly root = new THREE.Group();
  readonly npcs: Npc[] = [];
  private readonly handler: Walker;
  private readonly tech: Walker;
  private techTarget: string | null = null;
  private handlerLeg = 0;

  constructor(private layout: Layout, private nav: NavGrid, private game: SiteGame) {
    layout.npcs.forEach((p, i) => {
      const char = new Character(randomLook(1000 + i * 13, ROLE_LOOK[p.role] ?? {}));
      char.root.position.set(p.x, 0, p.z);
      char.root.rotation.y = p.facing;
      this.root.add(char.root);
      const badge = document.createElement('div');
      badge.className = 'npc-tag';
      badge.innerHTML = `<b>${p.name}</b><small>${p.role}</small><i class="npc-alert"></i>`;
      badge.style.setProperty('--role', ROLE_COLOR[p.role] ?? '#555');
      const obj = new CSS2DObject(badge);
      obj.position.set(0, 2.25, 0);
      char.root.add(obj);
      this.npcs.push({ place: p, char, badge });
    });

    const handlerChar = new Character(randomLook(77, { shirt: '#3a6d4a', vest: PALETTE.safetyYellow, helmet: PALETTE.safetyYellow }));
    handlerChar.setProp('box');
    handlerChar.setPose('carry');
    this.handler = new Walker(handlerChar, 2.0);
    const techChar = new Character(randomLook(91, { shirt: '#4a4a4a', vest: PALETTE.safetyOrange, helmet: '#2f6fb0' }));
    this.tech = new Walker(techChar, 3.2);
    const maint = layout.npcs.find((n) => n.role === 'Maintenance Lead');
    for (const [w, at] of [[this.handler, layout.stations[0].interact], [this.tech, maint ?? layout.spawn]] as const) {
      w.char.root.position.set(at.x, 0, at.z + 1.5);
      this.root.add(w.char.root);
    }
  }

  setGame(g: SiteGame): void {
    this.game = g;
  }

  /** Does this NPC have something new for the player? (mission offered) */
  private hasNews(n: NpcPlace): boolean {
    return this.game.missionsOfferedBy(n.role).some((m) => {
      if (n.role !== 'Team Leader') return true;
      return this.teamLeaderFor(m.id) === n.id;
    });
  }

  /** Which team leader gives a mission: the one in the zone of its first problem. */
  teamLeaderFor(missionId: string): string {
    const first = this.game.mission(missionId).problemIds[0];
    const zone = first ? this.game.problem(first).zoneId : 'z1';
    return `tl_${zone}`;
  }

  update(dt: number, simRunning: boolean, playerPos: THREE.Vector3): void {
    for (const n of this.npcs) {
      const r = n.char.root;
      const d = Math.hypot(playerPos.x - r.position.x, playerPos.z - r.position.z);
      // Turn to face the player when they come close.
      const target = d < 5 ? Math.atan2(playerPos.x - r.position.x, playerPos.z - r.position.z) : n.place.facing;
      let diff = target - r.rotation.y;
      diff = Math.atan2(Math.sin(diff), Math.cos(diff));
      r.rotation.y += diff * Math.min(1, dt * 4);
      n.char.setPose(n.place.room.includes('Obeya') && d > 5 ? 'type' : 'idle');
      n.char.update(dt);
      n.badge.classList.toggle('has-news', this.hasNews(n.place));
    }
    if (!simRunning) {
      this.handler.char.update(dt, 0);
      this.tech.char.update(dt, 0);
      return;
    }
    this.updateHandler(dt);
    this.updateTech(dt);
  }

  /** Milk run: the material handler loops along the station aisle side. */
  private updateHandler(dt: number): void {
    if (this.handler.idle) {
      const sts = this.layout.stations;
      this.handlerLeg = (this.handlerLeg + 3) % sts.length;
      const t = sts[this.handlerLeg].interact;
      this.handler.path = this.nav.findPath(this.handler.char.root.position, { x: t.x + 2, z: t.z }) ?? [];
      this.handler.wait = 1.5;
    }
    this.handler.update(dt);
  }

  /** Maintenance tech walks to the first station that is down. */
  private updateTech(dt: number): void {
    const down = this.game.flow.stations.find((s) => s.state === 'down');
    const want = down?.def.id ?? null;
    if (want !== this.techTarget) {
      this.techTarget = want;
      const place = want ? this.layout.stations.find((p) => p.def.id === want) : null;
      const home = this.layout.npcs.find((n) => n.role === 'Maintenance Lead');
      const to = place ? { x: place.x + place.dir * 2.5, z: place.z + 3.4 } : home ? { x: home.x + 1.5, z: home.z } : null;
      if (to) this.tech.path = this.nav.findPath(this.tech.char.root.position, to) ?? [];
    }
    const arrived = this.tech.path.length === 0;
    this.tech.char.setPose(arrived ? (this.techTarget ? 'work' : 'idle') : 'run');
    this.tech.update(dt);
  }
}
