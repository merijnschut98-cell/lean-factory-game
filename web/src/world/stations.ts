// Procedural station models — one builder per station kind. Each returns a
// group plus hooks the factory view drives: an andon stack light, moving parts
// and the spot where the unit-in-process sits.
import * as THREE from 'three';
import type { StationKind } from '../sim/line';
import type { StationState } from '../sim/flow';
import { box, cyl, GEO, mat, PALETTE } from './materials';

export interface StationModel {
  group: THREE.Group;
  /** Local position of the unit being worked on. */
  workPoint: THREE.Vector3;
  setState(state: StationState): void;
  animate(t: number, working: boolean): void;
}

const ANDON: Record<StationState, string> = {
  working: '#3fd16a',
  starved: '#f2c230',
  blocked: '#f08a24',
  down: '#ff3b30',
};

const lampOff = mat('#3a3d40', { rough: 0.4 });
const lampMats = Object.fromEntries(
  Object.entries(ANDON).map(([k, c]) => [k, mat(c, { emissive: c, ei: 1.6, rough: 0.3 })]),
) as Record<StationState, THREE.MeshStandardMaterial>;

/** A three-segment andon stack light (red / amber / green) on a pole. */
function andonTower(parent: THREE.Object3D, x: number, z: number, h: number) {
  cyl(parent, 0.04, h, x, h / 2, z, mat(PALETTE.darkSteel, { metal: 0.6, rough: 0.4 }));
  const lamps = (['down', 'blocked', 'working'] as StationState[]).map((s, i) => {
    const m = cyl(parent, 0.11, 0.18, x, h + 0.1 + (2 - i) * 0.19, z, lampOff);
    m.userData.state = s;
    return m;
  });
  cyl(parent, 0.12, 0.05, x, h + 0.68, z, mat(PALETTE.darkSteel));
  return (state: StationState) => {
    const key = state === 'starved' ? 'blocked' : state;
    for (const l of lamps) {
      l.material = l.userData.state === key ? lampMats[state] : lampOff;
    }
  };
}

function table(g: THREE.Group, w: number, d: number, h = 0.95, top = mat('#d9d4c6')) {
  box(g, w, 0.08, d, 0, h, 0, top);
  const leg = mat(PALETTE.steel, { metal: 0.5, rough: 0.45 });
  for (const [x, z] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) box(g, 0.08, h, 0.08, (x * (w - 0.2)) / 2, h / 2, (z * (d - 0.2)) / 2, leg);
}

type Builder = (g: THREE.Group, accent: string) => { work: THREE.Vector3; anim?: (t: number, on: boolean) => void };

const builders: Record<StationKind, Builder> = {
  dock: (g, accent) => {
    // Receiving bay: pallet racking + staging table + a parked pallet jack.
    const rack = mat(accent, { metal: 0.3, rough: 0.5 });
    for (const x of [-3.4, -1.2]) {
      for (const z of [-2, 2]) box(g, 0.1, 3, 0.1, x, 1.5, z, rack);
    }
    for (const y of [0.15, 1.4, 2.6]) {
      box(g, 2.4, 0.08, 4.2, -2.3, y, 0, mat('#6b6f74', { metal: 0.4 }));
      for (const z of [-1.2, 0, 1.2]) box(g, 0.9, 0.7, 0.9, -2.3, y + 0.4, z, mat(PALETTE.cardboard));
    }
    table(g, 3, 1.6);
    box(g, 0.8, 0.12, 0.6, 2.6, 0.06, 1.5, mat(PALETTE.safetyOrange));
    return { work: new THREE.Vector3(0, 1.2, 0) };
  },
  inspection: (g) => {
    table(g, 4.4, 1.8);
    box(g, 0.7, 0.45, 0.05, 1.4, 1.35, -0.6, mat('#1d1f22', { emissive: '#3b8fd9', ei: 0.35 }));
    box(g, 0.08, 0.35, 0.08, 1.4, 1.1, -0.6, mat(PALETTE.darkSteel));
    const arm = cyl(g, 0.03, 0.8, -1.2, 1.4, -0.5, mat(PALETTE.steel, { metal: 0.6 }));
    arm.rotation.z = 0.5;
    const lamp = new THREE.Mesh(new THREE.TorusGeometry(0.18, 0.05, 8, 20), mat('#e8e6df', { emissive: '#fff6d8', ei: 0.6 }));
    lamp.rotation.x = Math.PI / 2;
    lamp.position.set(-0.95, 1.8, -0.3);
    g.add(lamp);
    box(g, 1.2, 0.5, 0.8, -1.5, 1.24, 0.3, mat('#5a8f4e'));
    return { work: new THREE.Vector3(0, 1.22, 0.1) };
  },
  machine: (g, accent) => {
    // Winding / placement machine: enclosure with window and spinning head.
    box(g, 3.6, 2.2, 2.6, 0, 1.1, -0.6, mat(PALETTE.machine, { rough: 0.5 }));
    box(g, 3.62, 0.25, 2.62, 0, 2.3, -0.6, mat(accent, { rough: 0.45 }));
    box(g, 2.2, 1.0, 0.04, 0, 1.45, 0.71, mat(PALETTE.glass, { rough: 0.05, metal: 0.2 }));
    const head = new THREE.Group();
    head.position.set(0, 1.45, 0.1);
    g.add(head);
    cyl(head, 0.32, 0.3, 0, 0, 0, mat('#c47a2c', { metal: 0.7, rough: 0.3 })).rotation.x = Math.PI / 2;
    box(head, 0.7, 0.06, 0.06, 0, 0, 0.18, mat(PALETTE.darkSteel));
    box(g, 0.6, 0.9, 0.3, 2.2, 1.3, 0.5, mat('#2c3036')).rotation.y = -0.4;
    box(g, 0.45, 0.3, 0.02, 2.15, 1.5, 0.66, mat('#111', { emissive: '#4ad97a', ei: 0.5 })).rotation.y = -0.4;
    table(g, 2.2, 1.2, 0.9);
    g.children[g.children.length - 1].position.set(0, 0, 1.6);
    box(g, 2.2, 0.08, 1.2, 0, 0.9, 1.6, mat('#d9d4c6'));
    return {
      work: new THREE.Vector3(0, 1.15, 1.6),
      anim: (t, on) => {
        if (on) head.rotation.z = t * 9;
      },
    };
  },
  cnc: (g, accent) => {
    box(g, 4.2, 2.4, 3, 0, 1.2, -0.4, mat('#dfe3e6', { rough: 0.45 }));
    box(g, 4.22, 0.3, 3.02, 0, 0.15, -0.4, mat(PALETTE.darkSteel));
    const door = box(g, 1.8, 1.3, 0.05, -0.6, 1.4, 1.12, mat(PALETTE.glass, { rough: 0.05, metal: 0.3 }));
    box(g, 0.9, 1.6, 0.4, 1.7, 1.4, 1.0, mat(accent));
    box(g, 0.6, 0.4, 0.02, 1.7, 1.75, 1.21, mat('#111', { emissive: '#d9a24a', ei: 0.5 }));
    const spindle = cyl(g, 0.12, 0.6, -0.6, 2.0, 0.2, mat('#aaa', { metal: 0.9, rough: 0.2 }));
    return {
      work: new THREE.Vector3(-0.6, 1.0, 1.6),
      anim: (t, on) => {
        spindle.position.x = -0.6 + (on ? Math.sin(t * 1.5) * 0.6 : 0);
        door.position.x = -0.6 + (on ? 0 : 0.9);
      },
    };
  },
  bench: (g, accent) => {
    table(g, 4.4, 1.6);
    // Shadow-board / pegboard behind the bench with tools.
    box(g, 4.4, 1.6, 0.06, 0, 1.9, -0.82, mat('#e6dccb'));
    const tool = mat(accent, { rough: 0.5 });
    for (let i = 0; i < 9; i++) box(g, 0.08, 0.35 + (i % 3) * 0.12, 0.05, -1.8 + i * 0.45, 1.9, -0.77, tool);
    box(g, 0.9, 0.5, 0.6, 1.6, 1.24, -0.2, mat('#3d4a57'));
    return { work: new THREE.Vector3(-0.3, 1.2, 0.1) };
  },
  cell: (g, accent) => {
    // U-shaped assembly cell with a small robot arm in the middle.
    const top = mat('#d2cdc0');
    box(g, 5.6, 0.08, 1.2, 0, 0.95, -1.4, top);
    box(g, 1.2, 0.08, 2.6, -2.2, 0.95, 0.3, top);
    box(g, 1.2, 0.08, 2.6, 2.2, 0.95, 0.3, top);
    const leg = mat(PALETTE.steel, { metal: 0.5 });
    for (const [x, z] of [[-2.7, -1.9], [2.7, -1.9], [-2.7, 1.5], [2.7, 1.5], [-1.7, 1.5], [1.7, 1.5], [0, -1.9]]) box(g, 0.08, 0.95, 0.08, x, 0.47, z, leg);
    const base = cyl(g, 0.35, 0.5, 0, 0.25, -0.4, mat(accent, { rough: 0.4 }));
    base.castShadow = true;
    const arm = new THREE.Group();
    arm.position.set(0, 0.5, -0.4);
    g.add(arm);
    const lower = new THREE.Group();
    arm.add(lower);
    box(lower, 0.22, 1.1, 0.22, 0, 0.55, 0, mat(PALETTE.safetyOrange, { rough: 0.4 }));
    const upper = new THREE.Group();
    upper.position.y = 1.1;
    lower.add(upper);
    box(upper, 0.18, 0.9, 0.18, 0, 0.45, 0, mat(PALETTE.safetyOrange, { rough: 0.4 }));
    box(upper, 0.3, 0.12, 0.3, 0, 0.92, 0, mat(PALETTE.darkSteel));
    for (const [x, z] of [[-2.2, 0], [2.2, 0.5], [-1.2, -1.4]]) box(g, 0.5, 0.3, 0.4, x, 1.14, z, mat('#7d8790', { metal: 0.5 }));
    return {
      work: new THREE.Vector3(0, 1.1, -1.4),
      anim: (t, on) => {
        if (!on) return;
        arm.rotation.y = Math.sin(t * 0.9) * 1.2;
        lower.rotation.x = 0.4 + Math.sin(t * 1.3) * 0.25;
        upper.rotation.x = 0.9 + Math.sin(t * 1.7) * 0.3;
      },
    };
  },
  line: (g, accent) => {
    // Integration station: roller section + fixture + overhead tool balancer.
    box(g, 6.4, 0.75, 1.6, 0, 0.375, 0, mat(PALETTE.darkSteel, { metal: 0.4 }));
    for (let i = 0; i < 14; i++) {
      const r = cyl(g, 0.06, 1.5, -3 + i * 0.46, 0.8, 0, mat('#b8bec4', { metal: 0.8, rough: 0.3 }));
      r.rotation.x = Math.PI / 2;
    }
    box(g, 0.1, 3.2, 0.1, -3, 1.6, -1.1, mat(accent));
    box(g, 0.1, 3.2, 0.1, 3, 1.6, -1.1, mat(accent));
    box(g, 6.2, 0.14, 0.14, 0, 3.2, -1.1, mat(accent));
    const tool = new THREE.Group();
    g.add(tool);
    const cable = cyl(tool, 0.015, 1.4, 0, 2.5, -0.5, mat('#222'));
    box(tool, 0.12, 0.35, 0.12, 0, 1.75, -0.5, mat(PALETTE.safetyYellow));
    box(g, 1.4, 0.2, 0.9, 0, 0.95, 0, mat('#596875'));
    return {
      work: new THREE.Vector3(0, 1.12, 0),
      anim: (t, on) => {
        tool.position.x = on ? Math.sin(t * 0.8) * 0.5 : 0;
        cable.scale.y = 1;
      },
    };
  },
  oven: (g) => {
    // Burn-in: tall rack cabinets with blinking status LEDs.
    const leds: THREE.Mesh[] = [];
    for (const x of [-2.4, -0.8, 0.8, 2.4]) {
      box(g, 1.4, 2.6, 1.6, x, 1.3, -0.6, mat('#3a4048', { rough: 0.5, metal: 0.3 }));
      box(g, 1.2, 2.2, 0.03, x, 1.35, 0.21, mat('#1a1d21', { rough: 0.2 }));
      for (let r = 0; r < 6; r++) {
        const led = box(g, 0.08, 0.08, 0.02, x + 0.45, 0.5 + r * 0.36, 0.23, mat('#3fd16a', { emissive: '#3fd16a', ei: 2 }), false);
        leds.push(led);
      }
    }
    table(g, 2, 1, 0.9);
    g.children[g.children.length - 1].position.set(0, 0, 1.6);
    box(g, 2, 0.08, 1, 0, 0.9, 1.6, mat('#d9d4c6'));
    return {
      work: new THREE.Vector3(0, 1.1, 1.6),
      anim: (t, on) => leds.forEach((l, i) => (l.visible = on ? Math.sin(t * 3 + i * 1.7) > -0.3 : i % 3 === 0)),
    };
  },
  pad: (g, accent) => {
    // Flight test cage: netting posts, a pad, and a hovering test board.
    box(g, 6, 0.06, 4, 0, 0.03, 0, mat('#2f3a44'));
    const ring = new THREE.Mesh(new THREE.RingGeometry(1.0, 1.15, 32), mat(accent, { emissive: accent, ei: 0.6 }));
    ring.rotation.x = -Math.PI / 2;
    ring.position.y = 0.07;
    g.add(ring);
    const post = mat(PALETTE.safetyYellow);
    for (const [x, z] of [[-3, -2], [3, -2], [-3, 2], [3, 2]]) box(g, 0.1, 2.4, 0.1, x, 1.2, z, post);
    const net = new THREE.MeshStandardMaterial({ color: '#cfd6dc', transparent: true, opacity: 0.18, side: THREE.DoubleSide });
    for (const [w, x, z, ry] of [[6, 0, -2, 0], [4, -3, 0, Math.PI / 2], [4, 3, 0, Math.PI / 2]] as const) {
      const m = new THREE.Mesh(new THREE.PlaneGeometry(w, 2.3), net);
      m.position.set(x, 1.2, z);
      m.rotation.y = ry;
      g.add(m);
    }
    const board = new THREE.Mesh(GEO.deck, mat('#29a39a', { emissive: '#1d6b63', ei: 0.4 }));
    board.scale.set(1.6, 1.4, 1.6);
    board.castShadow = true;
    g.add(board);
    return {
      work: new THREE.Vector3(2.2, 0.5, 1.2),
      anim: (t, on) => {
        board.position.set(0, on ? 0.9 + Math.sin(t * 2.4) * 0.25 : 0.12, 0);
        board.rotation.y = on ? t * 0.8 : 0;
      },
    };
  },
  pack: (g) => {
    table(g, 4, 1.8);
    for (const [x, z, h] of [[-1.4, -0.4, 0.5], [-0.8, 0.3, 0.4], [1.5, -0.5, 0.6]]) box(g, 0.7, h, 0.6, x, 1 + h / 2, z, mat('#f5f5f0'));
    // Tape dispenser + stretch wrapper turntable.
    box(g, 0.4, 0.3, 0.2, 0.6, 1.14, 0.5, mat(PALETTE.red));
    const turn = cyl(g, 0.9, 0.12, 2.8, 0.06, 0.6, mat(PALETTE.darkSteel, { metal: 0.5 }));
    box(g, 0.15, 2.2, 0.15, 3.8, 1.1, 0.6, mat(PALETTE.safetyYellow));
    return {
      work: new THREE.Vector3(0, 1.2, 0.2),
      anim: (t, on) => {
        if (on) turn.rotation.y = t * 2;
      },
    };
  },
};

export function buildStation(kind: StationKind, accent: string): StationModel {
  const group = new THREE.Group();
  const { work, anim } = builders[kind](group, accent);
  // Footprint plate with hazard border.
  const plate = new THREE.Mesh(new THREE.PlaneGeometry(8, 5), mat('#c9c2b3', { rough: 0.9 }));
  plate.rotation.x = -Math.PI / 2;
  plate.position.y = 0.012;
  plate.receiveShadow = true;
  group.add(plate);
  const setLamp = andonTower(group, 3.7, -2.2, 2.6);
  return {
    group,
    workPoint: work,
    setState: setLamp,
    animate: (t, working) => anim?.(t, working),
  };
}
