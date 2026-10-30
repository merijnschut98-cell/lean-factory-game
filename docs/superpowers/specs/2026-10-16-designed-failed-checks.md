# One designed failed Check per act

> Status: by the mission and dialog design agent (Claude, 2026-10-16), PLAN §4.2.3. **Docs only.** For the builder (content) and the simulation checker (`game/tools/draft_check.gd`): each design names the rule that makes the first Check fail, and a content test that proves it on the real network before the mission ships.
>
> Read with: PLAN §4.2.3 ("every act gets one mission where the *expected* first Check fails, a lagging KPI or a wrong but plausible cause, and the real lesson is in the retry; the debrief for a failed Check must be the best-written text in the act"); the Check rules (PLAN §10, "the Check and recovery from debt": a pass needs the countermeasure to work, fit × maturity ≥ 0.5, **and** the predicted KPI to move by more than 2 %; a too-early countermeasure fails as `too_early`; a non-constraint fails as `not_moved`); `game/src/rules/pdca.gd` (`effectiveness`: a countermeasure two tiers above the region's maturity works at its `minimal` multiplier, one tier above at `reduced`); the tier drafts; D6 *Terug naar de gemba* (audit §4).

## 0. Summary

| Act | Mission | The expected first A3 | Why the Check fails (the rule) | The lesson in the retry |
|---|---|---|---|---|
| I | `fix_done_but_not_closed` | "Het registratiesysteem is te traag" → `automatic_ean_registration` | **Too early:** a tier-3 countermeasure at maturity 1 works at `minimal` (0.25 × 0.9 = 0.23 < 0.5) | A batch is waiting, not work. Close out at completion first; automate later. |
| II | `fix_digging_damage` | "De kaart klopt niet" → `revision_at_source` | **Too early:** tier 3 at maturity 1–2 (0.15–0.30) | The cause is right, the order is wrong: contain with test trenches now, fix the map in De revisieberg. Linked causes have a sequence. |
| III | `fix_cause_unknown` | "Zoek de herhaalstoringen" → `repeat_fault_analysis` | **Too early:** tier 3 at maturity 2 (`reduced`, 0.5 × 0.9 = 0.45) | You cannot analyse what nobody recorded. Record first (cause codes), then analyse. |
| IV | `t3_kaizen_week` | The kaizen week where the dashboard says the work waits | **Not the constraint:** regional averages point at Nova's Werkvoorbereiding; Havenzij's design holds the flow (`not_constraint`) | The false bottleneck: the data says one step, the gemba another (PLAN §4.2.4). |
| V | `fix_maintenance_calendar` | "Minder storingen" predicted on `outages` lead time | **A lagging KPI:** within the Check's horizon risk-based maintenance frees inspection hours; fewer faults come next winter, inside the noise now | Leading and lagging at asset scale: predict what the fix moves *now* (the inspection lead time), and look for the outage minutes at the audit and in winter. |
| VI | `fix_field_app_bypassed` | "De monteurs ontwerpen hun eigen afmeldschermen" → `po_rides_along` with the redesign, predicted on close-out first-time-right | **Not shipped:** the redesign is `release_gated`; the Check runs before the next release | A finished fix is not a delivered fix. The chapter's next mission (`fix_release_twice_a_year`) is the retry. |

**Rules for all six:**
1. **The expected A3 is a good A3.** Each first attempt follows the clues a careful player finds first, and each is *right in direction*. The failure is never "you guessed wrong"; it is "you were right too soon", "you measured the wrong moment", or "you were right at the wrong place". That keeps the failure fair and makes the retry feel like learning, not punishment.
2. **Every countermeasure stays a real improvement that can pass** (CLAUDE.md §2: many healthier processes). The tier-3 countermeasures pass later, at the right maturity; the lagging KPI moves later; the gated fix ships later.
3. **The failed-Check debrief is the act's best text.** It has five parts: what you predicted; what the Check saw; the number that *did* move (if one did); what that means, in one sentence; one question. A person speaks last. It never says "fout" and never names the right countermeasure.
4. **The retry is short and visible:** a second A3 on the same problem, with the earlier attempt shown as "eerder geprobeerd" (already built for repairs) and the Check's line next to it. D6 *Terug naar de gemba* fires when the player visits the gemba again between the failed Check and the second A3, as audit §4 designed.
5. **Ruud's reflect question after the failed Check** (main missions only) names the moment, not the answer.
6. **A player who avoids the trap is not punished.** The careful player who picks the tier-1 countermeasure first passes and never sees this debrief. The game does not force a failure; it designs the most likely one well.

---

## 1. Act I: `fix_done_but_not_closed` (Klaar maar niet af)

**The trap.** The briefing is the El Amrani heat pump that stays off because "uw EAN bestaat niet". The first clues are the two-week wait at "administratief open" (data) and Petra's quiet desk (queue count: a red herring, "het team heeft tijd over"). Petra's own words are "één keer inloggen" in a slow system. The modern-sounding fix is **automatic EAN registration** (fit 0.9). It is right in direction, but it is a tier-3 countermeasure: in Act I (maturity 1) it works at its minimal level, and the Check says `too_early`.

**The rule.** `Pdca.effectiveness`: gap = 3 − 1 = 2 → `minimal` (0.25) × 0.9 = 0.225 < 0.5.

**The failed-Check debrief** (`debrief_variants.too_early`):

> Je voorspelde dat de afhandeling sneller zou gaan als de computer de EAN-codes zelf aanmeldt. De Check zegt: half. Het systeem is gekoppeld, maar de dossiers wachten nog steeds tot het einde van de maand, want zo is de afspraak. De computer meldt nu sneller aan wat Petra hem één keer per maand geeft. Het wachten zat niet in het systeem. Het zat in de maand. Wat zou er gebeuren als je een dossier afhandelt op de dag dat het klaar is, met de hand, zoals het nu kan?
>
> Petra: "Die koppeling is mooi. Volgend jaar. Maar ik heb hem niet nodig om morgen te beginnen."

**Ruud** (reflect): "Wat probeerde je eigenlijk te versnellen: het werk, of het wachten?"

**The retry.** `close_out_at_completion` (tier 1, fit 1.0), predicted on lead time. The second debrief adds one line: "De koppeling komt terug in het investeringsplan. Dan helpt hij wel." (path: `automatic_ean_registration` is offered again at maturity ≥ 2).

**Content test.** On the real network at maturity 1, `automatic_ean_registration` fails as `too_early`; `close_out_at_completion` passes on `lead_time`.

---

## 2. Act II: `fix_digging_damage` (Graafschade)

**The trap.** The cable strike at De Linde. The strongest clue a player finds is "bij de helft van de schades lag de kabel anders dan op de KLIC-kaart" (documents, depth 1). The obvious fix is to fix the map: **revision at the source** (fit 0.6 here, 1.0 in De revisieberg). It is the right cause. It is tier 3, in Act II at maturity 1–2: `too_early`.

**The rule.** gap 2 → 0.25 × 0.6 = 0.15; gap 1 → 0.5 × 0.6 = 0.30. Both < 0.5.

**The failed-Check debrief**:

> Je voorspelde minder graafschade, omdat de kaart beter zou worden. De Check zegt: nauwelijks. Je had gelijk over de kaart. Maar een kaart die vanaf vandaag goed wordt bijgehouden, laat de tweehonderdveertig oude fouten liggen, en de graafmachine van morgen staat op een oude. Gert graaft volgende week weer, op de kaart van vorig jaar. Wat kan er vóór die tijd veilig, terwijl de kaart wordt rechtgezet?
>
> Gert: "Een goede kaart is mooi. Volgende week heb ik een schop in de grond. Wat doe ik dan?"

**Ruud** (reflect): "Welke van de twee oorzaken kun je deze week veilig maken, en welke vraagt een jaar?"

**The retry.** `standard_test_trenches` (tier 1, fit 0.8, `safety` category: containment for the safety risk now; audit §2.4.1) passes. The debrief points at the next mission: "De kaart is het volgende probleem. Mieke weet het al." (De revisieberg follows, decided order.)

**Content test.** At maturity 1 and 2, `revision_at_source` fails on this problem as `too_early`; `standard_test_trenches` passes.

---

## 3. Act III: `fix_cause_unknown` (Oorzaak: onbekend)

**The trap.** Three outages at De Linde, each with cause "onbekend". The data clue: repeat outages on the same streets. The analytic instinct: **repeat-fault analysis** (fit 0.9, tier 3). At maturity 2: `reduced`, 0.45, `too_early`. And it is too early for a reason the player can see: there is nothing in the cause field to analyse.

**The failed-Check debrief**:

> Je voorspelde dat een analyse van de herhaalstoringen de storingen in het noorden zou verminderen. De Check zegt: bijna niets. De analyse is gedaan. Ze vond dat de oorzaak bij de meeste storingen 'onbekend' is. Je kunt geen patroon vinden in een veld dat niemand invult. Ruben vult het niet in omdat hij om drie uur 's nachts niet zeker weet wat het was, en 'onbekend' is één klik. Wat moet er eerst gebeuren, en door wie?
>
> Ruben: "Als je wilt dat ik het invul, moet ik het wel zeker mogen weten. Of mogen zeggen dat ik het niet zeker weet."

**Ruud** (reflect): "Wat meet je eigenlijk, als niemand het opschrijft?"

**The retry.** `cause_codes_pareto` (tier 2, fit 1.0) or `stop_and_record` (tier 1, 0.7) passes. The debrief of the second Check: "Over een halfjaar staat er genoeg in het veld om te analyseren. Dan is je eerste idee het goede." (`repeat_fault_analysis` passes at maturity 3.)

**Content test.** At maturity 2, `repeat_fault_analysis` fails as `too_early`; `cause_codes_pareto` passes.

---

## 4. Act IV: `t3_kaizen_week` at the false bottleneck

**The trap.** The kaizen week goes "daar waar het de hele stroom ophoudt". The MT's dashboard (averages over Zuidmark; under the regime, Frank's dashboard; with `flag:vsm_bought`, the bureau's VSM) shows Nova's Werkvoorbereiding as the longest queue: Nova is the biggest area, so its average dominates. After the Havenzij fork, the stream's real constraint is Havenzij's design team. A player who reads the dashboard holds the week in Nova.

**The rule.** The kaizen goal's short Check at a non-constraint step: `not_constraint` (C12, tier-3 draft §1.6 `debrief_variants.not_constraint`), with the flow measure unmoved.

**The failed-Check debrief** (replaces the draft's shorter `not_constraint` text):

> Vijf dagen. Het team van Werkvoorbereiding Nova heeft zijn eigen werk opnieuw ingericht, en het is beter: het oudste dossier ligt er {days_before} dagen in plaats van {days_after}. Maar er gaan in Zuidmark niet meer aansluitingen per week door. Het dashboard liet Nova zien omdat Nova groot is. Het werk dat de stroom ophoudt, ligt in Havenzij, op een tekentafel met een vergrootglas ernaast. Een gemiddelde wijst naar waar het meeste werk is. Niet naar waar het wacht. Wie had je dat kunnen vertellen, als je het had gevraagd?
>
> Yusuf, aan de telefoon: "Ik zag op het dashboard dat Nova een kaizenweek kreeg. Mooi voor ze. Wij hebben er zes weken achterstand bij."

**Ruud** (reflect, by phone if seconded): "Wat had je in Havenzij gezien, als je er een dag was gaan staan?"

**The retry.** The second team-led kaizen week through `lsw_layered_audit`'s next cycle (decided tier-3 Q5) at Havenzij's design step. It is also the regime's way back (arc doc §7.3) when it is team-led. Nova's week is not wasted: its gain holds as a fix at a non-constraint (the debrief says so: "Nova is beter georganiseerd. Dat blijft.").

**Content test.** After either fork branch, the constraint of `hz_connections` + `connections` combined is Havenzij's design on the real network; a kaizen at `connections.design` reports `not_constraint` and no throughput gain.

---

## 5. Act V: `fix_maintenance_calendar` (Onderhoud op de kalender)

**The trap.** The briefing is about a joint that failed in a street the calendar had just inspected. The player, and the MT, want fewer faults. The natural A3 predicts **outage lead time** (or outage minutes). Risk-based maintenance is the right countermeasure. But within the Check's horizon, what it changes first is the *inspection* work: Theo's team stops visiting healthy stations and goes to the risky ones. The faults it prevents would have happened next winter.

**The rule.** The Check: the predicted KPI must move by more than 2 %. Outage lead time within one maintenance lead time plus eight weeks moves within the noise; the maintenance stream's lead time and the inspectors' capacity move at once. **This one must be measured** (`draft_check.gd`): if outage lead time does move beyond 2 % within the horizon, the design changes to predicting the *demand* of outages, which certainly lags.

**The failed-Check debrief**:

> Je voorspelde dat er minder storingen zouden zijn. De Check zegt: nog niet. Wat wél bewoog: Theo's ploeg komt nu {visits_before} keer per jaar langs stations die gezond zijn, in plaats van {visits_after}, en de stations bovenaan de risicolijst zijn in {weeks} weken allemaal bekeken. Een mof die je vandaag vervangt, gaat volgende winter niet stuk. Dat zie je volgende winter. Welk getal laat je vandaag zien dat het werkt, en wanneer kijk je naar het getal dat je eigenlijk wilt?
>
> Theo: "De kalender was makkelijk te meten. Je ging, of je ging niet. Dit is moeilijker. Dit is ook beter."

**Ruud** (reflect): "Wat is je leidende indicator, en wanneer verwacht je je volgende?"

**The retry.** The same countermeasure, predicted on the maintenance stream's lead time (or the inspectors' capacity): passes. The outage gain is read at the NTA 8120 audit and in winter 3 (a beat: "De eerste winter met onderhoud op risico: {outage_delta} minder storingen in de straten bovenaan de lijst.").

**Content test.** With `risk_based_maintenance` at maturity 4, the prediction on `outages` lead time fails (`not_moved`) and the prediction on `maintenance` lead time passes. If the first does not fail, use the fallback above and re-test.

---

## 6. Act VI: `fix_field_app_bypassed` (De app die niemand gebruikt)

**The trap.** Ricardo's WhatsApp group; the monteurs design their own close-out screens with Noor. The A3 predicts close-out first-time-right (or fewer retyped close-outs). The redesign is `release_gated` (tier-3 draft §0.1): it reaches the street at the next release, months away (releases twice a year). The Check runs on the network as it is: nothing changed in the street.

**The rule.** `release_gated`: the countermeasure's effect starts at the stream's next release, not at the Act. The Check's horizon ends before it: `not_moved`.

**The failed-Check debrief** (it is also the chapter's mid-twist cliffhanger, engagement loop §3):

> Je voorspelde dat er minder afmeldingen opnieuw getypt zouden worden. De Check zegt: niets veranderd. De schermen die Ricardo en zijn collega's ontwierpen, zijn af. Ze zijn getest, ze zijn goed, en ze staan klaar voor de release van maart. Tot maart typen de monteurs 's avonds over wat ze overdag in de groep zetten. Een verbetering die klaarstaat, is nog geen verbetering. Waar wacht een wijziging bij ons, nadat iemand haar af heeft?
>
> Ricardo, in de groep: "Mooie schermen. Zie ik ze in maart? Dan heb ik tot maart de groep nog nodig, hè."

**Ruud** (reflect): "Hoe lang duurt het, van een idee van Ricardo tot zijn duim op het scherm? Waar zit de tijd?"

**The retry** is the chapter's next main, `fix_release_twice_a_year`. When it passes, `fix_field_app_bypassed`'s Check is re-read at the release and its debrief completes ("De schermen staan sinds de release van {release_month} op de telefoons. Afmeldingen opnieuw getypt: van {before} naar {after}."). This is the only designed failure whose retry is a different mission; the lesson is the flow of work in IT.

**Content test.** With releases twice a year, the field-app redesign fails its Check as `not_moved`; after `monthly_releases` or `ci_cd_pipeline`, the re-read passes.

---

## 7. What the builder needs

- `debrief_variants` keyed on the Check's verdict (`too_early`, `not_moved`, `not_constraint`) on solve missions. The kaizen week has `not_constraint` already; the others are new texts above.
- Placeholders read from the Check (`{days_before}`, `{visits_before}`, `{release_month}` …), as the templated debriefs (catalogue C16) already plan.
- The second A3 on the same problem shows the first attempt as "eerder geprobeerd" with the Check's line (the repair view, reused).
- Act VI: a Check re-read at the next release for a `release_gated` countermeasure (a small addition to the IT chapter's release logic).
- The six content tests above, run by the simulation checker before each tier enters content (PLAN §4.2.10: a mission that cannot pass its own Check does not ship; here also: a designed failure that does not fail does not ship).

## 8. Questions, decided by the standing rule

1. **Too early as the main mechanism (Acts I–III).** **(a) Yes: the expected first fix is the right idea at the wrong maturity.** (b) Use wrong causes instead. *(a) keeps every countermeasure a real improvement and teaches "build the foundation first", which the maturity rule already models.*
2. **Act V's measure.** **(a) Predicting outage minutes fails within the horizon; to be confirmed by `draft_check.gd`, with outage demand as the fallback.** (b) Choose another Act V mission. *(a) is the most realistic asset-management lesson; the test decides.*
3. **Act VI's retry is another mission.** **(a) Yes, with the Check re-read at the release.** (b) A retry within the same mission. *(a) is the IT chapter's own lesson: the release is the constraint.*
