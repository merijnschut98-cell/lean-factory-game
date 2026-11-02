// Three.js scene for one factory site: renderer, lights, camera rig, input,
// and all the world objects. Talks to the rest of the game through callbacks.
import * as THREE from 'three';
import { CSS2DRenderer } from 'three/examples/jsm/renderers/CSS2DRenderer.js';
import type { SiteGame } from '../sim/game';
import type { Site } from '../sim/progression';
import { Actors, type Npc } from './actors';
import { buildEnvironment } from './environment';
import { FactoryView } from './factoryView';
import { buildLayout, type Layout, type StationPlace } from './layout';
import { NavGrid } from './navgrid';
import { Player } from './player';

export type Target =
  | { kind: 'station'; id: string; label: string; x: number; z: number; place: StationPlace }
  | { kind: 'npc'; id: string; label: string; x: number; z: number; npc: Npc }
  | { kind: 'board'; id: string; label: string; x: number; z: number };

const INTERACT_RANGE = 3.4;

export class World {
  readonly renderer: THREE.WebGLRenderer;
  readonly labels: CSS2DRenderer;
  readonly scene = new THREE.Scene();
  readonly camera = new THREE.PerspectiveCamera(50, 1, 0.1, 600);
  layout!: Layout;
  nav!: NavGrid;
  player!: Player;
  factory!: FactoryView;
  actors!: Actors;
  private sun = new THREE.DirectionalLight('#fff3df', 2.4);
  private occluders: THREE.Mesh[] = [];
  private pickables: THREE.Object3D[] = [];
  private ground!: THREE.Mesh;

  // Camera rig.
  yaw = Math.PI * 0.25;
  pitch = 0.82;
  distance = 22;
  private camTarget = new THREE.Vector3();
  /** When set, the camera slowly orbits this point (title screen). */
  orbit: THREE.Vector3 | null = null;

  // Input.
  private keys = new Set<string>();
  private pointers = new Map<number, { x: number; y: number; sx: number; sy: number }>();
  private dragged = false;
  private pinch = 0;
  inputEnabled = true;
  onTargetClicked: ((t: Target) => void) | null = null;

  constructor(private container: HTMLElement) {
    this.renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.05;
    container.appendChild(this.renderer.domElement);
    this.labels = new CSS2DRenderer();
    this.labels.domElement.className = 'labels-layer';
    container.appendChild(this.labels.domElement);

    this.scene.background = new THREE.Color('#bcd6ea');
    this.scene.fog = new THREE.Fog('#bcd6ea', 120, 330);
    this.scene.add(new THREE.HemisphereLight('#dfefff', '#8a7a5c', 1.15));
    this.sun.position.set(40, 80, 30);
    this.sun.castShadow = true;
    this.sun.shadow.mapSize.set(2048, 2048);
    const sc = this.sun.shadow.camera;
    sc.left = sc.bottom = -45;
    sc.right = sc.top = 45;
    sc.near = 10;
    sc.far = 220;
    this.sun.shadow.bias = -0.0004;
    this.scene.add(this.sun, this.sun.target);
    const fill = new THREE.DirectionalLight('#cfe0ff', 0.5);
    fill.position.set(-50, 40, -40);
    this.scene.add(fill);

    this.bindInput();
    this.resize();
    window.addEventListener('resize', () => this.resize());
  }

  /** (Re)build the world for a site. */
  load(site: Site, game: SiteGame): void {
    // Clear everything except lights.
    for (const o of [...this.scene.children]) if (!(o instanceof THREE.Light)) this.scene.remove(o);
    this.labels.domElement.innerHTML = '';
    this.layout = buildLayout(site.theme.size);
    this.nav = new NavGrid(this.layout.world, this.layout.obstacles);
    this.occluders = buildEnvironment(this.scene, this.layout, site).occluders;
    this.factory = new FactoryView(this.layout, game);
    this.scene.add(this.factory.root);
    game.flow.setTransitTimes(this.factory.transitTimes());
    this.actors = new Actors(this.layout, this.nav, game);
    this.scene.add(this.actors.root);
    this.player = new Player(this.nav, this.layout.spawn);
    this.scene.add(this.player.char.root);
    this.camTarget.copy(this.player.pos);

    const groundGeo = new THREE.PlaneGeometry(2000, 2000);
    this.ground = new THREE.Mesh(groundGeo, new THREE.MeshBasicMaterial({ visible: false }));
    this.ground.rotation.x = -Math.PI / 2;
    this.scene.add(this.ground);

    this.pickables = [];
    for (const v of this.factory.views) {
      v.root.userData.target = this.stationTarget(v.place);
      this.pickables.push(v.root);
    }
    for (const n of this.actors.npcs) {
      n.char.root.userData.target = this.npcTarget(n);
      this.pickables.push(n.char.root);
    }
  }

  private stationTarget(p: StationPlace): Target {
    return { kind: 'station', id: p.def.id, label: p.def.name, x: p.interact.x, z: p.interact.z, place: p };
  }
  private npcTarget(n: Npc): Target {
    return { kind: 'npc', id: n.place.id, label: `${n.place.name} · ${n.place.role}`, x: n.place.x, z: n.place.z, npc: n };
  }

  targets(): Target[] {
    return [
      ...this.layout.stations.map((p) => this.stationTarget(p)),
      ...this.actors.npcs.map((n) => this.npcTarget(n)),
      ...this.layout.boards.map((b) => ({ kind: 'board' as const, id: b.id, label: b.name, x: b.x - 1.6, z: b.z })),
    ];
  }

  /** Closest interactable within reach of the player. */
  nearestTarget(): Target | null {
    let best: Target | null = null, bd = INTERACT_RANGE;
    const p = this.player.pos;
    for (const t of this.targets()) {
      const d = Math.hypot(t.x - p.x, t.z - p.z);
      if (d < bd) {
        bd = d;
        best = t;
      }
    }
    return best;
  }

  /** Walk the player to a target and fire the click callback on arrival. */
  walkTo(t: Target): void {
    const stand = t.kind === 'npc' ? { x: t.x + Math.sin(t.npc.place.facing) * 1.6, z: t.z + Math.cos(t.npc.place.facing) * 1.6 } : t;
    const arrive = () => {
      this.player.faceTowards(t.kind === 'station' ? t.place.x : t.x, t.kind === 'station' ? t.place.z : t.z);
      this.onTargetClicked?.(t);
    };
    if (Math.hypot(stand.x - this.player.pos.x, stand.z - this.player.pos.z) < INTERACT_RANGE) arrive();
    else this.player.goTo(stand.x, stand.z, arrive);
  }

  private resize(): void {
    const w = this.container.clientWidth, h = this.container.clientHeight;
    this.renderer.setSize(w, h);
    this.labels.setSize(w, h);
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
  }

  // ── Input ────────────────────────────────────────────────────────────────
  private bindInput(): void {
    const el = this.renderer.domElement;
    window.addEventListener('keydown', (e) => {
      if ((e.target as HTMLElement).closest('input, textarea')) return;
      this.keys.add(e.code);
    });
    window.addEventListener('keyup', (e) => this.keys.delete(e.code));
    window.addEventListener('blur', () => this.keys.clear());
    el.addEventListener('contextmenu', (e) => e.preventDefault());
    el.addEventListener('wheel', (e) => {
      e.preventDefault();
      this.distance = THREE.MathUtils.clamp(this.distance * (1 + Math.sign(e.deltaY) * 0.1), 7, 70);
    }, { passive: false });
    el.addEventListener('pointerdown', (e) => {
      el.setPointerCapture(e.pointerId);
      this.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY, sx: e.clientX, sy: e.clientY });
      this.dragged = false;
      if (this.pointers.size === 2) this.pinch = this.pinchDist();
    });
    el.addEventListener('pointermove', (e) => {
      const p = this.pointers.get(e.pointerId);
      if (!p) return;
      const dx = e.clientX - p.x, dy = e.clientY - p.y;
      p.x = e.clientX;
      p.y = e.clientY;
      if (Math.hypot(e.clientX - p.sx, e.clientY - p.sy) > 6) this.dragged = true;
      if (this.pointers.size === 2) {
        const d = this.pinchDist();
        if (this.pinch > 0) this.distance = THREE.MathUtils.clamp(this.distance * (this.pinch / d), 7, 70);
        this.pinch = d;
      } else if (this.dragged) {
        this.yaw -= dx * 0.006;
        this.pitch = THREE.MathUtils.clamp(this.pitch + dy * 0.004, 0.35, 1.35);
      }
    });
    const end = (e: PointerEvent) => {
      const wasSingle = this.pointers.size === 1;
      this.pointers.delete(e.pointerId);
      if (wasSingle && !this.dragged && e.button === 0 && this.inputEnabled) this.click(e.clientX, e.clientY);
    };
    el.addEventListener('pointerup', end);
    el.addEventListener('pointercancel', (e) => this.pointers.delete(e.pointerId));
  }

  private pinchDist(): number {
    const [a, b] = [...this.pointers.values()];
    return Math.hypot(a.x - b.x, a.y - b.y) || 1;
  }

  private click(cx: number, cy: number): void {
    const rect = this.renderer.domElement.getBoundingClientRect();
    const ndc = new THREE.Vector2(((cx - rect.left) / rect.width) * 2 - 1, -((cy - rect.top) / rect.height) * 2 + 1);
    const ray = new THREE.Raycaster();
    ray.setFromCamera(ndc, this.camera);
    for (const hit of ray.intersectObjects(this.pickables, true)) {
      let o: THREE.Object3D | null = hit.object;
      while (o && !o.userData.target) o = o.parent;
      if (o) {
        this.walkTo(o.userData.target as Target);
        return;
      }
    }
    const g = ray.intersectObject(this.ground)[0];
    if (g) this.player.goTo(g.point.x, g.point.z);
  }

  moveInput(): { x: number; z: number; run: boolean } {
    if (!this.inputEnabled) return { x: 0, z: 0, run: false };
    const k = this.keys;
    const x = (k.has('KeyD') || k.has('ArrowRight') ? 1 : 0) - (k.has('KeyA') || k.has('ArrowLeft') ? 1 : 0);
    const z = (k.has('KeyW') || k.has('ArrowUp') ? 1 : 0) - (k.has('KeyS') || k.has('ArrowDown') ? 1 : 0);
    const len = Math.hypot(x, z) || 1;
    return { x: x / len, z: z / len, run: k.has('ShiftLeft') || k.has('ShiftRight') };
  }

  // ── Frame ────────────────────────────────────────────────────────────────
  update(dt: number, simRunning: boolean): void {
    if (this.inputEnabled) {
      if (this.keys.has('KeyQ')) this.yaw += dt * 1.8;
      if (this.keys.has('KeyE') && false) this.yaw -= dt * 1.8;
    }
    const mv = this.moveInput();
    this.player.update(dt, mv, mv.run || this.player.speed > 0 && this.keys.has('ShiftLeft'), this.yaw);
    this.factory.update(dt, simRunning);
    this.actors.update(dt, simRunning, this.player.pos);

    // Camera follow / orbit.
    if (this.orbit) {
      this.yaw += dt * 0.05;
      this.camTarget.lerp(this.orbit, 1 - Math.exp(-dt * 2));
    } else {
      this.camTarget.lerp(this.player.pos, 1 - Math.exp(-dt * 8));
    }
    const look = this.camTarget.clone().add(new THREE.Vector3(0, 1.4, 0));
    const r = this.distance;
    this.camera.position.set(
      look.x + Math.sin(this.yaw) * Math.cos(this.pitch) * r,
      look.y + Math.sin(this.pitch) * r,
      look.z + Math.cos(this.yaw) * Math.cos(this.pitch) * r,
    );
    this.camera.lookAt(look);
    // Shadows follow the camera target.
    this.sun.position.set(look.x + 40, 80, look.z + 30);
    this.sun.target.position.copy(look);
    this.fadeOccluders(look);
    this.renderer.render(this.scene, this.camera);
    this.labels.render(this.scene, this.camera);
  }

  private fadeOccluders(look: THREE.Vector3): void {
    const dir = look.clone().sub(this.camera.position);
    const len = dir.length();
    const ray = new THREE.Raycaster(this.camera.position, dir.normalize(), 0, len);
    const hits = new Set(ray.intersectObjects(this.occluders, false).map((h) => h.object));
    for (const m of this.occluders) {
      const mat = m.material as THREE.MeshStandardMaterial;
      const want = hits.has(m) ? 0.18 : 1;
      mat.opacity += (want - mat.opacity) * 0.2;
      mat.depthWrite = mat.opacity > 0.9;
    }
  }
}
