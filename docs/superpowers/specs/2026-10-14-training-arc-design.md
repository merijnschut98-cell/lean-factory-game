# Training arc ("Inwerkweek") — design draft

> Status: draft by Claude (2026-10-13, night), **not to be built yet**. Merijn asked for a training arc in the plan. The open choices are listed at the end as questions for him.

## Goal
Before the first real mission, the player learns three things by doing:
1. **How the game works:** walking, the map, gemba tools and their time cost, the clue journal, the A3, Check/Act, the coach, the mission board and later the KPI board.
2. **What choices do:** time, budget and trust; a fix that fades when it is not standardised; why improving a non-bottleneck brings nothing.
3. **The energy sector, a little:** what a grid operator does, grid congestion, the connection term, the technician shortage, the ACM and the energy transition. The text comes from `content/concepts.yaml`, with sources.

## Frame: "Inwerkweek" (onboarding week) in the Starter Kata style
The player starts on Monday as the new CI lead at Voltana Zuidmark. Ruud Hoekstra, the coach, gives them a week of small, safe routines. These are Starter Kata: practice before the real problem. Each day is a short side-mission-sized step in the connections office, with no risk and no deadline. The real campaign starts once the week is done.

| Day | Routine (mission) | What the player does | What they learn |
|---|---|---|---|
| Ma | Rondleiding (walk) | Walk the office with the map (M) and visit Intake, Werkvoorbereiding, the Obeya wall and the coach | Walking, the map, the places of the connections stream; *netbeheerder*, *aansluiting*, *aansluittermijn* |
| Di | Kijken zonder oordeel (go see) | Use two gemba tools at Werkvoorbereiding and read the clues in the journal | Tools cost time, clues get deeper with each "why"; *gemba*, *5x waarom*, *verspilling* |
| Wo | Waar zit de stapel? (bottleneck) | Count the queues at two steps and say which one waits longest; the HUD and map show it | Bottleneck versus non-bottleneck; *flow*, *WIP*, *knelpunt*; a sector link: *netcongestie* is a bottleneck in the grid |
| Do | Een klein experiment (PDCA) | A practice A3 on a harmless training problem (`training_tray`: dossiers sorted in two trays), then wait three days for a short Check | Writing the A3, predicting a KPI, the Check judging; *PDCA*, *A3*, *volgindicator vs stuurindicator* |
| Vr | Borgen of laten wegzakken (Act) | Choose to standardise or not, and see the fade (time-lapsed) in a replay | Standard work, sustaining; budget as a cost; trust per team |

**Rules it keeps (CLAUDE.md §2):**
- Action-based: no quiz and no multiple choice with a marked answer.
- The coach asks Kata questions and rarely gives an answer.
- The training problem is a real (tiny) simulation problem, so the Check really judges.
- It never ends in failure: a wrong choice in the training week only shows its effect.
- Dutch text throughout.

**Skippable:** a returning player can skip the week from the mission board, so the campaign stays open.

## Mechanics needed
- The mission kinds already exist (walk, investigate, solve). New:
  - a tiny training problem, `training_tray`, in content (a small extra delay at `connections.intake` that a trivial countermeasure removes);
  - a "time-lapse" helper that advances 30 days and shows before/after for the Friday lesson.
- **Sector cards:** when a concept is first met, a short card from `concepts.yaml` appears and is kept in a codex (K). This reuses `Profile.learn`.
- **Short Check for training only:** three days instead of `Region.CHECK_DAYS` (14). It is a mission flag, so the real rules stay unchanged.

## Questions for Merijn
1. **Length:** five days (as above), three days (merge Tue/Wed and Thu/Fri), or one long day?
2. **Skippable:** always, only after one playthrough, or never?
3. **Sector depth:** short cards only (as above), cards plus a talk with an expert (e.g. a grid planner explaining congestion), or a separate "sector" side quest?
4. **The training problem:** an invented harmless one (`training_tray`), or a light version of a real catalogue problem?
