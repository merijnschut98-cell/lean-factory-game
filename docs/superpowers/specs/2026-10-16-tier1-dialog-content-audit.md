# Tier-1 dialogs in content: audit of the builder's first dialogs

> Status: by the mission and dialog design agent (Claude, 2026-10-16), PLAN 1.6 follow-up and the continuous dialog audit (CLAUDE.md §2). **Docs only.** It audits the dialogs that will enter `content/` first: `content/dialogs.yaml` in the unmerged dialog-engine patch (`docs/handoff/dialog-engine-f5319f4.patch`, PLAN 1.1). The builder applies the fixes when the patch is merged, or right after.
>
> Read with: the dialog spec; the Acts 0–II scripts (§1.1 schema additions, R-D1 to R-D5, §3.3 and §3.4 the rewritten samples, §7 Frank); the four-tier audit §4, §6 and §7; the arc `2026-10-16-drie-winters-arc.md` (which reads Frank's facts).

## 0. Summary

The patch carries three people (Joost, Frank, Ahmed), the shared bank and three dialogs: `joost_output_kpi`, `frank_kpi_targets` and `ahmed_after_henk`. The engine work is sound. The content is the **spec's first draft** (§7–§8), not the audited rewrites in the Acts 0–II scripts (§3.3, §3.4, §7). That matters in four ways:

1. **Fixes already decided are missing:** the false experience line and the promise nobody tracks (F9, F12); the warning and the in-character ruined lines (R-D3, R-D4); Joost's human moment (F8).
2. **Facts the arc reads are never set:** `frank_kpi_targets` sets neither `heard:frank_budget` nor its key clue. The interim director's MT (drie-winters §5.2) reads `heard:frank_budget`; as built, a player who listened to Frank gets nothing for it in winter 2.
3. **The bank makes one route win everywhere.** The bank reply to a landed open question is tagged `claim`, so a paraphrase always lands after it; the bank reply to `mood` is tagged `feeling`, so a reflect always lands after it. With these two tags, "open question → paraphrase → mood → reflect" opens every person the same way: the formula drift of the four-tier audit, built into the engine's defaults.
4. **The bank's outcome defaults are a narrator.** Any dialog without its own outcome lines speaks "Goed. Ik doe mee, en ik sta erachter." Frank, as built, has no outcome lines at all.

Each finding has a fix below (§2). Scores for the three dialogs as built: **Joost 26/35, Frank 22/35, Ahmed 24/35** (the scripts' rewrites score 30, 29 and 29).

## 1. Scores as built (7 criteria, 1–5)

| Criterion | `joost_output_kpi` | `frank_kpi_targets` | `ahmed_after_henk` |
|---|---|---|---|
| Real | 4 | 4 | 5 |
| Entertaining | 3: no coffee, no joke, no warning | 2: no outcome lines; the bank speaks for him | 3 |
| Intriguing | 4 | 3: one route, no team-lead route | 3 |
| Challenging | 4 | 3 | 4 |
| Draws in | 4 | 3: no fact for later (§0.2) | 3: no TWI variant |
| Intuitive | 4 | 4 | 4 |
| Correct | 3: the commitment line breaks the voice sheet ("Afgesproken." in a tier already at the limit is fine; the line is new and generic) | 3: rule_bound, but `reflect` in the concern's `via` (lands at half) | 2: the CI lead claims a monteur's first year (F9) |
| **Total** | **26** | **22** | **24** |

**Would a player quit here?** At Frank: yes, at the end. The block is honest, but the summary card reads the bank's "Dat kan ik niet toezeggen." and the journal holds one route. The scripts' version gives him a voice and gives the player a second way (Joost and Sanne explain it themselves): people bring their boss along.

## 2. Findings and fixes

| # | Finding | Where | Fix |
|---|---|---|---|
| C1 | **The spec draft, not the audited rewrite.** | all three | Replace each dialog's content with the Acts 0–II scripts' version: `joost_output_kpi` §3.3, `ahmed_after_henk` §3.4, `frank_kpi_targets` §7. Keep the engine's field names where they differ (`name`/`text` on proposals for the scripts' `label`/`say`), or add the scripts' fields to the schema (Acts 0–II §1.1). Recommended: **adopt `label`/`say`** (§3 Q1), because a proposal needs both a short chip text and the player's spoken line. |
| C2 | **The experience line is false** (F9): "Mijn eerste jaar belde ik ook steeds iemand." The CI lead was never a monteur. The bank has the same flaw: "Toen ik net begon, had ik precies dat." | `ahmed_after_henk.lines.experience`; `bank.player.experience` | Dialog: "In mijn eerste maand hier belde ik Ruud drie keer per dag. Niemand vond dat raar." Bank: "In mijn eerste weken hier wist ik ook niet waar ik moest beginnen." The player's experience is the CI lead's own, always. |
| C3 | **A promise the game does not keep** (F12): "Ik loop vaker even langs." | `ahmed_after_henk.lines.close` | "Fijn dat je het vertelde." |
| C4 | **Frank sets no facts.** No `unlocks` on his concern. | `frank_kpi_targets` | `unlocks: {clue: {key: true, depth: 2, text: "'De directie vraagt elk kwartaal naar aantallen. Hoe lang een klant wacht, vraagt alleen de ACM. Eén keer per jaar.'"}, facts: [heard:frank_budget]}` (scripts §7). The arc's interim MT reads it. |
| C5 | **Frank has one block route.** | `frank_kpi_targets.block.routes` | Add the scripts' second and third routes: `{all: [partial:joost_output_kpi, partial:sanne_kpi, reputation>=40]}` ("Als Sanne en Joost het zelf komen uitleggen, sta ik er niet alleen voor.") and `{all: [forecast_positive:kpi_board]}`. Route 1 stays the unclosable one. |
| C6 | **Frank has no outcome lines.** The bank's defaults speak for him. | `frank_kpi_targets.outcomes` | The scripts' five lines (commitment "Goed. Ik zet mijn handtekening eronder. …", blocked, heard, compliance, ruined). |
| C7 | **No `warning`, no in-character ruin** (R-D3, R-D4). | Joost, Frank, Ahmed | Scripts: Joost "Hm. Ik heb hier eigenlijk geen tijd voor." / "Je kwam binnen met je antwoord al klaar. Dan moet Ruud het maar tegen mij zeggen."; Frank "Ik heb een regiegroep. Kom ter zake."; Ahmed "Ik moet zo weer rijden, hoor." |
| C8 | **Bank tags make one route win everywhere** (§0.3). | `bank.replies.open_question.lands` (`claim`), `bank.replies.mood.lands` (`feeling`), `bank.replies.reflect.misses` (`feeling`) | Bank replies carry **no** `claim` or `feeling` tags. Only authored lines (position, layers, a dialog's own `replies`) carry tags, so whether paraphrase or reflect lands depends on what *this* person said. A dialog that wants a bank-like line to carry a feeling authors it in its own `replies`. Content test T6 (four-tier audit §7) then catches a universal route. |
| C9 | **The bank's outcome defaults are a narrator** (§0.4). | `bank.outcomes` | Keep them only as a fallback for check-ins and experts. **Validator rule:** a `persuade` dialog must author `commitment`, `partial`, `heard`, `compliance` and `ruined` (and `blocked` when it has a block). Test T1 counts authored lines only. |
| C10 | **Ahmed's variant misses TWI.** | `ahmed_after_henk.variants[0].needs` | `{any: [chose:knowledge_drain:skills_matrix_buddy, chose:knowledge_drain:twi_job_instruction]}` (scripts §3.4). |
| C11 | **Ahmed's trigger has no beat delay.** It fires as soon as Henk's mission ends and morale is under 50, so the check-in can come the day after the farewell. | `ahmed_after_henk.trigger` | `{beat: henk_farewell, after_days: 16, morale_below: 50}` (scripts §3.4): grief needs a little time before a talk can help. |
| C12 | **Frank's recurring line differs from the voice sheet.** People: "Het staat in het jaarplan." Voice sheet: "Dat moet ik kunnen uitleggen." | `people.frank.voice` | Use the voice sheet's line; "jaarplan" stays in his position. |
| C13 | **Frank's concern `via` holds `reflect`** (rule_bound: reflect lands at half), and his lead-in "Kijk… (zucht)" is a feeling written as a hesitation. | `frank_kpi_targets.layers.concern` | Scripts: `via: [inquiry, silence, empathy]`, lead-in "En daar komt bij…" (a hesitation; silence is his key, which fits a man who never says what he feels). |
| C14 | **Joost's commitment line is new and generic:** "Afgesproken. En ik vertel het mijn team zelf." | `joost_output_kpi.outcomes.commitment` | Scripts: "Afgesproken. En als het eerst slechter wordt, zeg ik dat zelf in het MT. Voordat Frank het vraagt." It answers *his* concern (the dip), which is what a commitment line should do. |
| C15 | **No `beats_after`** for the partial that upgrades when Frank signs (F6). | `joost_output_kpi` | `beats_after: [{when: "committed:frank_kpi_targets", text: "Frank heeft getekend. Nu sta ik er ook echt achter."}]`. |

## 3. Questions, decided by the standing rule

1. **Proposal fields.** **(a) Adopt the scripts' `label` (chip) and `say` (spoken line), keeping `text` as an alias during the merge.** (b) Keep `name`/`text`. *(a) every later script uses `label`/`say`; one schema saves a conversion per tier.*
2. **Bank tags.** **(a) No `claim` or `feeling` tags on bank replies (C8).** (b) Keep them and rely on the route test. *(a) removes the cause; (b) only measures it.*
3. **Required outcome lines.** **(a) Required for every persuasion (C9).** (b) Recommended only. *(a) is the only way the opener limit can hold.*

## 4. Log

- **2026-10-16, after the merge.** The engine is merged (PLAN 1.1) and `content/dialogs.yaml` holds the same three dialogs as the patch, plus Ruud's coach bank (`bank.coach`: K1–K5 in turn, `after` lines for pressure, ruin, block and commitment). The coach lines are in his voice and name no move: no finding. C1–C15 above all still apply to the merged content. One addition: **C16**, Ruud's `after.pressure` line says "Wat zei het gezicht erbij?" where the spec has "Wat zei zijn gezicht?"; the neutral form is right (a person may be a woman), keep it.

## 5. Next in this audit

As the builder adds tier-1 dialogs to `content/dialogs.yaml`, each is checked against: its script (Acts 0–II), the voice sheet (four-tier audit §6), the content-test rules T1–T11, and the facts the later tiers and the arc read (§2 there). Findings are added here, newest first.
