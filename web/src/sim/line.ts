// The NovoGlide hoverboard line: 19 stations in 6 zones, in flow order.
// Station ids match station_id / zone_id in the problem YAML.
//
// Numbers are tuned for play, not copied from the Python build: takt is
// 600 s and Burn-In is the starting bottleneck (~750 s effective), so a new
// player sees ~75% of demand shipped and WIP slowly piling up upstream.

export const SHIFT_SECONDS = 8 * 3600;
export const DEMAND_PER_SHIFT = 48;
export const TAKT = SHIFT_SECONDS / DEMAND_PER_SHIFT;

export type StationKind =
  | 'dock' | 'inspection' | 'machine' | 'cnc' | 'bench' | 'cell' | 'line' | 'oven' | 'pad' | 'pack';

export interface StationDef {
  id: string;
  name: string;
  zoneId: string;
  kind: StationKind;
  /** Ideal cycle time, sim seconds per unit. */
  ct: number;
  avail: number;
  perf: number;
  quality: number;
  operators: number;
  startWip: number;
}

export interface ZoneDef {
  id: string;
  name: string;
  color: string;
}

export const ZONES: ZoneDef[] = [
  { id: 'z1', name: 'Receiving', color: '#e0b860' },
  { id: 'z2', name: 'Component Prep', color: '#8fbf5a' },
  { id: 'z3', name: 'Subassembly', color: '#4fb39a' },
  { id: 'z4', name: 'Final Assembly', color: '#5b8fd6' },
  { id: 'z5', name: 'Testing', color: '#9a7ad6' },
  { id: 'z6', name: 'Packaging & Shipping', color: '#d67a7a' },
];

const S = (
  id: string, name: string, zoneId: string, kind: StationKind, ct: number,
  avail: number, perf: number, quality: number, operators: number, startWip: number,
): StationDef => ({ id, name, zoneId, kind, ct, avail, perf, quality, operators, startWip });

export const STATIONS: StationDef[] = [
  S('dock', 'Dock & Staging', 'z1', 'dock', 230, 0.95, 0.95, 0.998, 2, 0),
  S('incoming_qa', 'Incoming QA', 'z1', 'inspection', 330, 0.92, 0.9, 0.995, 2, 2),
  S('coil_winding', 'Coil Winding', 'z2', 'machine', 420, 0.88, 0.85, 0.99, 2, 3),
  S('pcb_prep', 'PCB Prep', 'z2', 'machine', 450, 0.85, 0.88, 0.99, 2, 3),
  S('deck_cutting', 'Deck Cutting', 'z2', 'cnc', 380, 0.9, 0.9, 0.995, 1, 2),
  S('battery_prep', 'Battery Prep', 'z2', 'bench', 400, 0.9, 0.88, 0.995, 1, 2),
  S('deck_assembly', 'Deck Assembly', 'z3', 'cell', 440, 0.88, 0.87, 0.99, 2, 3),
  S('battery_assembly', 'Battery Assembly', 'z3', 'cell', 430, 0.9, 0.86, 0.99, 2, 2),
  S('propulsion_build', 'Propulsion Build', 'z3', 'cell', 470, 0.86, 0.84, 0.988, 2, 4),
  S('shell_assembly', 'Shell Assembly', 'z3', 'cell', 380, 0.92, 0.9, 0.995, 1, 2),
  S('integration_1', 'Integration 1', 'z4', 'line', 400, 0.9, 0.88, 0.993, 1, 2),
  S('integration_2', 'Integration 2', 'z4', 'line', 400, 0.9, 0.9, 0.993, 1, 1),
  S('integration_3', 'Integration 3', 'z4', 'line', 440, 0.86, 0.85, 0.985, 1, 3),
  S('integration_4', 'Integration 4', 'z4', 'line', 420, 0.87, 0.87, 0.988, 1, 2),
  S('integration_5', 'Integration 5', 'z4', 'line', 390, 0.92, 0.9, 0.995, 1, 1),
  S('burn_in', 'Burn-In', 'z5', 'oven', 620, 0.9, 0.92, 0.997, 1, 4),
  S('flight_test', 'Flight Test', 'z5', 'pad', 420, 0.85, 0.85, 0.985, 2, 3),
  S('final_qa', 'Final QA', 'z5', 'inspection', 360, 0.9, 0.88, 0.99, 2, 2),
  S('packaging', 'Packaging & Shipping', 'z6', 'pack', 240, 0.95, 0.95, 0.998, 2, 1),
];

export const zoneById = (id: string): ZoneDef | undefined => ZONES.find((z) => z.id === id);

/** Problems without a station_id act on the first station of their zone. */
export function stationForProblem(zoneId: string, stationId: string | null): string {
  if (stationId && STATIONS.some((s) => s.id === stationId)) return stationId;
  return (STATIONS.find((s) => s.zoneId === zoneId) ?? STATIONS[0]).id;
}
