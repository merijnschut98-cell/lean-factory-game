# CLAUDE.md — Rules Before Every Coding Session

## How enforcement works
Claude Code automatically loads this file into context at the start of every session.
**At the start of each session, confirm in your first response:** current phase from PLAN.md + the next task. This makes it verifiable.

---

## 1. Check and Update the Plan

Before writing any code, read [PLAN.md](PLAN.md).

**Every session:**
- State the current phase and next task in your first message
- Mark tasks done (✅) immediately when complete — never batch updates
- Add newly discovered tasks or sub-tasks as you find them
- Remove tasks that are no longer needed (don't leave stale entries)
- Keep PLAN.md honest: it should always reflect reality, not intent

---

## 2. Skill Triggers

### Always — every task, no exceptions
- **`simplify`** — run after every code change. No exceptions. Code must pass the simplification checklist before the task is considered done.

### On specific conditions
| Condition | Skill |
|---|---|
| Any function touches `ai/`, calls `anthropic`, or manages API cost | `claude-api` |
| Code reads external input (YAML files, save files, CLI args, API responses) | `data-validation` |
| Any `try/except`, I/O operation, or external call | `error-handling` |
| A module exceeds 300 lines or a function exceeds 30 lines | `architecture` |
| End of each phase (before moving to next) | `automated-testing` |
| Anything touching credentials, file paths, subprocess | `security` |
| Monthly or before Phase 6 | `technical-debt` |
| CI or local setup changes | `developer-experience` |

### Reference
Full skill definitions are in [SKILLS.md](SKILLS.md).
