// Shared materials and geometries. Reusing them keeps draw-state changes and
// GPU memory low even with hundreds of boxes and dozens of characters.
import * as THREE from 'three';

const cache = new Map<string, THREE.MeshStandardMaterial>();

/** A cached standard material for a colour (+ optional roughness/metalness/emissive). */
export function mat(color: string, opts: { rough?: number; metal?: number; emissive?: string; ei?: number } = {}) {
  const key = `${color}|${opts.rough ?? 0.75}|${opts.metal ?? 0}|${opts.emissive ?? ''}|${opts.ei ?? 0}`;
  let m = cache.get(key);
  if (!m) {
    m = new THREE.MeshStandardMaterial({
      color,
      roughness: opts.rough ?? 0.75,
      metalness: opts.metal ?? 0,
      emissive: opts.emissive ?? '#000000',
      emissiveIntensity: opts.ei ?? 0,
    });
    cache.set(key, m);
  }
  return m;
}

export const PALETTE = {
  steel: '#8d969e',
  darkSteel: '#4a5259',
  machine: '#e9e5dc',
  machineAccent: '#2f6fb0',
  safetyYellow: '#f2c230',
  safetyOrange: '#f07b22',
  cardboard: '#c9a26b',
  wood: '#a87b4f',
  rubber: '#2b2d30',
  glass: '#9fd3e6',
  green: '#3fae5a',
  red: '#d8483b',
  white: '#f4f2ec',
};

export const GEO = {
  box: new THREE.BoxGeometry(1, 1, 1),
  cyl: new THREE.CylinderGeometry(0.5, 0.5, 1, 16),
  sphere: new THREE.SphereGeometry(0.5, 20, 14),
  unit: new THREE.BoxGeometry(0.5, 0.42, 0.5),
  deck: new THREE.BoxGeometry(0.75, 0.16, 0.32),
};

/** Add a box mesh with shadows to a parent. Position is the box centre. */
export function box(
  parent: THREE.Object3D, w: number, h: number, d: number, x: number, y: number, z: number,
  material: THREE.Material, cast = true,
): THREE.Mesh {
  const m = new THREE.Mesh(GEO.box, material);
  m.scale.set(w, h, d);
  m.position.set(x, y, z);
  m.castShadow = cast;
  m.receiveShadow = true;
  parent.add(m);
  return m;
}

export function cyl(
  parent: THREE.Object3D, r: number, h: number, x: number, y: number, z: number, material: THREE.Material,
): THREE.Mesh {
  const m = new THREE.Mesh(GEO.cyl, material);
  m.scale.set(r * 2, h, r * 2);
  m.position.set(x, y, z);
  m.castShadow = true;
  m.receiveShadow = true;
  parent.add(m);
  return m;
}

/** Material for product units at each stage of the line (by zone index). */
export const UNIT_MATS = [
  mat(PALETTE.cardboard),
  mat('#b9bec4', { metal: 0.4, rough: 0.5 }),
  mat('#29a39a', { rough: 0.45 }),
  mat('#29a39a', { rough: 0.45 }),
  mat('#3fbfb0', { rough: 0.35, emissive: '#1d6b63', ei: 0.25 }),
  mat('#f5f5f0'),
];
