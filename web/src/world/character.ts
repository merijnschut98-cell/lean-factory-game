// Procedural low-poly characters with a code-driven skeleton.
// Every limb hangs from a pivot group so animations are just rotations.
// Swappable later for rigged glTF models without changing callers.
import * as THREE from 'three';
import { mat } from './materials';

export type Pose = 'idle' | 'walk' | 'run' | 'work' | 'wave' | 'carry' | 'observe' | 'type';

export interface Look {
  skin: string;
  hair: string;
  hairStyle: 'short' | 'bun' | 'long' | 'bald' | 'cap';
  shirt: string;
  pants: string;
  /** Hard hat colour, or null for office staff. */
  helmet: string | null;
  vest: string | null;
  clipboard?: boolean;
  glasses?: boolean;
  height?: number;
}

const SKINS = ['#f1d0b5', '#e0b48f', '#c68d63', '#a26a45', '#7a4b2f', '#f5dcc8'];
const HAIRS = ['#2b1d14', '#5a3a22', '#a8743c', '#d9b26a', '#1c1c1c', '#8a8a8a', '#7b2f1e'];
const STYLES: Look['hairStyle'][] = ['short', 'bun', 'long', 'short', 'bald'];

/** Deterministic random look from a seed (so an NPC always looks the same). */
export function randomLook(seed: number, base: Partial<Look> = {}): Look {
  let s = seed * 9301 + 49297;
  const r = () => ((s = (s * 9301 + 49297) % 233280) / 233280);
  const pick = <T>(a: T[]) => a[Math.floor(r() * a.length)];
  return {
    skin: pick(SKINS),
    hair: pick(HAIRS),
    hairStyle: pick(STYLES),
    shirt: '#3d5a80',
    pants: pick(['#2e3440', '#3b3f46', '#4a4e57', '#2c3e50']),
    helmet: null,
    vest: null,
    height: 0.94 + r() * 0.12,
    ...base,
  };
}

const limbGeo = new THREE.CapsuleGeometry(0.075, 0.36, 4, 10);
const legGeo = new THREE.CapsuleGeometry(0.09, 0.42, 4, 10);
const torsoGeo = new THREE.CapsuleGeometry(0.2, 0.32, 4, 14);
const headGeo = new THREE.SphereGeometry(0.21, 20, 16);
const hatGeo = new THREE.SphereGeometry(0.235, 18, 10, 0, Math.PI * 2, 0, Math.PI / 2);
const brimGeo = new THREE.CylinderGeometry(0.27, 0.27, 0.025, 20);
const eyeGeo = new THREE.SphereGeometry(0.028, 8, 6);
const handGeo = new THREE.SphereGeometry(0.06, 10, 8);
const shoeGeo = new THREE.BoxGeometry(0.13, 0.08, 0.24);

function mesh(geo: THREE.BufferGeometry, m: THREE.Material, parent: THREE.Object3D, x = 0, y = 0, z = 0) {
  const o = new THREE.Mesh(geo, m);
  o.position.set(x, y, z);
  o.castShadow = true;
  parent.add(o);
  return o;
}

export class Character {
  readonly root = new THREE.Group();
  private readonly body = new THREE.Group();
  private readonly head = new THREE.Group();
  private readonly armL = new THREE.Group();
  private readonly armR = new THREE.Group();
  private readonly legL = new THREE.Group();
  private readonly legR = new THREE.Group();
  private readonly prop = new THREE.Group();
  pose: Pose = 'idle';
  private phase = Math.random() * 10;
  private blend = 0;

  constructor(readonly look: Look) {
    const skin = mat(look.skin, { rough: 0.6 });
    const shirt = mat(look.shirt);
    const pants = mat(look.pants);
    const dark = mat('#222428');
    const k = look.height ?? 1;
    this.root.scale.setScalar(k);
    this.root.add(this.body);

    // Legs pivot at the hips.
    for (const [leg, x] of [[this.legL, -0.1], [this.legR, 0.1]] as const) {
      leg.position.set(x, 0.62, 0);
      mesh(legGeo, pants, leg, 0, -0.29, 0);
      mesh(shoeGeo, dark, leg, 0, -0.58, 0.04);
      this.body.add(leg);
    }
    // Torso + optional hi-vis vest with reflective stripes.
    mesh(torsoGeo, shirt, this.body, 0, 0.94, 0).scale.set(1, 1, 0.75);
    if (look.vest) {
      const vest = mesh(torsoGeo, mat(look.vest, { rough: 0.5 }), this.body, 0, 0.93, 0);
      vest.scale.set(1.06, 0.82, 0.8);
      const stripe = mat('#e8e8e8', { rough: 0.2, metal: 0.6 });
      for (const y of [0.86, 0.98]) {
        const s = new THREE.Mesh(new THREE.TorusGeometry(0.205, 0.012, 4, 24), stripe);
        s.rotation.x = Math.PI / 2;
        s.scale.set(1.04, 0.8, 1);
        s.position.y = y;
        this.body.add(s);
      }
    }
    // Arms pivot at the shoulders.
    for (const [arm, x] of [[this.armL, -0.27], [this.armR, 0.27]] as const) {
      arm.position.set(x, 1.15, 0);
      mesh(limbGeo, shirt, arm, 0, -0.22, 0);
      mesh(handGeo, skin, arm, 0, -0.47, 0);
      this.body.add(arm);
    }
    // Head.
    this.head.position.set(0, 1.42, 0);
    this.body.add(this.head);
    mesh(headGeo, skin, this.head, 0, 0, 0);
    for (const x of [-0.075, 0.075]) mesh(eyeGeo, dark, this.head, x, 0.02, 0.19);
    if (look.glasses) {
      const g = new THREE.Mesh(new THREE.BoxGeometry(0.26, 0.05, 0.02), mat('#9fd3e6', { rough: 0.1, metal: 0.3 }));
      g.position.set(0, 0.03, 0.205);
      this.head.add(g);
    }
    this.addHair(look, mat(look.hair, { rough: 0.9 }));
    if (look.helmet) {
      const hm = mat(look.helmet, { rough: 0.35 });
      mesh(hatGeo, hm, this.head, 0, 0.04, 0);
      mesh(brimGeo, hm, this.head, 0, 0.05, 0.03);
    }
    // Props live in the right hand.
    this.armR.add(this.prop);
    this.prop.position.set(0, -0.48, 0.08);
    if (look.clipboard) this.setProp('clipboard');
  }

  private addHair(look: Look, hm: THREE.Material): void {
    if (look.hairStyle === 'bald' || look.helmet) {
      if (look.hairStyle === 'long' && look.helmet) mesh(new THREE.BoxGeometry(0.3, 0.22, 0.08), hm, this.head, 0, -0.08, -0.17);
      return;
    }
    const cap = mesh(new THREE.SphereGeometry(0.225, 18, 10, 0, Math.PI * 2, 0, Math.PI / 1.9), hm, this.head, 0, 0.02, -0.01);
    cap.rotation.x = -0.25;
    if (look.hairStyle === 'bun') mesh(new THREE.SphereGeometry(0.09, 10, 8), hm, this.head, 0, 0.12, -0.2);
    if (look.hairStyle === 'long') mesh(new THREE.BoxGeometry(0.36, 0.34, 0.1), hm, this.head, 0, -0.1, -0.16);
    if (look.hairStyle === 'cap') {
      const c = mesh(brimGeo, mat('#c0392b'), this.head, 0, 0.12, 0.12);
      c.scale.set(0.7, 1, 0.7);
    }
  }

  setProp(kind: 'none' | 'clipboard' | 'box' | 'tablet'): void {
    this.prop.clear();
    if (kind === 'clipboard') {
      const b = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.3, 0.02), mat('#8a5a32'));
      const paper = new THREE.Mesh(new THREE.BoxGeometry(0.19, 0.25, 0.005), mat('#fafafa'));
      paper.position.z = 0.013;
      b.add(paper);
      b.rotation.x = -1.1;
      this.prop.add(b);
    } else if (kind === 'box') {
      const b = new THREE.Mesh(new THREE.BoxGeometry(0.4, 0.3, 0.35), mat('#c9a26b'));
      b.position.set(-0.27, 0.05, 0.2);
      b.castShadow = true;
      this.prop.add(b);
    } else if (kind === 'tablet') {
      const t = new THREE.Mesh(new THREE.BoxGeometry(0.24, 0.17, 0.015), mat('#222', { emissive: '#4aa3df', ei: 0.4 }));
      t.rotation.x = -1.0;
      this.prop.add(t);
    }
  }

  /** Advance the animation. `speed` is the movement speed in m/s (for stride). */
  update(dt: number, speed = 0): void {
    const p = this.pose;
    const moving = p === 'walk' || p === 'run' || (p === 'carry' && speed > 0.1);
    const rate = moving ? 1.6 + speed * 1.15 : p === 'work' || p === 'type' ? 6 : p === 'wave' ? 7 : 1.4;
    this.phase += dt * rate;
    this.blend = Math.min(1, this.blend + dt * 6);
    const s = Math.sin(this.phase);
    const swing = p === 'run' ? 0.95 : 0.6;

    let armL = 0, armR = 0, armLz = 0, armRz = 0, legL = 0, legR = 0, bob = 0, lean = 0, headY = 0, headX = 0;
    if (moving) {
      legL = s * swing;
      legR = -s * swing;
      armL = -s * swing * 0.8;
      armR = s * swing * 0.8;
      bob = Math.abs(Math.cos(this.phase)) * (p === 'run' ? 0.08 : 0.04);
      lean = p === 'run' ? 0.15 : 0.04;
    } else {
      bob = Math.sin(this.phase * 0.8) * 0.008;
      headY = Math.sin(this.phase * 0.35) * 0.25;
    }
    if (p === 'work') {
      armL = -1.15 + Math.sin(this.phase) * 0.18;
      armR = -1.2 + Math.sin(this.phase + 2) * 0.22;
      armLz = 0.25;
      armRz = -0.25;
      lean = 0.18;
      headX = 0.35;
      headY = Math.sin(this.phase * 0.2) * 0.1;
    } else if (p === 'type') {
      armL = -1.0 + Math.sin(this.phase * 1.7) * 0.06;
      armR = -1.0 + Math.cos(this.phase * 1.9) * 0.06;
      armLz = 0.2;
      armRz = -0.2;
      headX = 0.15;
    } else if (p === 'wave') {
      armR = -2.6;
      armRz = -0.3 + Math.sin(this.phase) * 0.45;
      headX = -0.2;
    } else if (p === 'carry') {
      armL = -1.25;
      armR = -1.25;
      armLz = 0.35;
      armRz = -0.35;
    } else if (p === 'observe') {
      armR = -1.05;
      armRz = -0.1;
      armL = -0.4;
      headX = 0.25;
      headY = Math.sin(this.phase * 0.5) * 0.5;
    }
    const k = this.blend;
    const lerp = (o: THREE.Object3D, axis: 'x' | 'y' | 'z', v: number) => {
      o.rotation[axis] += (v - o.rotation[axis]) * Math.min(1, k * 0.35 + 0.15);
    };
    lerp(this.armL, 'x', armL);
    lerp(this.armR, 'x', armR);
    lerp(this.armL, 'z', armLz);
    lerp(this.armR, 'z', armRz);
    lerp(this.legL, 'x', legL);
    lerp(this.legR, 'x', legR);
    lerp(this.body, 'x', lean);
    lerp(this.head, 'y', headY);
    lerp(this.head, 'x', headX);
    this.body.position.y = bob;
  }

  setPose(p: Pose): void {
    if (p !== this.pose) {
      this.pose = p;
      this.blend = 0;
    }
  }
}
