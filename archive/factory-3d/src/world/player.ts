// The player: third-person walker driven by WASD (camera-relative) or
// click-to-move along an A* path. Collision comes from the nav grid.
import * as THREE from 'three';
import { Character, type Pose } from './character';
import type { NavGrid } from './navgrid';

const WALK = 4.2;
const RUN = 8.5;

export class Player {
  readonly char: Character;
  private path: { x: number; z: number }[] = [];
  private onArrive: (() => void) | null = null;
  /** Locked while performing a gemba action (observing, timing...). */
  busyPose: Pose | null = null;
  speed = 0;

  constructor(private nav: NavGrid, spawn: { x: number; z: number }) {
    this.char = new Character({
      skin: '#e8c4a0', hair: '#3b2a1e', hairStyle: 'short', shirt: '#1f3b5c', pants: '#2b2f36',
      helmet: '#ffffff', vest: '#3fb3e8', glasses: true, clipboard: true, height: 1.02,
    });
    this.char.root.position.set(spawn.x, 0, spawn.z);
  }

  get pos(): THREE.Vector3 {
    return this.char.root.position;
  }

  teleport(x: number, z: number): void {
    this.char.root.position.set(x, 0, z);
    this.path = [];
  }

  /** Walk to a point; optional callback on arrival. Returns false if unreachable. */
  goTo(x: number, z: number, onArrive?: () => void): boolean {
    const path = this.nav.findPath(this.pos, { x, z });
    if (!path) return false;
    this.path = path.slice(1);
    this.onArrive = onArrive ?? null;
    return true;
  }

  cancelPath(): void {
    this.path = [];
    this.onArrive = null;
  }

  faceTowards(x: number, z: number): void {
    this.char.root.rotation.y = Math.atan2(x - this.pos.x, z - this.pos.z);
  }

  /** `input` is a camera-relative move vector (x right, z forward), length ≤ 1. */
  update(dt: number, input: { x: number; z: number }, running: boolean, cameraYaw: number): void {
    if (this.busyPose) {
      this.char.setPose(this.busyPose);
      this.char.update(dt, 0);
      this.speed = 0;
      return;
    }
    const v = new THREE.Vector2(input.x, input.z);
    let dx = 0, dz = 0;
    const maxSpeed = running ? RUN : WALK;
    if (v.lengthSq() > 0.01) {
      this.cancelPath();
      // Forward = away from the camera.
      const s = Math.sin(cameraYaw), c = Math.cos(cameraYaw);
      dx = (input.x * c - input.z * s) * maxSpeed;
      dz = (-input.x * s - input.z * c) * maxSpeed;
    } else if (this.path.length) {
      const t = this.path[0];
      const ddx = t.x - this.pos.x, ddz = t.z - this.pos.z;
      const d = Math.hypot(ddx, ddz);
      if (d < 0.25) {
        this.path.shift();
        if (!this.path.length && this.onArrive) {
          const cb = this.onArrive;
          this.onArrive = null;
          cb();
        }
      } else {
        dx = (ddx / d) * maxSpeed;
        dz = (ddz / d) * maxSpeed;
      }
    }
    const p = this.pos;
    const nx = p.x + dx * dt, nz = p.z + dz * dt;
    // Slide along obstacles: try each axis separately.
    if (this.nav.walkable(nx, p.z)) p.x = nx;
    if (this.nav.walkable(p.x, nz)) p.z = nz;
    this.speed = Math.hypot(dx, dz);
    if (this.speed > 0.1) {
      const yaw = Math.atan2(dx, dz);
      let diff = yaw - this.char.root.rotation.y;
      diff = Math.atan2(Math.sin(diff), Math.cos(diff));
      this.char.root.rotation.y += diff * Math.min(1, dt * 12);
    }
    this.char.setPose(this.speed > 6 ? 'run' : this.speed > 0.1 ? 'walk' : 'idle');
    this.char.update(dt, this.speed);
  }
}
