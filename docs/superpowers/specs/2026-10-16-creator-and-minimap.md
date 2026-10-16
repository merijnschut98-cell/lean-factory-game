# The creator screen and the minimap: build spec (PLAN 2.7b, 2.1b, 2.7d)

> Status: by the mission-and-dialog design agent (Claude, 2026-10-16 evening), for the **UI agent** (the creator screen, the portrait, the pause-menu entry) and the **world agent** (the minimap). **Docs only.** Merijn was away; every open question below has one answer, logged as a call in §5 and in PLAN §10. Dutch game text, English ids and comments; numbers are marked `estimate:` where no source exists.
>
> Read with: `CLAUDE.md` §2 (immersion; nothing handed over; respect the player's time); PLAN 2.1, 2.1b, 2.7, 2.7b, 2.7d, 2.9 (`tr()`), §6.2 (a HUD element needs its appearance moment); `2026-10-16-first-five-minutes.md` (the beats: B1 the creator as HR's mail and a phone camera, B3 the walk, the minimap as Ruud's paper plan). This doc adds what those leave open: layout, controls, validation, the portrait, the drawing, the targets and the tests.

## 0. Summary

| Question | Answer (one per question) |
|---|---|
| Creator: one trait at a time or one page? | **One trait at a time**, on a trait strip like a phone camera's mode strip; every trait reachable in one click, so it is never a wizard you cannot jump around in |
| The frame | A phone held **in landscape**: the viewfinder fills the screen, the camera's controls in a column on the right, the shutter at the bottom right |
| Rotate the model | Drag with the mouse, or **Z / C** (the game's own camera keys); the framing follows the trait (face traits close, body and clothes wider) |
| Randomise | **Yes**: "Willekeurig" in the phone's top corner; it never touches the first name or the body. A new creator also *opens* on a random look, so no two players start from the same face |
| First name | 1–16 characters after trimming; letters (any script's letters with accents, e.g. é, ë, ç, ş, ğ), one space, a hyphen or an apostrophe between letters; nothing else. **No profanity filter** (§1.4) |
| Pronoun | Follows **Lichaam** (Merijn): man → hij, vrouw → zij; no separate control |
| Portrait | Rendered once at "Foto maken" (and after a later change): a 252 × 324 px PNG (passport ratio 35:45), kept in the save's meta; the save cards and the badge use it |
| "Klaar" | The shutter, the photo freezes, "Verzonden ✓", the phone goes dark, fade to B2 (the ontvangst). No extra save point |
| Changing it later | Pause menu → **"Uiterlijk"**: the same screen as "Nieuwe pasfoto", name included; free, no time passes, no story cost, no comment from anyone |
| Minimap: where and how big | **Bottom right**, round, 220 px across at 1600 × 900, 20 px from the edges; it shows about 28 m of floor across (`estimate:` one room and its neighbours) |
| Minimap: turning or north-up | **Turns with the camera by default** (up = where the camera looks, as WASD moves); north-up is a setting. The M map stays north-up |
| What is drawn | Walls and rooms (open rooms in paper white, shut rooms hatched), room names upright, the stairs and lift as symbols, people as small grey dots (all alike), the player as an arrowhead in the middle |
| Targets | One target per accepted mission, **at room level** (never a step, a clue or a tool): the main mission a filled orange diamond with a rim arrow and distance; side missions a small hollow ring and a rim notch without text |
| Out of view | A rim arrow with the walking distance ("35 m", rounded to 5 m); on another floor the arrow points to the nearest stairs or lift by route and says **"2e verdieping ↑"** or **"Begane grond ↓"** |
| In the target room | The marker and the arrow fade out over one second; nothing blinks, ever |
| First appearance | B3 leg 3, when Ruud hands over the folded plan (a fold-open animation); a returning player ("Inwerkweek overslaan") has it from the start |
| Hiding it | Instellingen → **"Plattegrond in beeld"** (aan/uit) and **"Plattegrond draait mee"** (aan/uit). It also hides itself in a talk, an explainer, a panel and the scenes of B4–B6 |
| The hard rule | **Where, never what.** No marker on a clue, a tool, a stack, a person with a concern or a check-in; no colour on any room; never more specific than the mission's briefing already was |
| Ruud's line | Added to B3 leg 6 of the first-five-minutes spec: "Mijn kamer. Voorlopig." · "Boven heb ik er een met uitzicht op het spoor. Maar boven zit ik te ver van het werk." |

---

## 1. The creator screen (UI agent; PLAN 2.7b, first five minutes B1)

### 1.1 The flow

1. **"Nieuw spel"** on the title menu fades to a phone, held upright, showing HR's mail (first five minutes B1, the text there). One button: **[Pasfoto maken]**. Esc on the mail: back to the title menu (nothing was made, nothing asks).
2. The phone **turns to landscape** (a 0.4 s rotation; `estimate:` short enough to read as a gesture, not a wait) and opens the camera: the creator.
3. The player goes through the traits in any order; **[Volgende]** walks the strip in order, **[Zo is het goed]** jumps to the shutter with what is chosen so far.
4. **[Foto maken]**: the shutter sound, a white flash at 30 % opacity for 80 ms (no full-white flash: photosensitivity), the frame freezes, "Verzonden ✓" in the phone's status line, the phone goes dark, fade to B2.

### 1.2 Layout (reference 1600 × 900; the phone frame scales with the window, never the model)

```
┌────────────────────────────────────────────────────────────────────────────────┐  phone bezel: 14 px, near-black, rounded 36 px
│ 20:14  Pasfoto · Voltana                                     [Willekeurig] ▣  │  status line: the evening before, zo 11 okt
│                                                                                │
│        ┊               ┊                    ┌──────────────────────────────┐   │
│        ┊   ┌───────┐   ┊                    │ JE VOORNAAM                   │   │  the trait strip, vertical,
│ ┄┄┄┄┄┄┄┊┄┄┄│ face  │┄┄┄┊┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │ Lichaam                       │   │  current trait in white caps,
│        ┊   └───────┘   ┊                    │ Huidskleur                    │   │  the rest muted
│        ┊   (the model) ┊                    │ Kapsel                        │   │
│ ┄┄┄┄┄┄┄┊┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┊┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │ Haarkleur · Ogen · Gezicht    │   │
│        ┊               ┊                    │ Bril · Kleding                │   │
│        ┊               ┊                    ├──────────────────────────────┤   │
│                                             │ (options: 5 swatches/chips)   │   │
│   "Zo noemen je collega's je."              │ Koperrood                     │   │  the selected option's name, always shown
│                                             │ [Zo is het goed]  [Volgende]  │   │
│                                             │                      ( ◉ )    │   │  the shutter: "Foto maken"
└────────────────────────────────────────────────────────────────────────────────┘
```

- **The viewfinder** is the 3D view: the player's character in the neutral grey photo-booth light of B1, a thin rule-of-thirds grid, and a small yellow **face square** that follows the head (as phone cameras do). The model stands left of centre, so the right column never covers it.
- **The right column** (~34 % of the width): the trait strip on top, the current trait's options under it, the option's name under the options, then the two buttons, then the shutter.
- **The line under the trait** (bottom left, in the viewfinder, white on a soft shadow): the labels and lines of first five minutes B1 ("Zo noemen je collega's je.", "Collega's spreken over je als hij of zij.", "Buiten draag je er je PBM overheen."). Traits without a line show none.
- **Options:** colour traits (Huidskleur, Haarkleur, Ogen) as five round swatches; shape traits (Kapsel, Gezicht, Bril, Kleding, Lichaam) as text chips. No rendered thumbnails: the live model *is* the preview (cheaper, and one source of truth).
- **The name step** shows a text field in the right column ("Je voornaam (op je pas)") with a live badge preview under it: a small Voltana pass with a grey silhouette, the typed name and "CI-lead · Aansluitingen". The face fills in on the pass after "Foto maken", which is the B2 payoff.
- **Framing by trait** (the camera moves, 0.3 s ease): Je voornaam, Huidskleur, Kapsel, Haarkleur, Ogen, Gezicht, Bril → head and shoulders; Lichaam, Kleding → from the knees up. No zoom control.

### 1.3 Controls

| Input | Does |
|---|---|
| Mouse: click a trait on the strip | go to that trait |
| Mouse: click a swatch or chip | choose it (applies at once) |
| Mouse: drag left/right on the viewfinder | turn the model (it eases back to facing the camera 2 s after release, so the photo is always frontal) |
| **↑ / ↓** (also W / S) | previous / next trait |
| **← / →** (also A / D) | previous / next option of the trait |
| **Z / C** | turn the model (the game's own camera keys: the creator teaches them in passing) |
| **Enter** | [Volgende]; on the last trait, [Foto maken] |
| **Tab / Shift+Tab** | move focus through the column's controls (a visible focus ring) |
| **Esc** | in the name field: leave the field; elsewhere: "Terug naar het titelmenu? Je pasfoto is nog niet gemaakt." [Terug] [Blijven] (once) |
| R | Willekeurig |

While the name field has focus, letters type (WASD, R, Z and C do not act). Gamepad comes later with the rest (2.7).

### 1.4 The first name

- **Length:** 1–16 characters after trimming (`estimate:` 16 fits the badge at its font size and covers long Dutch first names such as "Maximiliaan", "Jan-Willem", "Anne-Marie"). Typing stops at 16.
- **Allowed:** Unicode letters (category L, so é, ë, ï, ç, ş, ğ, ø and other scripts' letters pass), and between two letters a single space, hyphen `-` or apostrophe `'` (also the typographic `’`, stored as `'`). Nothing else: no digits, no symbols, no emoji, no control or direction-override characters.
- **Normalised on confirm:** trimmed, runs of spaces collapsed, NFC; if the whole name is lower case, the first letter is capitalised ("jan" → "Jan"); otherwise the player's casing stands ("deVries" stays).
- **Why the set is this narrow (security and data validation):** the name is substituted into dialog text with `{speler}` and shown in `RichTextLabel`s. Braces and square brackets can never enter a name, so a name can never become a token (`{hij_zij}`) or BBCode (`[b]`). Substitution is single-pass: a substituted value is never scanned for tokens again. The save loader runs the same validator on the stored name; an invalid stored name falls back to "Nieuwe CI-lead" (the 2.7 placeholder), never a crash.
- **Feedback** (inline, under the field, calm grey, never red): a rejected character is simply not typed, and the line says once "Alleen letters, met een spatie, streepje of apostrof ertussen." At 16: "Langer past niet op je pas."
- **Empty name at the shutter or at [Zo is het goed]:** the name step opens with "Hoe mogen we je noemen?" (once; first five minutes B1). The shutter stays disabled until there is a name.
- **No profanity filter.** The game is single-player and local; a name is never sent anywhere (the playtest log does not hold it; check `session_log.gd` keeps it out). A word list is both leaky and wrong on real names (the "Scunthorpe problem": it blocks real names such as *Dick* or *Fokke*), and refusing someone's real name breaks the one promise of the screen: this is *you*. Revisit only if a shared or online feature ever shows a name to someone else (none is planned; Phase 6 is a private build).

### 1.5 Traits and the options file

The art agent writes `game/assets/characters/creator_options.json` with PLAN 2.7b's traits. **That file's ids are the source of truth**; this spec names traits by these ids and the UI must read labels and order from the file, never hard-code them:

| Trait id (expected) | Label on the strip | Options | Notes |
|---|---|---|---|
| `name` (not in the file) | Je voornaam | text | §1.4 |
| `body` | Lichaam | man · vrouw | sets the pronoun; changing it resets `face` to the new body's first option; everything else stays |
| `skin` | Huidskleur | 5 tones | tint |
| `hair` | Kapsel | 5 per body list, any style with either body | the strip shows the body's own five first, then "Meer kapsels" with the other five |
| `hair_colour` | Haarkleur | 5 | tint |
| `eyes` | Ogen | 5 | tint |
| `face` | Gezicht | 5 per body (beard and snor for man; make-up for vrouw) | per body, as Merijn listed |
| `glasses` | Bril | 5 (incl. geen) | part |
| `outfit` | Kleding | 5 | the Lichaam/Kleding framing shows it |

If the art agent's ids differ (e.g. `hair_color`), the UI follows the file and this table is read as roles. **Check for the UI agent:** every option the UI can choose resolves to a part or a tint in the file (PLAN 2.7b's test); the creator reads the order from the file.

**Willekeurig** draws every trait except `name` and `body` uniformly from the file's options (for `hair`, from all ten). **The opening look** is a random draw too, with `body` drawn 50/50, so the model never stands there as a default mannequin; step 2 then asks the body explicitly.

### 1.6 The pronoun

`body: man` → `{hij_zij}` = hij, `{Zij_Hij_speler}` = Hij, `{haar_hem_speler}` = hem, `{jongen_meid}` = jongen; `body: vrouw` → zij / Zij / haar / meid. (`{jongen_meid}` is for Henk, who calls the player "jongen" three times in tier 1: the D9 talks audit, A12.) Derived from `player.look.body` at substitution time, never stored separately (one source; a body change later changes every later line at once). The line under Lichaam says it in the fiction: "Collega's spreken over je als hij of zij."

### 1.7 The portrait

- **When:** at [Foto maken], and again whenever the look changes later (§1.9).
- **How:** a `SubViewport` with its own fixed camera (head and shoulders, front, 0° turn, the booth light, a flat neutral grey `#9aa0a6` background), rendered once to an `Image`, 252 × 324 px (`estimate:` the passport ratio 35 × 45 mm at a size that stays sharp on a save card and a badge).
- **Where it lives:** `GameSave.meta.portrait` as PNG bytes (`estimate:` 30–60 KB), so the title menu shows five cards **without loading any 3D**. On load: at most 256 KB, must decode as PNG, must be exactly 252 × 324; anything else → the drawn placeholder of 2.7 (data validation; the save's SHA-256 already catches damage, this catches a valid save from a broken build).
- **Used on:** the save cards (2.7, replacing the placeholder and "Nieuwe CI-lead" with the name); the badge Yvonne slides across in B2 (a close-up card with the photo, the name and "CI-lead · Aansluitingen"); the pass on the character's lanyard in the world (a small texture, low priority: from close zoom only).
- **Headless:** where nothing renders (tests, the CI), the pipeline returns the placeholder and says so; it never blocks the flow.

### 1.8 What "Klaar" leads to

[Foto maken] is the creator's only "Klaar". After it: freeze, "Verzonden ✓", dark, fade, **B2 (the ontvangst)**. The look and name live in the session from that moment and reach disk at the existing save moments (every dagstart and on closing, 2.7); no new save point, so the accepted autosave rule (one shared autosave that a new game replaces) is unchanged. The playtest log records the creator's duration (first five minutes §5 measures time per beat).

### 1.9 Changing the look later

- **Pause menu → "Uiterlijk"** (between "Opslaan" and "Naar het titelmenu"). It opens the same screen without the mail and without the phone's turn; the status line reads "Nieuwe pasfoto"; the opening look is the current one, not a random one; the name is editable (a typo should be fixable); **[Foto maken]** saves and returns to the game, **Esc** asks "Wijzigingen weggooien?" once.
- **Free and silent:** no game time passes, no money, no trust, no line from anyone (no story cost, PLAN 2.7b). A body change changes the pronoun in every later line; past talks in the Mensen notebook are quotes and stay as they were said.
- The portrait is re-rendered, the badge and the save card follow at the next save.
- Not reachable during a talk, an explainer or a cutscene beat (the pause menu is not open then).

### 1.10 Text and accessibility

- Every label goes through `tr()` (2.9). The selected option's name is always printed under the options (colour-blind players read "Groen", not a swatch).
- Every control is reachable by keyboard alone (§1.3); focus is visible.
- No timer anywhere; the screen waits forever.

---

## 2. The minimap (world agent; PLAN 2.1b)

### 2.1 The drawing: a Voltana site plan, not a radar

- **Shape:** round, as Merijn asked, drawn as a round cut-out of the paper floor plan Ruud hands over: off-white paper (`#f4f1ea`), a faint fold crease across it, a thin Voltana-blue ink rim (2 px). No sweep, no glow, no grid of rings.
- **Lines:** walls in dark grey ink (1.5 px), doors as gaps, rooms filled paper white when open and **hatched** grey when shut (the M map's "▦ Dicht"); the stairs as the architectural stair symbol (treads and an arrow), the lift as a box with a cross. Desks are not drawn (they would make it a game map of objects).
- **Room names:** in small caps, centred in the room when the room's centre is inside the circle, always upright on screen even when the map turns. Text through `tr()`.
- **People:** small grey ink dots (5 px), **all alike**. No colour for mood, energy, a check-in, a concern or a mission role (§2.6).
- **The player:** a dark-green arrowhead (the M map's `GREEN_DARK`) at the centre, pointing where the character faces.
- **Colours:** paper, ink grey, Voltana blue for the rim, safety orange only for the main target, a muted blue-grey for side targets. Nothing blinks or pulses, ever.

### 2.2 Size, corner, scale

- **Bottom right**, 220 px across at 1600 × 900 (scaled with the HUD), 20 px from the right and bottom edges. The toasts (today bottom right in `hud.gd`) stack **above** it. The place prompt (bottom centre) and the help line (bottom left) are untouched.
- **Scale:** fixed, 28 m across (`estimate:` one room and its neighbours on the 1e; the whole floor is the M map's job). No zoom control.

### 2.3 Turning or north-up

- **Default: turning.** Screen-up is the camera's forward, so "up on the plan" is "forward on W". A small "N" sits on the rim where north is. The room names stay upright.
- **Setting:** "Plattegrond draait mee" (aan by default). Off → north-up, the player's arrow turns instead.
- The **M map stays north-up** (an overview is read, not steered by).

### 2.4 Targets

**One target per accepted mission, at room level.** A target is resolved by a pure function (testable without the world), `MinimapTargets.of(mission, session) -> {kind, room?, person?, floor} | null`:

| Mission goal | Target (the next "where") |
|---|---|
| `talk_to {dialog}` (not yet met) | the person of that dialog: their dot gets the target ring, wherever they are |
| `walk {stream}` | the room of the first step of the stream not yet seen |
| `observe {places}` | the room of the first goal place not yet observed |
| `check` / `solve {problem}` | the room the briefing sends the player to (the room of the problem's step, or the mission's optional `where:` room) until the A3 is ready for a Check; then the **Obeya** |
| any other goal, or no place | **no target** (no marker, no arrow) |
| an opening beat (2.7d) | the beat's own target: Aansluitingen on the walk (B3 leg 3), the exit in B6 |

Rules:
- **Room, never the place.** The target is a room (or a person); a room with two steps (Aansluitingen: Intake and Werkvoorbereiding) never says which one. **The target is never more specific than the briefing already was** (content check: a `where:` room must be named in the briefing text).
- **Offered is not accepted:** an offered mission on the board has no target.
- **Main:** a filled safety-orange diamond (10 px) on the target room's door, or a ring around the person's dot. In a fork (two mains), both.
- **Sides:** a small hollow blue-grey ring (7 px); no distance text. At most three (the 1 + 3 rule).

### 2.5 Out of view: the rim arrow, distance and floors

- A **main** target outside the circle becomes an orange arrow on the rim, pointing along the **walking route** (the first leg of the path from `office_nav`, not the straight line through walls), with the **route distance** under it: "35 m", rounded to 5 m, never below "5 m", updated at most four times a second.
- A **side** target outside the circle is a short blue-grey notch on the rim, no text.
- **Another floor:** the arrow points to the nearest of the stairs and the lift **by route length**, and the text reads the target floor and the direction: **"2e verdieping ↑"**, **"1e verdieping ↓"**, **"Begane grond ↓"** (floor names from `content/world.yaml`). On the stairs or in the lift the minimap shows the stairwell; on arrival the arrow resumes for the target on that floor.
- **Another building or the town** (2.2 onwards, Phase 4): the arrow points to the exit and names the place ("Werf", "Lindeveld"), as 2.1b says. Not built now; the target function returns `{kind: "exit", name}` so the drawing needs no change later.

### 2.6 Where, never what (the hard rule)

The minimap shows **where the mission is**, never **what is wrong**:
- no marker on a clue, a stack, a board, a tool's place or any interactable other than the target room's door;
- no colour, heat or highlight on a room or step (nothing that reads as "the bottleneck is here");
- no marker on a person with a concern, an open check-in or a low energy bar (the energy bar lives in the world only, 1.2);
- no text but room names, the distance, a floor and an exit name;
- the target never more specific than the briefing (§2.4).
This is a test (§4.2), not a guideline.

### 2.7 Fading in the target room

When the player enters the target room (the room's rect contains the player), the main marker and its arrow **fade to 0 over 1 s** and stay gone while the player is in the room; they fade back in over 1 s on leaving. A person target's ring fades when the player is within 3 m of them (they are then in reach of E, 1.6 m, a step or two away). A side marker fades the same way.

### 2.8 When it appears and when it hides

- **First appearance:** B3 leg 3, when Ruud hands over the folded plan: the minimap **unfolds** in its corner (two 0.3 s folds), with the rim arrow already pointing to Aansluitingen. Stored as `SessionLayer.has_floor_plan` (saved; old saves and "Inwerkweek overslaan" → true).
- **Hides itself** (fade 0.2 s) while a talk, an explainer, any panel (A3, Check, map, journal, codex, board, pause), the terugblik card or a cutscene beat (B4, B5, B6's skip) is open; it returns when they close. A talk shows only the date and time (dialog UI audit U9).
- **Settings** (Instellingen, 2.7): "Plattegrond in beeld" (aan) and "Plattegrond draait mee" (aan). When hidden by the setting, nothing replaces it; the M map still works.

### 2.9 Performance and code

Drawn in code like `OfficeMap` (a `Control` with `_draw`, reusing `OfficeFloors.map_plan` and `OfficeMap.project`); redrawn when the player moves more than 0.1 m or turns more than 2° (`estimate:`), not every frame. `OfficeMap.mission_places` is the M map's; the minimap uses the new room-level `MinimapTargets`.

**Follow-up found while writing this (⬜, UI agent):** the M map marks `place:<problem step>` for a `solve`/`check` mission (`office_map.gd` `mission_places`), so its orange pill names the step, which can be more specific than the briefing. Align the M map with §2.4: mark the room (or the `where:` room), and the obeya once the A3 is ready.

---

## 3. Ruud's line on the first walk (first five minutes B3, Merijn Q10)

Merijn confirmed on 2026-10-16 that Ruud sits with Aansluitingen by choice in the first hundred days. The line goes at the **end of leg 6**, at the door of his room on the 1e (where B4 begins), in his voice (short; one idea a line; no jargon; self-mocking, never a lecture):

> *(Ruud opens a glass door at the edge of the open office: a small room, a desk with a ring from a coffee cup, a whiteboard.)*
> **Ruud:** "Mijn kamer. Voorlopig."
> **Ruud:** "Boven heb ik er een met uitzicht op het spoor. Maar boven zit ik te ver van het werk."

It does not explain gemba, it shows it (nothing handed over). A player who overtook him hears "Je vond het zelf. Goed teken." first, then the same two lines. When the 2e opens in Act II and he moves up, his first line in the new room can echo it ("Uitzicht op het spoor. Ik moet vaker naar beneden.", a suggestion for the Act II writer). Added to the first-five-minutes spec, B3 leg 6.

---

## 4. Tests (what a test can assert)

### 4.1 Creator (UI agent; Godot, headless)

1. **Options:** every trait in `creator_options.json` has 2–5 options (`hair`: 5 per body list), every id resolves to a part or a tint (2.7b's test), and the creator's strip order equals the file's.
2. **Name validator** (a table test on the pure function): accepted "Sanne", "Jan-Willem", "Anne Marie", "D'Angelo", "Şeyma", "Zoë", "Bo"; normalised "  jan  " → "Jan", "anne  marie" → "Anne marie", "deVries" unchanged, "D’Angelo" → "D'Angelo"; rejected "", "   ", 17 letters, "R2D2", "{speler}", "[b]Jan[/b]", "-Jan", "Jan-", "Jan--Piet", "Jan  ", an emoji, a U+202E override, a newline.
3. **Single-pass tokens:** a player named "Hij" in a line with `{speler}` and `{hij_zij}` renders once; no value is re-substituted.
4. **Pronoun follows body:** `body: man` → hij/Hij/hem/jongen, `vrouw` → zij/Zij/haar/meid; changing the body changes the next line rendered.
5. **Body change resets `face`** to the new body's first option and keeps `skin`, `hair`, `hair_colour`, `eyes`, `glasses`, `outfit`.
6. **Willekeurig** never changes `name` or `body`, and always yields ids in the file (1,000 draws).
7. **The opening look** is random (two creators with different seeds differ) and valid.
8. **Zo is het goed** jumps to the shutter; with an empty name it opens the name step with "Hoe mogen we je noemen?" once; the shutter is disabled without a name.
9. **Keyboard only:** a scripted run of key events (↓, →, typing, Enter) reaches B2 with the chosen look; letters typed into the name field do not move the trait or option.
10. **Portrait:** returns a 252 × 324 image, or the placeholder in headless; the save meta round-trips it; a portrait over 256 KB, not a PNG or the wrong size loads as the placeholder.
11. **Save:** `player.look` and the name round-trip; an unknown option id falls back to the trait's first option; an invalid stored name falls back to "Nieuwe CI-lead".
12. **Uiterlijk** from the pause menu: game time, budget, missions and People are identical before and after (a state diff); the save card's name and portrait follow.
13. **No HUD and no game time** during the creator; no `tr()`-less string in the screen (the 2.9 test).

### 4.2 Minimap (world agent; Godot, headless; the target function needs no world)

1. **Targets per goal type** on the content's missions: `talk_to` → the person; `walk` → the first unseen step's room; `observe` → the first unobserved place's room; `check`/`solve` → the briefing's room, then the Obeya once the A3 is ready; a goal without a place → `null`.
2. **Room level:** for every tier-1 mission, the target is a room id or a person id, never a place id.
3. **Never more specific than the briefing:** for every mission with `where:`, the room's Dutch name occurs in its briefing (content check in `build_content.py`).
4. **Where, never what:** the minimap's drawn items are only walls, rooms, room names, stairs, lift, people dots, the player, targets, arrows and notches; no item is created from a clue, a tool or an interactable other than a target room door. People dots have one colour, whatever their energy, check-in or concern.
5. **Accepted only:** an offered mission has no target; at most one main (two in a fork) and three side targets are drawn.
6. **Rim arrow:** a main target outside the 14 m radius gives an arrow and a distance; inside, a marker and no arrow. The distance is the route length rounded to 5 m (a target behind a wall reads longer than the straight line).
7. **Floors:** from the 1e, a target on the 2e points to the nearer of stairs and lift by route and reads "2e verdieping ↑"; from the 2e, a target on the begane grond reads "Begane grond ↓".
8. **Fading:** in the target room, the marker's alpha reaches 0 within 1.1 s and stays 0; on leaving, it returns. No tween or animation loops on any minimap item (no blinking).
9. **Turning:** with the setting on, the map's rotation equals the camera's yaw; off, it is 0; room names have screen rotation 0 in both.
10. **Appearance:** hidden before `has_floor_plan`; visible after B3 leg 3; true for "Inwerkweek overslaan" and old saves; saved and restored.
11. **Hides:** hidden while a talk, an explainer, any panel or a cutscene beat is open; the setting "Plattegrond in beeld" off hides it with nothing in its place.
12. **Layout:** at 1600 × 900 the minimap's rect does not overlap the toasts, the help line or the place prompt.

---

## 5. Claude's calls (for PLAN §10)

1. **The creator shows one trait at a time on a phone camera's mode strip**, every trait one click away; the phone in landscape; options as swatches and chips, no thumbnails.
2. **Z / C and drag turn the model**; framing follows the trait; no zoom control.
3. **Willekeurig exists and the creator opens on a random look**; neither touches name or body.
4. **First name: 1–16 characters, letters with a space, hyphen or apostrophe between them**; braces and brackets can never enter (token and BBCode safety).
5. **No profanity filter**: local, single player, never sent; revisit only for a shared feature.
6. **The portrait is a 252 × 324 PNG in the save's meta**, so the title menu never loads 3D.
7. **No new save point after the creator**; the existing dagstart and close saves keep it.
8. **"Uiterlijk" in the pause menu includes the name**, free and silent.
9. **The minimap sits bottom right, 220 px, 28 m across**, the toasts above it.
10. **It turns with the camera by default**; north-up is a setting; the M map stays north-up.
11. **Targets are rooms (or a person), never places**, and never more specific than the briefing; only the main mission gets a distance.
12. **Distances follow the walking route**, rounded to 5 m.
13. **People are grey dots, all alike.**
14. **Two settings**: "Plattegrond in beeld" and "Plattegrond draait mee".
15. **Ruud's room line** ("Boven zit ik te ver van het werk.") closes the walk at his door.
