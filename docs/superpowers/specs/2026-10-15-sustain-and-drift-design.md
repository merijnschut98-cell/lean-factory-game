# Sustain or decay, and stagnation drift — design

Date: 2026-10-15 · Status: built by Claude while Merijn is away (his autonomy rule:
"design, then build"); calls listed in PLAN.md "Claude's calls, pending Merijn
(2026-10-15, sustain and drift)".

## Merijn's rules (CLAUDE.md §2, PLAN.md Decisions 2026-10-15)

1. **Improvements must be sustained, or they decay — faster the weaker the
   sustaining habits.** Even a standardised fix erodes, slowly.
2. **Stagnation is regression.** A region that stops improving slowly gets worse.

**Merijn's answer on decay (2026-10-15, binding):** "Standardised fixes also decay:
slowly, but faster the longer you don't do something about it, until at some point
you get a mission to have a look at it. Also, the stronger the sustaining
mechanism, the less it decays. Especially if audits and routines are planned: then
it doesn't decay, it stays the same." So: (a) wear accelerates with neglect,
(b) crossing a threshold opens a "have a look" mission, (c) stronger sustainment
decays slower, (d) a planned routine stops the decay while it runs.

## Today

`Region.act(problem, standardise)`: standardised → the fix holds forever
(`recur_at = -1`); not → `recur_at = now + decay_days`, then the problem goes
dormant (`Region._recur`) and its mission reopens (`Missions._reopen_faded`).
Binary: nothing in between, and nothing gets worse while the player idles.

## Approaches considered

- **A. Graded wear that accelerates with neglect (chosen).** Each resolved fix
  wears at a rate that grows with the days since anything was done to sustain it,
  scaled by its sustain strength; health falls smoothly, the problem's effects come
  back in proportion, and below a threshold it recurs through the existing path.
  Deterministic, testable, and the S=0 case keeps today's timing. (A first draft
  used a constant half-life; Merijn's answer (a) replaced it.)
- B. Keep the binary `recur_at`, only stretch it by sustain strength. Simplest, but
  nothing shows the slide before the cliff, and the player cannot see a fix slip.
- C. A random hazard of recurrence. Realistic in spirit, but unpredictable for a
  learning game and hard to test; the player could not reason about it.

## 1. Graded sustainment (rules/sustain.gd, Region)

**Sustain strength S ∈ [0, 1]** of a resolved fix, the sum of the mechanisms present:

| Mechanism | Weight | Present when |
|---|---|---|
| `standard_work` | 0.6 | the player standardised at the Act |
| `visual_management` | 0.2 | another held fix in the same value stream has a countermeasure with `sustains: true` (content: the end-to-end Obeya, the capacity-usage dashboard) |
| `kpis` | 0.2 | a team working at the fix's step steers by KPIs chosen on the KPI board |

Weights are estimates: standard work is the main habit (Merijn's brief), the other
two are the visual and the steering parts of a daily management system.

**Wear, accelerating with neglect.** Base days `B` = the countermeasure's
`decay_days`, or 365 for a fix that used to "stay" (`decay_days: null`: built into a
system or contract; estimate — workarounds creep in over about a year). Life
`L = B / (1 − 0.9·S)`: S = 0 → L = B, standard work alone → 2.2 B, all three → 10 B.
`neglect` = days since the Act, the last audit, or the end of a routine. With a
constant L, `wear = (neglect / L)²`: the hazard grows linearly with neglect, so a
fix slips slowly at first and faster the longer nobody looks. Day by day (S can
change underway): `wear += ((n + dt)² − n²) / L²`. `health = 0.5 ^ wear`.
**Recurrence** at `wear ≥ 1` (health 0.5), after L days of neglect: at S = 0 that
is exactly `decay_days`, today's timing, so the training week's Friday lesson and
its numbers are unchanged.

**What erosion does.** Each day the fix's effects follow its health
(`Sustain.eroded_effects`): the countermeasure's effects at `eff × health`, the
problem's non-lever effects back at `1 − health`, and the problem's cost per week
at `1 − health`. Levers (rules like a WIP limit or a start rule) are in place or not:
the problem's levers come back only with the problem, the fix's go with the fix.
A `slipping` event fires once when health drops below 0.75, for the UI.

**"Have a look" mission (check-in, Terugval).** When a *standardised* fix's health
drops below 0.75 (and no routine holds it), `Missions` builds a small side mission
`terugval_<problem>` (goal `sustain`: the fix back in use, by an audit at the
place or a routine there; 100 XP, estimate). It is never a free problem: the
problem stays resolved, the player decides whether to take the side slot. Done,
it comes back when the fix slips again. Ignored until the fix wears out, the
check-in ends and the problem comes back through its own mission. An
unstandardised fix gets no check-in (nothing to audit against): it fades back to
its mission as before. Check-ins are rebuilt from a save's mission ids.

**Recurrence** stays the existing path: the fix's and problem's effects go, the
state resets to dormant, `recurred` event; `Missions._reopen_faded` reopens the
mission. Problems only arrive through missions, so between the recurrence and the
player accepting the reopened mission the problem does nothing (as today).

**Gemba audit (leader routine).** `Region.audit(place)` / `GameSession.audit(place)`:
a mission-free check of the standard at a place; 60 minutes (estimate: a layered
process audit takes 10–30 minutes per area, plus the walk and the conversation).
Standardised fixes at that step are refreshed (wear and neglect back to 0).
Unstandardised ones are listed as `no_standard`: with no standard there is nothing
to audit against. Teaches `standard_work` and `leader_standard_work` (new glossary
card).

**Planned routine (Merijn's (d)).** `Region.plan_routine(place)` /
`stop_routine(place)`: a recurring leader-standard-work routine at a step with a
team. While it runs, standardised fixes at that step do not wear at all (health
stays as it is, neglect stays 0). It costs the team 2 hours a week (estimate: a
30-minute layered audit by the team lead plus a short stand-up), as an
availability effect `routine:<place>`. Unstandardised fixes keep wearing: a
routine holds people to a standard. Errors: `unknown_place`, `no_team` (a wait
step), `planned`, `not_planned`.

## 2. Stagnation drift (Region, source `region:drift`)

**Level** `d = clamp((stagnant_days − 28) / 365, 0, 1)`, where `stagnant_days` is the
time since the last resolved improvement (an Act), or since the campaign started.
A resolved improvement resets it to 0 (an improving organisation absorbs the
growth). Drift is off until `start_drift` (GameSession calls it when the campaign
opens, also for old saves), so the warm-up, the training week and the rules tests
are untouched.

**Effects at level d** (all estimates, PLAN.md calls):
- demand × (1 + 0.06·d) on `connections` and `congestion`: the energy transition
  keeps adding requests. Public figures show ~107,000 small connections realised in
  2024 at a flat pace while the average wait rose (40 → 44 weeks in H1 2025) and
  applications surged (Netbeheer Nederland, Stand van de uitvoering); no clean
  yearly growth figure was found, so 6 %/year is an estimate.
- availability − 0.03·d for every team: turnover and unfilled vacancies (technician
  shortage). Estimate: ~10 %/year turnover × ~4 months until a replacement is
  productive ≈ 3 % of capacity.
- first-time-right − 0.02·d at every work step: knowledge leaving, workarounds
  creeping in (estimate).

Capped at d = 1, gentle (one year past the grace for the full effect), and never
game over: it only shifts the numbers.

## 3. Save / load

`ProblemState` saves `standardised`, `wear` and `neglect` (no more `recur_at`; an
old save's `recur_at < 0` on a resolved fix reads as standardised, wear 0).
`RegionState` saves `drift_from` (absent: drift not started; GameSession starts it)
and `routines`. The erosion, drift and routine effects come back with the
network's effects. `Missions.load_dict` rebuilds check-in missions.

## 4. Views for the UI (GameSession; ui/ is another agent's)

- `sustain_of(problem_id)` → `{strength, mechanisms, standardised, health,
  neglect_days, life_days, routine, days_to_recur (INF under a routine)}` for a
  resolved fix, `{}` otherwise.
- `plan_routine(place)` / `stop_routine(place)` → `""` or a code; `routines()`.
- Events: Region `slipping {problem}`; Missions `checkin {mission}`.
- `drift()` → `{level, stagnant_days, grace_days, started}`.
- `audit(place)` → `{refreshed, no_standard}` or `{error: unknown_place}`.
- `fade_forecast` keeps its shape and adds `recur_days` (the fix's own forecast).

## Tests

Wear accelerates with neglect; erosion faster with weaker sustainment;
standardised still erodes, slowly; a routine holds a standardised fix and costs
team time; a slipping standardised fix opens a check-in, completed by an audit or
a routine, ended by recurrence (main mission reopens); effects
partly return; the mission reopens through Missions at the threshold; an audit
refreshes standardised fixes only; drift grows without improvement, is capped and
reset by an Act; save/load round trip (and an old save); the Friday lesson's
forecast still shows; existing tests updated where behaviour changed on purpose.
