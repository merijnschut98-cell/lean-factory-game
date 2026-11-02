// When a layer shows, as data for the manifest (the game reads `when`; nothing here runs in Godot).
//   {haspel: n, active}  shows while reel n is (active) or is not (!active) the one in use
//   {control, on}        shows while that switch or valve is on (or off)
//   {spray, level}       shows while that outlet's flow is at this density (1–3)
// A layer without `when` shows whenever its skin does.
const TAPS = { dripper: "lamp", big: "kettle", small: "heater" };

export function whenOf(id) {
  let m;
  if ((m = id.match(/^(?:hosereel|haspel)(\d)_(rolled|unrolled)$/))) return { haspel: Number(m[1]), active: m[2] === "unrolled" };
  if ((m = id.match(/^(?:hoselead|cordlead)(\d)$/))) return { haspel: Number(m[1]), active: true };
  if ((m = id.match(/^(?:hose|cable|heat_tint_hose|heat_tint_cable)_(thin|thick)$/))) return { haspel: m[1] === "thin" ? 1 : 2, active: true };
  if ((m = id.match(/^tap_(dripper|big|small)_(closed|open)$/))) return { control: TAPS[m[1]], on: m[2] === "open" };
  if ((m = id.match(/^switch_(lamp|kettle|heater)_(off|on)$/))) return { control: m[1], on: m[2] === "on" };
  if ((m = id.match(/^spray_(lamp|kettle|heater)_(\d)$/))) return { spray: m[1], level: Number(m[2]) };
  if (id === "kettle_lamp_on") return { control: "kettle", on: true };
  if (id === "heater_glow") return { control: "heater", on: true };
  return null;
}
