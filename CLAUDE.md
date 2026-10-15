# CLAUDE.md — Rules Before Every Coding Session

## How enforcement works
Claude Code automatically loads this file into context at the start of every session.
**At the start of each session, confirm in your first response:** current phase from PLAN.md + the next task. This makes it verifiable.

---

## 1. Check and Update the Plan — CORE DIRECTIVE

Before writing any code, read [PLAN.md](PLAN.md) and state the current phase + next task.

**PLAN.md must stay in sync with reality at all times:**
- ✅ Mark a task done the moment it is complete — not at end of session
- ➕ Add any newly discovered task or sub-task as soon as you discover it
- 🗑 Remove or rewrite tasks that are no longer relevant
- 🔄 Update the "Current Status" line at the top whenever the phase changes
- ❌ Never leave stale blockers, outdated tasks, or wrong status indicators

This is not an end-of-session cleanup — it is an inline, real-time habit. Every code change that completes or adds a task must be immediately followed by a PLAN.md edit.

---

## 2. Game Design Rules — uphold in every change

Merijn's design decisions that every feature, content file and test must respect. Change one only when Merijn says so; record the change in PLAN.md "Decisions Made".

### Core directives (the game's purpose)
- **A learning game about continuous improvement**: Lean first, later IT / Agile / DevOps / SAFe, set in the energy sector (a Dutch grid operator).
- **People are the most valuable resource.** Problems live in the process, not the person; countermeasures develop people rather than replace them.
- **An RPG where the main character has to search and think** to find out what is wrong and how to fix it. Nothing is handed over.
- **Fix processes end to end.** Improving a step that is not the bottleneck brings no gain, and the simulation must show that.
- **Measure.** KPIs and OKRs come up often: predictions name a KPI, the Check measures it, missions and the coach ask for numbers.
- **The 8 wastes come up often** (TIMWOODS, in a service and field organisation).
- **Sector-specific issues come up often**: congestion, permits, the technician shortage, regulation (ACM, NTA 8120), the energy transition.

### The mission system decides the game (Merijn, 2026-10-15)
If the missions are weak, the game is weak. Every mission must:
1. simulate real problems with real fixes;
2. be entertaining;
3. be intriguing;
4. be challenging;
5. draw the player into it;
6. be intuitive;
7. be correct: the right Lean methods, the right numbers.

- **Primary directives:** players learn Lean and the energy sector, and players keep playing (intriguing missions, rewarding play, hidden rewards for notable play).
- **Secondary:** process management, SAFe, Agile, DevOps, Six Sigma, IT and project management.
- Always one main mission at a time and at most three side missions.
- A dedicated agent keeps designing, auditing and improving missions; Claude tells Merijn when that stops.

### Rules
- **Progressive RPG through missions.** The player advances by completing missions. New and harder missions unlock as the player progresses; nothing is open from the start.
- **One main quest, at most three side quests.** Never more than one main mission active at once, and at most three side missions. Side missions are small.
- **Problems only arrive through missions.** The player never faces a list of problems to choose from: what is wrong right now is the active main mission's problem and at most three side missions' problems. Nothing else may switch a problem on (a fix that fades comes back through its mission).
- **Sometimes the main quest forks.** Two main missions open at once: one tackles the bottleneck, the other a non-bottleneck problem. The player has to think and prioritise; the Check shows that fixing a non-bottleneck brings no flow gain. Use forks now and then, not everywhere.
- **A senior manager is the coach.** The player can talk to the coach for insight. The coach mostly answers with a question (Toyota Kata style: target, actual condition, obstacles, next experiment, what did you learn), rarely with an answer.
- **The coach helps only with the main quest.** Asking about a side mission gets no coaching.
- **Action-based problem solving.** Clues are earned with gemba tools and questions; the player writes the A3; the simulation judges. No multiple-choice answers with one marked correct.
- **Many healthier processes, not one.** Every problem lists several countermeasures with a fit; each one is a real improvement that can pass the Check, some more than others.
- **Evidence first.** Numbers in content (norms, rates, durations, costs) come from public sources or industry norms where they exist; estimates are marked as estimates, with their reasoning, in the content file.
- **Setbacks, never game over.** Costs and claims can push the budget into debt and the region into a bad period, but the company never goes down and the game never ends in failure. Recovery is always possible.
- **Improvements must be sustained, or they decay.** Every improvement erodes over time unless something sustains it (standard work, visual management, audits, leader routines, the KPIs that steer). The weaker the sustaining habits and processes, the faster the decay; even "standardised" is not forever.
- **Stagnation is regression.** When the player stops improving, processes slowly fall behind (demand grows, people change, the sector moves on), so continuous improvement is needed just to stand still.
- **Missed deadlines have lasting consequences.** A failed mission closes a door (e.g. Henk retires and his knowledge transfer is no longer possible); the problem can still be solved another way.
- **Dutch game text; English code and docs.**

---

## 3. Skill Triggers

### Always — every task, no exceptions
- **Superpowers** — a core skill (Merijn, 2026-10-12). Check the superpowers skills before every task and use the ones that apply: `brainstorming` before designing a feature, `writing-plans` / `executing-plans` for multi-step work, `test-driven-development` for every behaviour change (watch the test fail first), `systematic-debugging` for every bug, `verification-before-completion` before calling anything done, `requesting-code-review` before a phase ends.
- **`simplify`** — run after every code change. No exceptions. Code must pass the simplification checklist before the task is considered done.

### `error-handling` — run whenever any of these are true
- A function does file I/O, database access, or network/API calls
- A `try/except` block is added, changed, or removed
- A function could silently swallow a missing key, a None, or a failed external call
- A new module is wired to an external system (persistence, AI, YAML loading)
- State could be left corrupt if an exception occurs mid-operation

### `data-validation` — run whenever any of these are true
- A new data entry point is added: YAML load, save file read, CLI arg, API response, config file
- A `dict` or deserialized structure is accessed without type or key checks
- A new field is added to the save schema or problem/countermeasure YAML
- Player input is consumed by game logic (e.g. text fields in dialogs, credit amounts)
- Any function that accepts data from outside the process boundary

### `security` — run whenever any of these are true
- File paths are constructed from any variable (not a hardcoded literal)
- A `subprocess` call is added or changed
- Credentials, API keys, or tokens are read, passed, or stored
- A new external API is called (Anthropic, any HTTP endpoint)
- Save/load operations change: new tables, new fields, new file access patterns
- Any SQL query is written or modified
- A new config value is read from environment or file at startup

### `architecture` — run whenever any of these are true
- A single function does more than one distinct thing (name would need "and")
- A module accumulates mixed concerns (e.g. rendering logic in simulation, UI logic in factory)
- A change requires edits in 4+ unrelated files (shotgun surgery smell)
- A new module becomes a dependency of 3+ other modules
- A function's parameter list grows beyond 4 parameters

### `automated-testing` — run in any of these situations
- At the end of every phase before moving to the next (required gate)
- When any new function with business logic is added (score functions, simulation logic, catalog loading, state machines)
- When a bug is fixed — write a test that would have caught it
- When a stub is replaced with a real implementation
- Verify the full suite still passes after every commit:
  - Godot logic tests (Spanning): `godot --headless --path game --script res://tests/run_tests.gd`
  - Content pipeline: `python tools/build_content.py --check`
  - Python tests (legacy factory game + content tools): `python -m pytest tests/ -v`

### `technical-debt` — run in any of these situations
- Before starting each new phase
- When a stub, placeholder, or `# Phase N: implement` comment is replaced with real code
- When a TODO or FIXME is added (address it immediately or log it as a tracked task)
- At the start of a new session after a long gap (> 1 week)

### `claude-api` — run whenever any of these are true
- Any function in `ai/` is written or modified
- The Anthropic SDK, prompt caching, or cost tracking is touched
- A new Claude model or API feature is used

### `developer-experience` — run when setup, CI, or launch scripts change

### Reference
Full skill definitions are in [SKILLS.md](SKILLS.md).
