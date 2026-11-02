class_name Strain
extends RefCounted
## What the work puts on a person (PLAN 3.1-A, spec 2026-10-26 §3.1): one reading from the
## team's smoothed load, the person's morale and recent pressure. The office reads it (who
## stays late, posture, chatter) and so does People (a sick day). Every threshold of it lives
## here and nowhere else; People keeps the state, this file only computes.
##
## All numbers are ESTIMATES, tuned so that a heavy team shows it within a fortnight and
## recovers within a fortnight of a fix that holds (probe 2026-10-27: work_prep's load is
## 1.08 with the custom-design problem, 0.83 at the base, 0.71 with the fix):
## - weights: load counts most (the work itself), then wear (morale), then pressure (a
##   yes under pressure or a confrontation, not respect for people);
## - morale only adds strain under STRAIN_MORALE and reaches its full part at the morale
##   where people leave (People.LEAVE_MORALE). Load alone wears nobody below
##   People.NEGLECT_FLOOR, so neglect without load stays under LATE_AT;
## - the load is smoothed over about a week (SMOOTH_DAYS): the office shows a team's
##   week, not one busy Tuesday;
## - pressure counts for a month (PRESSED_DAYS);
## - bands: easy under EASY_BELOW (a joke), a late evening from LATE_AT, a slump from
##   SLUMP_AT, a hand to the neck from NECK_AT; from ABSENT_AT for ABSENT_AFTER_DAYS (three
##   weeks) a person goes off sick on one working day a week.

## The tones of what people say in passing (band); mirrored in tools/build_content.py CHATTER_STRAINS.
const BANDS: Array[String] = ["low", "mid", "high"]
const LOAD_W := 0.6
const MORALE_W := 0.25
const PRESSURE_W := 0.15
const STRAIN_MORALE := 50
const SMOOTH_DAYS := 7
const PRESSED_DAYS := 30
const EASY_BELOW := 0.15
const LATE_AT := 0.35
const SLUMP_AT := 0.5
const NECK_AT := 0.7
const ABSENT_AT := 0.8
const ABSENT_AFTER_DAYS := 21


## Strain from a team's (smoothed) load, a person's morale and whether they were pressed
## lately, 0 (an ordinary day) to 1.
static func reading(load: float, morale: int, pressed: bool) -> float:
	var from_load := clampf((load - People.LOAD_NORM) / People.LOAD_SPAN, 0.0, 1.0)
	var from_morale := clampf((STRAIN_MORALE - morale) / float(STRAIN_MORALE - People.LEAVE_MORALE), 0.0, 1.0)
	return clampf(LOAD_W * from_load + MORALE_W * from_morale + PRESSURE_W * (1.0 if pressed else 0.0), 0.0, 1.0)


## The smoothed load after `days` days at `load`, from the `seen` one: it closes
## 1/SMOOTH_DAYS of the gap each day, so a span compounds as that many single days.
static func smoothed(seen: float, load: float, days: int) -> float:
	return load + (seen - load) * pow(1.0 - 1.0 / SMOOTH_DAYS, days)


## One of BANDS: "low" (easy), "mid" or "high" (staying late or worse): the tone of what they say in passing.
static func band(strain: float) -> String:
	if strain < EASY_BELOW:
		return BANDS[0]
	return BANDS[2] if strain >= LATE_AT else BANDS[1]


## The working day of `week` (0 Monday to 4 Friday) a person is off sick, the same every time.
static func sick_weekday(person_id: String, week: int) -> int:
	return posmod(hash([person_id, week]), 5)
