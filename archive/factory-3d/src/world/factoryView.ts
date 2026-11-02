// Draws the live line: stations, conveyors, WIP stacks, units in transit,
// scrap bins and operators — all read from the SiteGame every frame.
import * as THREE from 'three';
import { CSS2DObject } from 'three/examples/jsm/renderers/CSS2DRenderer.js';
import type { SiteGame } from '../sim/game';
import { ZONES } from '../sim/line';
import type { StationState } from '../sim/flow';
import { Character, randomLook, type Pose } from './character';
import type { Layout, StationPlace, V3 } from './layout';
import { box, cyl, GEO, mat, PALETTE, UNIT_MATS } from './materials';
import { buildStation, type StationModel } from './stations';

const MAX_STACK = 24;
const SCRAP_SHOWN = 6;
/** Conveyor speed in metres per simulated second. */
export const CONVEYOR_SPEED = 0.12;

interface PathCache {
  pts: V3[];
  cum: number[];
  total: number;
}

function cachePath(pts: V3[]): PathCache {
  const cum = [0];
  for (let i = 1; i < pts.length; i++) {
    cum.push(cum[i - 1] + Math.hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y, pts[i].z - pts[i - 1].z));
  }
  return { pts, cum, total: cum[cum.length - 1] };
}

function sample(p: PathCache, t: number, out: THREE.Vector3): THREE.Vector3 {
  const d = Math.max(0, Math.min(1, t)) * p.total;
  let i = 1;
  while (i < p.cum.length - 1 && p.cum[i] < d) i++;
  const a = p.pts[i - 1], b = p.pts[i];
  const seg = p.cum[i] - p.cum[i - 1];
  const k = seg > 0 ? (d - p.cum[i - 1]) / seg : 0;
  return out.set(a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k, a.z + (b.z - a.z) * k);
}

interface StationView {
  place: StationPlace;
  model: StationModel;
  stack: THREE.Mesh[];
  stackLabel: HTMLDivElement;
  inProcess: THREE.Mesh;
  scrap: THREE.Mesh[];
  operators: Character[];
  marker: HTMLDivElement;
  state: StationState | null;
  root: THREE.Group;
}

/** Product look by stage: boxes early on, hoverboard decks later. */
function unitMesh(stationIndex: number, zoneIdx: number): THREE.Mesh {
  const deck = stationIndex >= 10 && zoneIdx < 5;
  const m = new THREE.Mesh(deck ? GEO.deck : GEO.unit, UNIT_MATS[zoneIdx] ?? UNIT_MATS[0]);
  m.castShadow = true;
  return m;
}

function buildConveyor(parent: THREE.Object3D, pts: V3[]): void {
  const belt = mat('#3b4045', { rough: 0.6 });
  const rail = mat(PALETTE.steel, { metal: 0.6, rough: 0.4 });
  const post = mat('#5b646b', { metal: 0.5 });
  const a = new THREE.Vector3(), b = new THREE.Vector3(), dir = new THREE.Vector3();
  for (let i = 1; i < pts.length; i++) {
    a.set(pts[i - 1].x, pts[i - 1].y - 0.25, pts[i - 1].z);
    b.set(pts[i].x, pts[i].y - 0.25, pts[i].z);
    dir.subVectors(b, a);
    const len = dir.length();
    if (len < 0.01) continue;
    const seg = new THREE.Group();
    seg.position.copy(a).add(b).multiplyScalar(0.5);
    seg.quaternion.setFromUnitVectors(new THREE.Vector3(1, 0, 0), dir.clone().normalize());
    parent.add(seg);
    box(seg, len + 0.6, 0.12, 0.75, 0, 0, 0, belt, false);
    box(seg, len + 0.6, 0.12, 0.06, 0, 0.1, 0.4, rail, false);
    box(seg, len + 0.6, 0.12, 0.06, 0, 0.1, -0.4, rail, false);
    // Support posts every few metres under overhead runs.
    const steps = Math.floor(len / 4);
    for (let k = 1; k <= steps; k++) {
      const t = k / (steps + 1);
      const x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t, z = a.z + (b.z - a.z) * t;
      if (y > 1.5) cyl(parent, 0.05, y, x, y / 2, z, post).castShadow = false;
    }
  }
}

export class FactoryView {
  readonly root = new THREE.Group();
  readonly views: StationView[] = [];
  private readonly paths: PathCache[];
  private readonly transitPool: THREE.Mesh[] = [];
  private readonly tmp = new THREE.Vector3();
  private time = 0;

  constructor(readonly layout: Layout, private game: SiteGame) {
    this.paths = layout.paths.map(cachePath);
    for (const p of layout.paths) buildConveyor(this.root, p);
    for (const place of layout.stations) this.views.push(this.buildStationView(place));
  }

  /** Simulated-second transit times derived from conveyor lengths. */
  transitTimes(): number[] {
    return this.paths.map((p) => Math.max(40, p.total / CONVEYOR_SPEED));
  }

  setGame(g: SiteGame): void {
    this.game = g;
  }

  private buildStationView(place: StationPlace): StationView {
    const zoneIdx = ZONES.findIndex((z) => z.id === place.def.zoneId);
    const zone = ZONES[zoneIdx];
    const root = new THREE.Group();
    root.position.set(place.x, 0, place.z);
    this.root.add(root);
    const model = buildStation(place.def.kind, zone.color);
    root.add(model.group);

    // Input WIP pallet + stack pool (world-space children of the station root).
    const bx = place.buffer.x - place.x, bz = place.buffer.z - place.z;
    box(root, 1.3, 0.14, 1.3, bx, 0.07, bz, mat(PALETTE.wood, { rough: 0.9 }));
    const stack: THREE.Mesh[] = [];
    for (let i = 0; i < MAX_STACK; i++) {
      const m = unitMesh(place.index, zoneIdx);
      const layer = Math.floor(i / 4), slot = i % 4;
      const isDeck = m.geometry === GEO.deck;
      const h = isDeck ? 0.17 : 0.43;
      m.position.set(bx + ((slot % 2) - 0.5) * 0.55, 0.14 + h / 2 + layer * h, bz + (Math.floor(slot / 2) - 0.5) * (isDeck ? 0.36 : 0.55));
      m.visible = false;
      root.add(m);
      stack.push(m);
    }
    const stackLabel = document.createElement('div');
    stackLabel.className = 'wip-tag';
    const stackObj = new CSS2DObject(stackLabel);
    stackObj.position.set(bx, 2.6, bz);
    root.add(stackObj);

    const inProcess = unitMesh(place.index, zoneIdx);
    inProcess.position.copy(model.workPoint);
    inProcess.visible = false;
    model.group.add(inProcess);

    // Scrap bin: red tub with reject crates inside.
    const sx = place.scrap.x - place.x, sz = place.scrap.z - place.z;
    const bin = mat(PALETTE.red, { rough: 0.6 });
    box(root, 0.9, 0.05, 0.9, sx, 0.03, sz, bin);
    for (const [dx, dz, w, d] of [[0, -0.43, 0.9, 0.05], [0, 0.43, 0.9, 0.05], [-0.43, 0, 0.05, 0.9], [0.43, 0, 0.05, 0.9]]) {
      box(root, w, 0.6, d, sx + dx, 0.3, sz + dz, bin);
    }
    const scrap: THREE.Mesh[] = [];
    for (let i = 0; i < SCRAP_SHOWN; i++) {
      const m = new THREE.Mesh(GEO.unit, mat('#7a3b2e'));
      m.scale.setScalar(0.6);
      m.position.set(sx + ((i % 2) - 0.5) * 0.35, 0.18 + Math.floor(i / 2) * 0.26, sz + ((i % 3) - 1) * 0.18);
      m.rotation.y = i * 0.7;
      m.visible = false;
      root.add(m);
      scrap.push(m);
    }

    // Operators face the station from the aisle side.
    const operators = place.operatorSpots.map((spot, i) => {
      const c = new Character(randomLook(place.index * 7 + i * 3 + 1, {
        shirt: '#45627d', vest: PALETTE.safetyOrange, helmet: PALETTE.safetyYellow,
      }));
      c.root.position.set(spot.x - place.x, 0, spot.z - place.z);
      c.root.rotation.y = Math.PI;
      root.add(c.root);
      return c;
    });

    // Floating marker for known problems.
    const marker = document.createElement('div');
    marker.className = 'station-marker';
    const markerObj = new CSS2DObject(marker);
    markerObj.position.set(0, 4.6, 0);
    root.add(markerObj);

    const nameTag = document.createElement('div');
    nameTag.className = 'station-name';
    nameTag.innerHTML = `<span style="background:${zone.color}"></span>${place.def.name}`;
    const nameObj = new CSS2DObject(nameTag);
    nameObj.position.set(0, 3.7, 0);
    root.add(nameObj);

    return { place, model, stack, stackLabel, inProcess, scrap, operators, marker, state: null, root };
  }

  /** Per-frame update. `dt` real seconds. */
  update(dt: number, simRunning: boolean): void {
    this.time += dt;
    const flow = this.game.flow;
    for (const v of this.views) {
      const st = flow.stations[v.place.index];
      if (st.state !== v.state) {
        v.state = st.state;
        v.model.setState(st.state);
      }
      const working = st.state === 'working' && simRunning;
      v.model.animate(this.time, working);
      const n = st.queue.length;
      v.stack.forEach((m, i) => (m.visible = i < n));
      v.stackLabel.textContent = n > 0 ? `${n}` : '';
      v.stackLabel.classList.toggle('high', n >= 8);
      v.inProcess.visible = !!st.current;
      const shownScrap = Math.min(SCRAP_SHOWN, st.scrapToday);
      v.scrap.forEach((m, i) => (m.visible = i < shownScrap));
      const pose: Pose = st.state === 'working' ? 'work' : st.state === 'down' ? 'wave' : 'idle';
      for (const op of v.operators) {
        op.setPose(simRunning ? pose : 'idle');
        op.update(dt);
      }
      this.updateMarker(v);
    }
    this.updateTransits();
  }

  private updateMarker(v: StationView): void {
    const open = this.game.openAt(v.place.def.id).filter((r) => r.phase !== 'active');
    let cls = '', text = '';
    if (open.some((r) => r.phase === 'checkReady')) [cls, text] = ['check', 'CHECK'];
    else if (open.some((r) => r.phase === 'spotted')) [cls, text] = ['problem', '!'];
    else if (open.some((r) => r.phase === 'doing')) [cls, text] = ['doing', 'PDCA'];
    if (v.marker.dataset.k !== cls) {
      v.marker.dataset.k = cls;
      v.marker.className = `station-marker ${cls}`;
      v.marker.textContent = text;
    }
  }

  private updateTransits(): void {
    const transits = this.game.flow.transits;
    while (this.transitPool.length < transits.length) {
      const m = new THREE.Mesh(GEO.unit, UNIT_MATS[0]);
      m.castShadow = true;
      this.root.add(m);
      this.transitPool.push(m);
    }
    this.transitPool.forEach((m, i) => {
      const tr = transits[i];
      m.visible = !!tr;
      if (!tr) return;
      const zoneIdx = ZONES.findIndex((z) => z.id === this.game.flow.stations[tr.from].def.zoneId);
      const deck = tr.from >= 9 && tr.from < 18;
      m.geometry = deck ? GEO.deck : GEO.unit;
      m.material = UNIT_MATS[Math.min(5, zoneIdx + (tr.from === 18 ? 1 : 0))];
      sample(this.paths[tr.from], tr.t / tr.dur, this.tmp);
      m.position.set(this.tmp.x, this.tmp.y + (deck ? 0.1 : 0.2), this.tmp.z);
    });
  }
}
