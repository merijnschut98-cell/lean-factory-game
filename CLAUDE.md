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

## 2. Skill Triggers

### Always — every task, no exceptions
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

### `automated-testing` — run at the end of every phase before moving to the next

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
