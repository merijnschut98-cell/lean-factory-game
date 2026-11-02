// Plant layout as plain data: where every station, conveyor, room and NPC is.
// No Three.js here — the same layout feeds rendering, navigation and the minimap.
//
// Coordinates in metres. x → east, z → south, y up. The line snakes through
// four rows of the hall (serpentine), entering at the west receiving door and
// leaving through the west shipping door. Offices form a wing on the east side.

import { STATIONS, ZONES, type StationDef } from '../sim/line';

export interface Rect {
  x0: number;
  z0: number;
  x1: number;
  z1: number;
}
export interface V3 {
  x: number;
  y: number;
  z: number;
}

export interface StationPlace {
  def: StationDef;
  index: number;
  x: number;
  z: number;
  /** +1 if the row flows east, −1 if west. */
  dir: number;
  footprint: Rect;
  /** Where the input buffer pallet sits. */
  buffer: { x: number; z: number };
  /** Where operators stand (one per operator). */
  operatorSpots: { x: number; z: number }[];
  /** Where the player stands to interact. */
  interact: { x: number; z: number };
  scrap: { x: number; z: number };
}

export interface NpcPlace {
  id: string;
  name: string;
  role: string;
  zoneId?: string;
  x: number;
  z: number;
  facing: number;
  room: string;
}

export interface Room {
  id: string;
  name: string;
  rect: Rect;
  floor: string;
}

export interface Layout {
  scale: number;
  hall: Rect;
  wing: Rect;
  world: Rect;
  stations: StationPlace[];
  /** Conveyor path from station i output to station i+1 input (last one → shipping). */
  paths: V3[][];
  zones: { id: string; name: string; color: string; rect: Rect }[];
  rooms: Room[];
  walls: (Rect & { h: number })[];
  obstacles: Rect[];
  npcs: NpcPlace[];
  boards: { id: string; name: string; x: number; z: number; facing: number }[];
  receivingDoor: { x: number; z: number };
  shippingDoor: { x: number; z: number };
  spawn: { x: number; z: number };
}

const ROWS: string[][] = [
  ['dock', 'incoming_qa', 'coil_winding', 'pcb_prep', 'deck_cutting', 'battery_prep'],
  ['deck_assembly', 'battery_assembly', 'propulsion_build', 'shell_assembly'],
  ['integration_1', 'integration_2', 'integration_3', 'integration_4', 'integration_5'],
  ['burn_in', 'flight_test', 'final_qa', 'packaging'],
];
const ROW_Z = [-22, -7, 8, 23];
const CONVEYOR_Y = 2.9;
const STATION_W = 8;
const STATION_D = 5;

const TEAM_LEADERS: Record<string, string> = {
  z1: 'Bram', z2: 'Fatima', z3: 'Jin-Ho', z4: 'Carlos', z5: 'Hana', z6: 'Bao',
};

export function buildLayout(scale = 1): Layout {
  const s = scale;
  const hx = 60 * s;
  const hz = 33 * s;
  const hall: Rect = { x0: -hx, z0: -hz, x1: hx, z1: hz };
  const wing: Rect = { x0: hx, z0: -hz, x1: hx + 30, z1: hz };
  const world: Rect = { x0: -hx - 34, z0: -hz - 22, x1: wing.x1 + 22, z1: hz + 22 };

  // ── Stations ─────────────────────────────────────────────────────────────
  const stations: StationPlace[] = [];
  ROWS.forEach((row, r) => {
    const dir = r % 2 === 0 ? 1 : -1;
    const z = ROW_Z[r] * s;
    const span = 96 * s;
    const step = span / row.length;
    row.forEach((id, k) => {
      const def = STATIONS.find((d) => d.id === id);
      if (!def) throw new Error(`layout: unknown station ${id}`);
      const slot = dir > 0 ? k : row.length - 1 - k;
      const x = -span / 2 + step * (slot + 0.5);
      const ops = Array.from({ length: def.operators }, (_, i) => ({
        x: x + (def.operators === 1 ? 0 : (i - 0.5) * 2.6),
        z: z + STATION_D / 2 + 0.75,
      }));
      stations.push({
        def,
        index: STATIONS.indexOf(def),
        x,
        z,
        dir,
        footprint: { x0: x - STATION_W / 2, z0: z - STATION_D / 2, x1: x + STATION_W / 2, z1: z + STATION_D / 2 },
        buffer: { x: x - dir * (STATION_W / 2 + 1.6), z },
        operatorSpots: ops,
        interact: { x, z: z + STATION_D / 2 + 2.6 },
        scrap: { x: x + dir * (STATION_W / 2 + 1.2), z: z + 1.6 },
      });
    });
  });
  stations.sort((a, b) => a.index - b.index);

  // ── Conveyors: up from the output, overhead to the next buffer, down. ────
  const outPt = (st: StationPlace) => ({ x: st.x + st.dir * (STATION_W / 2 - 0.4), z: st.z });
  const shippingDoor = { x: -hx, z: ROW_Z[3] * s };
  const receivingDoor = { x: -hx, z: ROW_Z[0] * s };
  const paths: V3[][] = stations.map((st, i) => {
    const o = outPt(st);
    const pts: V3[] = [{ x: o.x, y: 1.1, z: o.z }, { x: o.x + st.dir * 1.2, y: CONVEYOR_Y, z: o.z }];
    const next = stations[i + 1];
    if (!next) {
      // Packaging → shipping door.
      pts.push({ x: shippingDoor.x + 3, y: CONVEYOR_Y, z: o.z }, { x: shippingDoor.x + 1.5, y: 1.1, z: o.z });
      return pts;
    }
    const b = next.buffer;
    if (next.dir !== st.dir) {
      // Row change: run past the row end, turn, come back along the next row.
      const turnX = st.dir > 0 ? 52.5 * s : -52.5 * s;
      pts.push({ x: turnX, y: CONVEYOR_Y, z: o.z }, { x: turnX, y: CONVEYOR_Y, z: b.z });
    }
    pts.push({ x: b.x - next.dir * 1.2, y: CONVEYOR_Y, z: b.z }, { x: b.x, y: 1.1, z: b.z });
    return pts;
  });

  // ── Zones (floor tint rectangles around their stations) ──────────────────
  const zones = ZONES.map((zd) => {
    const sts = stations.filter((p) => p.def.zoneId === zd.id);
    const rect: Rect = {
      x0: Math.min(...sts.map((p) => Math.min(p.footprint.x0, p.buffer.x - 1))) - 1.5,
      z0: Math.min(...sts.map((p) => p.footprint.z0)) - 2.5,
      x1: Math.max(...sts.map((p) => Math.max(p.footprint.x1, p.buffer.x + 1, p.scrap.x + 1))) + 1.5,
      z1: Math.max(...sts.map((p) => p.footprint.z1)) + 2.2,
    };
    return { id: zd.id, name: zd.name, color: zd.color, rect };
  });

  // ── Office wing ──────────────────────────────────────────────────────────
  const cx = wing.x0 + 6; // corridor x0..x0+6, rooms east of it
  const roomDefs: [string, string, string][] = [
    ['obeya', 'Obeya Room · Operations', '#c7d3e0'],
    ['quality', 'Quality Lab', '#cfe0cc'],
    ['it', 'IT & MES', '#d7cfe6'],
    ['finance', 'Finance', '#cfe3df'],
    ['hr', 'HR', '#ead7c6'],
    ['break', 'Break Room', '#e2d2bd'],
  ];
  const roomH = (wing.z1 - wing.z0) / roomDefs.length;
  const rooms: Room[] = roomDefs.map(([id, name, floor], i) => ({
    id, name, floor,
    rect: { x0: cx, z0: wing.z0 + i * roomH, x1: wing.x1, z1: wing.z0 + (i + 1) * roomH },
  }));
  rooms.push({ id: 'corridor', name: 'Corridor', floor: '#d8d2c4', rect: { x0: wing.x0, z0: wing.z0, x1: cx, z1: wing.z1 } });
  const maint: Rect = { x0: hx - 16, z0: hz - 7, x1: hx, z1: hz };
  rooms.push({ id: 'maintenance', name: 'Maintenance Shop', floor: '#cdbf8f', rect: maint });

  // ── Walls (thin rects) with door gaps ────────────────────────────────────
  const T = 0.3;
  const walls: (Rect & { h: number })[] = [];
  const EXT = 6;
  const INT = 3.2;
  // A straight wall from a to b along one axis, split around door gaps.
  const wall = (horizontal: boolean, a0: number, a1: number, at: number, h: number, gaps: [number, number][] = []) => {
    const seg = (s0: number, s1: number) => walls.push(horizontal
      ? { x0: s0, z0: at - T / 2, x1: s1, z1: at + T / 2, h }
      : { x0: at - T / 2, z0: s0, x1: at + T / 2, z1: s1, h });
    let cur = a0;
    for (const [g0, g1] of [...gaps].sort((a, b) => a[0] - b[0])) {
      if (g0 > cur) seg(cur, g0);
      cur = g1;
    }
    if (cur < a1) seg(cur, a1);
  };
  const hWall = (x0: number, x1: number, z: number, gaps: [number, number][] = [], h = EXT) => wall(true, x0, x1, z, h, gaps);
  const vWall = (z0: number, z1: number, x: number, gaps: [number, number][] = [], h = EXT) => wall(false, z0, z1, x, h, gaps);
  hWall(hall.x0, wing.x1, hall.z0, [[hall.x0 + 4, hall.x0 + 10]]);
  hWall(hall.x0, wing.x1, hall.z1, [[hall.x0 + 22, hall.x0 + 28]]);
  vWall(hall.z0, hall.z1, hall.x0, [
    [receivingDoor.z - 3, receivingDoor.z + 3],
    [shippingDoor.z - 3, shippingDoor.z + 3],
  ]);
  vWall(hall.z0, hall.z1, wing.x0, [[-10 * s, -4 * s], [12 * s, 18 * s]]);
  vWall(wing.z0, wing.z1, wing.x1);
  // Room partitions + doors to the corridor.
  rooms.filter((r) => !['corridor', 'maintenance'].includes(r.id)).forEach((r, i) => {
    if (i > 0) hWall(cx, wing.x1, r.rect.z0, [], INT);
    const mid = (r.rect.z0 + r.rect.z1) / 2;
    vWall(r.rect.z0, r.rect.z1, cx, [[mid - 1.6, mid + 1.6]], INT);
  });
  // Maintenance shop walls.
  hWall(maint.x0, maint.x1, maint.z0, [[maint.x0 + 2, maint.x0 + 6]], INT);
  vWall(maint.z0, maint.z1, maint.x0, [], INT);

  // ── NPCs ─────────────────────────────────────────────────────────────────
  const npcs: NpcPlace[] = zones.map((z) => {
    const sts = stations.filter((p) => p.def.zoneId === z.id);
    const first = sts[0];
    return {
      id: `tl_${z.id}`,
      name: TEAM_LEADERS[z.id],
      role: 'Team Leader',
      zoneId: z.id,
      x: first.x + first.dir * 1.5 + 0.2,
      z: first.z - STATION_D / 2 - 2.3,
      facing: 0,
      room: z.name,
    };
  });
  const roomNpc = (id: string, name: string, role: string, room: string, dx = 0.5, dz = 0.5) => {
    const r = rooms.find((x) => x.id === room) as Room;
    npcs.push({
      id, name, role, room: r.name,
      x: r.rect.x0 + (r.rect.x1 - r.rect.x0) * dx,
      z: r.rect.z0 + (r.rect.z1 - r.rect.z0) * dz,
      facing: -Math.PI / 2,
    });
  };
  roomNpc('coach', 'Alex', 'Lean Coach', 'obeya', 0.35, 0.62);
  roomNpc('scheduler', 'Maya', 'Scheduler', 'obeya', 0.75, 0.7);
  roomNpc('quality', 'Sven', 'Quality Lead', 'quality', 0.4, 0.55);
  roomNpc('it', 'Priya', 'IT Engineer', 'it', 0.4, 0.55);
  roomNpc('finance', 'Jon', 'Controller', 'finance', 0.4, 0.55);
  roomNpc('hr', 'Ingrid', 'HR Manager', 'hr', 0.4, 0.55);
  roomNpc('maint', 'Ruud', 'Maintenance Lead', 'maintenance', 0.55, 0.45);

  const obeya = rooms[0].rect;
  const boards = [{ id: 'obeya', name: 'Obeya Board', x: obeya.x1 - 0.4, z: (obeya.z0 + obeya.z1) / 2, facing: -Math.PI / 2 }];

  // ── Obstacles for navigation ─────────────────────────────────────────────
  const obstacles: Rect[] = [...walls];
  for (const st of stations) {
    obstacles.push(st.footprint);
    obstacles.push({ x0: st.buffer.x - 1.4, z0: st.buffer.z - 1.4, x1: st.buffer.x + 1.4, z1: st.buffer.z + 1.4 });
    obstacles.push({ x0: st.scrap.x - 0.5, z0: st.scrap.z - 0.5, x1: st.scrap.x + 0.5, z1: st.scrap.z + 0.5 });
  }
  for (const r of rooms) {
    if (r.id === 'corridor' || r.id === 'maintenance') continue;
    // A desk / table block in the middle-east of each room.
    const midZ = (r.rect.z0 + r.rect.z1) / 2;
    obstacles.push({ x0: r.rect.x0 + 9, z0: midZ - 1.2, x1: r.rect.x0 + 15, z1: midZ + 1.2 });
  }

  return {
    scale, hall, wing, world, stations, paths, zones, rooms, walls, obstacles, npcs, boards,
    receivingDoor, shippingDoor,
    spawn: { x: wing.x0 + 3, z: (obeya.z0 + obeya.z1) / 2 + 2 },
  };
}

export function pathLength(pts: V3[]): number {
  let L = 0;
  for (let i = 1; i < pts.length; i++) {
    L += Math.hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y, pts[i].z - pts[i - 1].z);
  }
  return L;
}

/** Point at fraction t (0..1) along a polyline. */
export function pointAt(pts: V3[], t: number, out: V3 = { x: 0, y: 0, z: 0 }): V3 {
  const total = pathLength(pts);
  let d = Math.max(0, Math.min(1, t)) * total;
  for (let i = 1; i < pts.length; i++) {
    const a = pts[i - 1], b = pts[i];
    const seg = Math.hypot(b.x - a.x, b.y - a.y, b.z - a.z);
    if (d <= seg || i === pts.length - 1) {
      const k = seg > 0 ? Math.min(1, d / seg) : 0;
      out.x = a.x + (b.x - a.x) * k;
      out.y = a.y + (b.y - a.y) * k;
      out.z = a.z + (b.z - a.z) * k;
      return out;
    }
    d -= seg;
  }
  return out;
}
