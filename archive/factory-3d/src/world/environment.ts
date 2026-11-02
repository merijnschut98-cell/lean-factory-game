// Static world: sky, ground, building shell, painted floor, offices, yard.
import * as THREE from 'three';
import type { Layout, Rect } from './layout';
import { box, cyl, mat, PALETTE } from './materials';
import type { Site } from '../sim/progression';

export interface Environment {
  /** Wall meshes that fade when they block the view of the player. */
  occluders: THREE.Mesh[];
}

const WALL_H = 6;

/** Paint the hall floor once onto a big canvas: concrete, zones, aisles, labels. */
function floorTexture(L: Layout, site: Site): THREE.CanvasTexture {
  const { hall } = L;
  const W = hall.x1 - hall.x0, D = hall.z1 - hall.z0;
  const ppm = 16; // pixels per metre
  const c = document.createElement('canvas');
  c.width = Math.round(W * ppm);
  c.height = Math.round(D * ppm);
  const g = c.getContext('2d') as CanvasRenderingContext2D;
  const X = (x: number) => (x - hall.x0) * ppm;
  const Z = (z: number) => (z - hall.z0) * ppm;
  const rect = (r: Rect) => [X(r.x0), Z(r.z0), (r.x1 - r.x0) * ppm, (r.z1 - r.z0) * ppm] as const;

  g.fillStyle = site.theme.floor;
  g.fillRect(0, 0, c.width, c.height);
  // Concrete speckle + slab joints.
  for (let i = 0; i < 26000; i++) {
    const v = Math.random();
    g.fillStyle = v > 0.5 ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)';
    g.fillRect(Math.random() * c.width, Math.random() * c.height, 2, 2);
  }
  g.strokeStyle = 'rgba(0,0,0,0.08)';
  g.lineWidth = 1;
  for (let x = 0; x < c.width; x += 6 * ppm) g.strokeRect(x, 0, 0, c.height);
  for (let z = 0; z < c.height; z += 6 * ppm) g.strokeRect(0, z, c.width, 0);

  // Zones: tinted epoxy with a solid border and a big painted name.
  for (const z of L.zones) {
    g.fillStyle = z.color + '38';
    g.fillRect(...rect(z.rect));
    g.strokeStyle = z.color;
    g.lineWidth = 0.18 * ppm;
    g.strokeRect(...rect(z.rect));
    g.save();
    g.fillStyle = z.color + 'aa';
    g.font = `bold ${1.5 * ppm}px "Segoe UI", Arial, sans-serif`;
    g.textBaseline = 'top';
    g.fillText(z.name.toUpperCase(), X(z.rect.x0) + 0.6 * ppm, Z(z.rect.z0) + 0.4 * ppm);
    g.restore();
  }
  // Walkway lines between rows (yellow), with pedestrian chevrons.
  g.strokeStyle = PALETTE.safetyYellow;
  g.lineWidth = 0.15 * ppm;
  const rows = [...new Set(L.stations.map((s) => s.z))].sort((a, b) => a - b);
  for (let i = 0; i < rows.length - 1; i++) {
    const mid = (rows[i] + rows[i + 1]) / 2;
    for (const off of [-1.6, 1.6]) {
      g.beginPath();
      g.moveTo(X(hall.x0 + 3), Z(mid + off));
      g.lineTo(X(hall.x1 - 3), Z(mid + off));
      g.stroke();
    }
    g.fillStyle = 'rgba(80,160,80,0.35)';
    g.fillRect(X(hall.x0 + 3), Z(mid - 1.5), (hall.x1 - hall.x0 - 6) * ppm, 3 * ppm);
  }
  // Hazard hatch at the dock doors.
  for (const door of [L.receivingDoor, L.shippingDoor]) {
    for (let k = 0; k < 12; k++) {
      g.fillStyle = k % 2 ? '#222' : PALETTE.safetyYellow;
      g.fillRect(X(door.x) + k * 0.5 * ppm, Z(door.z - 3), 0.5 * ppm, 6 * ppm);
    }
  }
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 8;
  return tex;
}

function plane(parent: THREE.Object3D, r: Rect, y: number, material: THREE.Material) {
  const m = new THREE.Mesh(new THREE.PlaneGeometry(r.x1 - r.x0, r.z1 - r.z0), material);
  m.rotation.x = -Math.PI / 2;
  m.position.set((r.x0 + r.x1) / 2, y, (r.z0 + r.z1) / 2);
  m.receiveShadow = true;
  parent.add(m);
  return m;
}

function tree(parent: THREE.Object3D, x: number, z: number, s: number) {
  cyl(parent, 0.18 * s, 1.6 * s, x, 0.8 * s, z, mat('#6b4a2f'));
  const leaves = mat(['#4f8a3c', '#5e9a46', '#3f7a35'][Math.floor(Math.abs(x * z)) % 3], { rough: 0.9 });
  for (const [dy, r] of [[2.1, 1.3], [2.9, 1.0], [3.5, 0.65]]) {
    const cone = new THREE.Mesh(new THREE.ConeGeometry(r * s, 1.4 * s, 9), leaves);
    cone.position.set(x, dy * s, z);
    cone.castShadow = true;
    parent.add(cone);
  }
}

function truck(parent: THREE.Object3D, x: number, z: number, color: string) {
  const g = new THREE.Group();
  g.position.set(x, 0, z);
  parent.add(g);
  box(g, 11, 3.6, 2.5, 0, 2.3, 0, mat('#eeeeea'));
  box(g, 3, 2.6, 2.4, 7.2, 1.8, 0, mat(color, { rough: 0.4, metal: 0.2 }));
  box(g, 0.05, 1.0, 2.0, 8.72, 2.4, 0, mat('#1c2a33', { rough: 0.1, metal: 0.5 }));
  for (const wx of [-3.5, -2.3, 3.5, 7.2]) {
    for (const wz of [-1.2, 1.2]) {
      const w = cyl(g, 0.5, 0.35, wx, 0.5, wz, mat(PALETTE.rubber));
      w.rotation.x = Math.PI / 2;
    }
  }
  return g;
}

/** A desk with a monitor, used across the office rooms. */
function desk(parent: THREE.Object3D, x: number, z: number, rotY = 0) {
  const g = new THREE.Group();
  g.position.set(x, 0, z);
  g.rotation.y = rotY;
  parent.add(g);
  box(g, 1.8, 0.06, 0.8, 0, 0.75, 0, mat('#c9b18f'));
  for (const sx of [-0.85, 0.85]) box(g, 0.05, 0.75, 0.75, sx, 0.375, 0, mat(PALETTE.darkSteel));
  box(g, 0.6, 0.38, 0.03, 0, 1.05, -0.25, mat('#1d1f22', { emissive: '#4a8fd9', ei: 0.3 }));
  box(g, 0.05, 0.22, 0.05, 0, 0.86, -0.25, mat(PALETTE.darkSteel));
  return g;
}

export function buildEnvironment(scene: THREE.Scene, L: Layout, site: Site): Environment {
  const occluders: THREE.Mesh[] = [];
  const root = new THREE.Group();
  scene.add(root);

  // Ground: grass world, asphalt yard west of the hall.
  plane(root, { x0: L.world.x0 - 80, z0: L.world.z0 - 80, x1: L.world.x1 + 80, z1: L.world.z1 + 80 }, -0.02, mat('#7fa65a', { rough: 1 }));
  plane(root, { x0: L.world.x0 + 2, z0: L.hall.z0 - 6, x1: L.hall.x0, z1: L.hall.z1 + 6 }, -0.01, mat('#5f5c57', { rough: 0.95 }));
  plane(root, { x0: L.hall.x0, z0: L.hall.z1 + 2, x1: L.wing.x1, z1: L.hall.z1 + 9 }, -0.01, mat('#6a6660', { rough: 0.95 }));

  // Hall floor (painted canvas) and office floors.
  const floorMat = new THREE.MeshStandardMaterial({ map: floorTexture(L, site), roughness: 0.85 });
  plane(root, L.hall, 0, floorMat);
  for (const r of L.rooms) plane(root, r.rect, 0.005, mat(r.floor, { rough: 0.95 }));

  // Walls: exterior walls are tall; office partitions are glass-topped.
  const wallMat = new THREE.MeshStandardMaterial({ color: site.theme.wall, roughness: 0.9, transparent: true });
  const trim = mat(site.theme.accent, { rough: 0.6 });
  for (const w of L.walls) {
    const h = w.h;
    const m = new THREE.Mesh(new THREE.BoxGeometry(w.x1 - w.x0, h, w.z1 - w.z0), wallMat.clone());
    m.position.set((w.x0 + w.x1) / 2, h / 2, (w.z0 + w.z1) / 2);
    m.castShadow = true;
    m.receiveShadow = true;
    root.add(m);
    occluders.push(m);
    box(root, w.x1 - w.x0 + 0.02, 0.3, w.z1 - w.z0 + 0.02, m.position.x, h - 0.15, m.position.z, trim, false);
  }

  // Roof trusses (open "dollhouse" roof so the camera can look in).
  const steel = mat('#7c858c', { metal: 0.6, rough: 0.45 });
  for (let x = L.hall.x0 + 10; x < L.hall.x1; x += 12) {
    box(root, 0.35, 0.5, L.hall.z1 - L.hall.z0, x, WALL_H + 2.2, 0, steel, false);
    for (const z of [L.hall.z0 + 0.3, L.hall.z1 - 0.3]) box(root, 0.35, 2.2, 0.35, x, WALL_H + 1.1, z, steel, false);
  }
  // Hanging high-bay lights along the aisles.
  const lampMat = mat('#fffbe8', { emissive: '#fff4cc', ei: 1.4 });
  const rows = [...new Set(L.stations.map((s) => s.z))].sort((a, b) => a - b);
  for (let i = 0; i < rows.length - 1; i++) {
    const z = (rows[i] + rows[i + 1]) / 2;
    for (let x = L.hall.x0 + 10; x < L.hall.x1; x += 12) {
      cyl(root, 0.015, 2.2, x, WALL_H + 1.1, z, mat('#333'));
      const shade = new THREE.Mesh(new THREE.ConeGeometry(0.6, 0.45, 16, 1, true), mat('#4a5560', { metal: 0.5 }));
      shade.position.set(x, WALL_H - 0.1, z);
      root.add(shade);
      cyl(root, 0.4, 0.04, x, WALL_H - 0.33, z, lampMat);
    }
  }

  // Dock doors: roll-up door frames with a truck parked outside each.
  for (const [door, color] of [[L.receivingDoor, '#2f80ed'], [L.shippingDoor, '#d35400']] as const) {
    box(root, 0.5, 0.5, 6.4, door.x, 4.8, door.z, mat(PALETTE.safetyYellow), false);
    truck(root, door.x - 10, door.z, color).rotation.y = Math.PI;
  }

  // Yard: parked cars and trees.
  const carColors = ['#c0392b', '#2980b9', '#f1f1f1', '#2c3e50', '#16a085', '#8e44ad'];
  for (let i = 0; i < 14; i++) {
    const x = L.hall.x0 + 8 + i * 5.5;
    const z = L.hall.z1 + 5.5;
    const c = new THREE.Group();
    c.position.set(x, 0, z);
    root.add(c);
    box(c, 2, 0.8, 4.2, 0, 0.6, 0, mat(carColors[i % carColors.length], { rough: 0.35, metal: 0.3 }));
    box(c, 1.8, 0.6, 2.2, 0, 1.25, -0.2, mat('#25323a', { rough: 0.1, metal: 0.5 }));
  }
  for (let i = 0; i < 46; i++) {
    const a = (i / 46) * Math.PI * 2;
    const rx = (L.world.x1 - L.world.x0) / 2 + 12, rz = (L.world.z1 - L.world.z0) / 2 + 10;
    const cx = (L.world.x0 + L.world.x1) / 2, cz = (L.world.z0 + L.world.z1) / 2;
    tree(root, cx + Math.cos(a) * rx + Math.sin(i * 7) * 4, cz + Math.sin(a) * rz + Math.cos(i * 5) * 4, 1 + (i % 3) * 0.25);
  }

  // Office furniture per room.
  for (const r of L.rooms) {
    if (r.id === 'corridor') continue;
    const midZ = (r.rect.z0 + r.rect.z1) / 2;
    if (r.id === 'break') {
      box(root, 6, 0.08, 2.2, r.rect.x0 + 12, 0.75, midZ, mat('#b88a5a'));
      box(root, 1.2, 2, 0.8, r.rect.x1 - 1.2, 1, r.rect.z0 + 1.5, mat('#c0392b', { emissive: '#ff9f8a', ei: 0.15 }));
      box(root, 1.0, 1.0, 0.7, r.rect.x1 - 3, 1.2, r.rect.z0 + 1.2, mat('#3d3d3d'));
      continue;
    }
    if (r.id === 'maintenance') {
      box(root, 5, 1, 1.5, (r.rect.x0 + r.rect.x1) / 2, 0.5, r.rect.z1 - 1.5, mat('#6d7a83', { metal: 0.4 }));
      box(root, 4, 2.5, 0.6, r.rect.x1 - 3, 1.25, r.rect.z0 + 1.2, mat('#c0392b'));
      continue;
    }
    desk(root, r.rect.x0 + 12, midZ, 0);
    if (r.id === 'it') for (let k = 0; k < 3; k++) box(root, 0.9, 2.2, 1, r.rect.x1 - 1.2 - k * 1.1, 1.1, r.rect.z0 + 1.2, mat('#222', { emissive: '#3fd16a', ei: 0.1 }));
    if (r.id === 'quality') box(root, 3, 1, 1.2, r.rect.x1 - 2.5, 0.5, r.rect.z1 - 1.5, mat('#e8e8e8'));
    if (r.id === 'finance' || r.id === 'hr') box(root, 2.4, 2, 0.5, r.rect.x1 - 2, 1, r.rect.z0 + 0.6, mat('#8a6a4a'));
  }
  // Obeya board: big whiteboard on the Obeya room wall.
  for (const b of L.boards) {
    const g = new THREE.Group();
    g.position.set(b.x, 0, b.z);
    g.rotation.y = b.facing;
    root.add(g);
    box(g, 6, 2.2, 0.08, 0, 1.7, 0, mat('#f7f7f2', { rough: 0.3 }));
    const colors = ['#e74c3c', '#f1c40f', '#2ecc71', '#3498db'];
    for (let k = 0; k < 18; k++) {
      box(g, 0.3, 0.3, 0.02, -2.6 + (k % 9) * 0.6, 2.3 - Math.floor(k / 9) * 0.6, 0.06, mat(colors[k % 4]), false);
    }
    for (let k = 0; k < 8; k++) box(g, 0.25, 0.15 + k * 0.08, 0.02, -2.4 + k * 0.6, 1.0 + (0.15 + k * 0.08) / 2, 0.06, mat('#2f6fb0'), false);
  }
  return { occluders };
}
