# Work saved at the weekend break (2026-10-17, Merijn: "take a break")

Every agent's work that was not yet on the branch, as binary patches against
origin at the time of saving (`git apply --binary <file>` on a fresh branch from
that commit, or merge the agent branch if its worktree still exists).
None of these has passed the coordinator's gate yet; each was gate-green in
its own worktree unless marked otherwise.

| Patch | Agent | What | State |
|---|---|---|---|
| agent-a127ba555e9b45656-committed | devex | route test 590 s -> 196 s (results proven identical); new_game warms up once per seed (suite 2043 s -> 822 s); per-test timing flag | gate-green in its worktree |
| agent-a2b7676723089d552-committed | D9 builder | D9 third-pass checklist (check-in prompts, #45-#51), the two Act II side talks pasted (Petra, Wim) | committed; last gate status unknown (limit) |
| agent-af5cf6a11c46abaa7-committed | UI | Act 0 teaching UI (f03742b, gate-green 844/0) and De eerste vijf minuten B2-B7 as one scene (764b315, gate not confirmed) | land f03742b first |
| agent-a9b792fd50ccc9c33-committed | world | Dirk, Gert, Saskia, Wim (7c62b18, gate-green 839/0); the yard spec and model (2.2) | yard WIP |
| agent-a9b792fd50ccc9c33-uncommitted | world | the yard's people, in progress | unfinished |
| agent-ab6e9c0668bc3f824-uncommitted | QA | autoplay personas talker / never-talks, report not yet regenerated | unfinished |

Landing order when work resumes (one at a time, PLAN §6.2): devex, UI f03742b,
world 7c62b18, D9, UI 764b315, the yard, then QA's report.
