// Bundles the shared YAML content (../data) into the build via Vite ?raw imports.
import p1 from '../../../data/problems_tier1.yaml?raw';
import p2 from '../../../data/problems_tier2.yaml?raw';
import p3 from '../../../data/problems_tier3.yaml?raw';
import p4 from '../../../data/problems_tier4.yaml?raw';
import m1 from '../../../data/missions_tier1.yaml?raw';
import m2 from '../../../data/missions_tier2.yaml?raw';
import m3 from '../../../data/missions_tier3.yaml?raw';
import m4 from '../../../data/missions_tier4.yaml?raw';
import cms from '../../../data/countermeasures_v1.yaml?raw';
import concepts from '../../../data/concepts.yaml?raw';
import { buildCatalog } from './parse';
import type { Catalog } from './types';

export const CATALOG: Catalog = buildCatalog({
  problems: [p1, p2, p3, p4],
  missions: [m1, m2, m3, m4],
  countermeasures: cms,
  concepts,
});
