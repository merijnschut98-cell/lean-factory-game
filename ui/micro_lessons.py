"""
Micro-lesson texts — short in-fiction NPC explanations shown when a concept
is discovered for the first time via a dialogue fork choice.

Each entry is 2-4 sentences in a collegial, floor-level voice.
"""
from __future__ import annotations

MICRO_LESSONS: dict[str, str] = {
    "5S": (
        "5S stands for Sort, Set in order, Shine, Standardize, Sustain. "
        "It sounds basic, but an organized workplace is the foundation everything else rests on. "
        "You can't flow smoothly through chaos, and you can't see abnormalities if normal is already a mess."
    ),
    "5S_sort": (
        "The first S is Sort — separate what you actually use from what you're keeping 'just in case.' "
        "Red-tag anything you haven't touched in 30 days. If nobody comes to reclaim it, it goes. "
        "Clutter is a slow tax on every operator who has to work around it."
    ),
    "FIFO": (
        "First In, First Out means the oldest unit gets processed first — always. "
        "When inventory sits out of order, older batches age unnoticed, and defects show up downstream long after the cause is gone. "
        "FIFO lanes keep material moving in sequence and make problems visible while they're still correctable."
    ),
    "FTR": (
        "First Time Right is the proportion of units that pass quality checks on the first attempt. "
        "Rework and reinspection feel productive, but they're paying twice for the same unit. "
        "A falling FTR is an early warning — something upstream is out of control before the defect becomes obvious."
    ),
    "MSA": (
        "Before you trust your data, verify your measurement system. "
        "MSA — Measurement System Analysis — checks whether your gauge, method, and operator all agree reliably. "
        "Decisions made on bad measurements are worse than decisions made on gut feel, because they look authoritative."
    ),
    "OEE": (
        "OEE — Overall Equipment Effectiveness — multiplies Availability, Performance, and Quality. "
        "All three have to be high for the number to be good; one weak factor drags the whole score. "
        "It's the most honest single number for how well a station is actually running versus how it could run."
    ),
    "TPM": (
        "Total Productive Maintenance gives operators ownership over basic machine care: clean it, inspect it, lubricate it. "
        "The person running the machine every day is the first to notice a sound that's changed or a vibration that's new. "
        "Reactive maintenance is expensive; operator-led care catches problems while they're still cheap to fix."
    ),
    "WIP": (
        "Work In Progress is everything in the system that isn't finished product yet. "
        "High WIP doesn't mean the factory is busy — it means lead time is long and problems are hidden behind queues. "
        "Every unit sitting between steps is a defect that hasn't been found yet and a question nobody has answered."
    ),
    "autonomous_maintenance": (
        "Autonomous maintenance shifts daily machine care from a specialist team to the operators themselves. "
        "They clean, inspect, and lubricate — and in doing so, they learn what normal looks and sounds like. "
        "When something changes, they notice it before it becomes a breakdown."
    ),
    "cross_training": (
        "Cross-training means operators can cover more than one station. "
        "Without it, one absence creates a bottleneck — the whole line waits on a single person. "
        "Resilience isn't about having more people; it's about having people who can shift where they're needed."
    ),
    "data_accuracy": (
        "Data is only as good as the process that captures it. "
        "If operators are recording what they think the system expects rather than what actually happened, you're managing a fiction. "
        "Accurate data starts with removing the pressure to report good numbers."
    ),
    "data_capture": (
        "Before you can analyze anything, you have to decide what to record and when. "
        "Capturing everything sounds safe but creates noise; capturing too little leaves gaps you can't fill later. "
        "Good data capture design is a process decision, not an IT decision."
    ),
    "data_integrity": (
        "Data integrity means the numbers mean what you think they mean — consistently, across shifts and systems. "
        "When two sources disagree, someone has been making decisions on the wrong one. "
        "Reconciling the gap is less important than finding where it starts."
    ),
    "decision_authority": (
        "The person closest to the problem should have the authority to stop and fix it. "
        "Escalation chains create delays — and by the time approval comes back, the evidence is gone. "
        "Delegating authority to the floor isn't losing control; it's moving control to where the information is."
    ),
    "digitalization": (
        "Digital tools don't fix unstable processes — they speed up the instability. "
        "The right time to digitalize a step is after you've stabilized it on paper: standard work, clean data, defined inputs and outputs. "
        "Then the tool captures reality instead of creating a parallel version of it."
    ),
    "documentation": (
        "Documentation exists so that the right way to do something doesn't depend on who's on shift. "
        "A process that lives only in one person's head is one sick day away from variation. "
        "Good documentation is short, visual, and updated by the people who use it."
    ),
    "flow": (
        "Flow means units move through the process one at a time, without waiting, in sequence. "
        "Every queue between steps is evidence of imbalance — somewhere upstream is faster than downstream, or vice versa. "
        "One-piece flow shortens lead time and surfaces quality problems immediately, while they can still be contained."
    ),
    "heijunka": (
        "Heijunka is production leveling — spreading demand evenly across time instead of running big batches. "
        "Batching feels efficient but it creates feast-and-famine cycles: flood the floor, then starve it. "
        "Leveling lets every upstream process respond to a steady rhythm instead of chasing peaks."
    ),
    "information_flow": (
        "Material flow gets all the attention, but information flow is usually the real bottleneck. "
        "If operators don't know what to build next, or when, they improvise — and improvisation creates variation. "
        "Mapping how information travels reveals disconnects that no amount of machine optimization will fix."
    ),
    "inspection": (
        "Inspection finds defects; it doesn't prevent them. "
        "Relying on inspection as your quality system means accepting that defects will be made and hoping they're caught. "
        "The goal is to move the control upstream — to the step where the defect is created, not the step where it's found."
    ),
    "inventory_management": (
        "Inventory hides problems. A large buffer between two stations masks the fact that one of them is unreliable. "
        "Reducing inventory gradually forces problems to surface — but you have to be ready to act on what you find. "
        "The right inventory level is the minimum needed to keep flow stable while you close the reliability gaps."
    ),
    "kaizen": (
        "Kaizen means continuous incremental improvement — small changes, often, by the people doing the work. "
        "It's not a project or a workshop; it's a daily habit of asking whether there's a slightly better way. "
        "The aggregate of small improvements compounds over time in ways that large redesigns rarely match."
    ),
    "kanban": (
        "A kanban is a signal that says: I've consumed something, please replenish it. "
        "It's a pull mechanism — nothing gets made or moved until downstream consumption triggers it. "
        "Without pull, upstream processes guess at demand and overproduce to feel safe; kanban replaces the guess with a fact."
    ),
    "knowledge_management": (
        "Knowledge management is the discipline of making what people know into something the organization knows. "
        "When expertise lives only in individuals, it leaves when they do. "
        "Standard work, training materials, and documented procedures are the tools — but only if they're maintained by the people who use them."
    ),
    "leader_standard_work": (
        "Leader standard work defines what leaders do every day to sustain the system: which checks to run, which processes to audit, which conversations to have. "
        "Without it, leaders respond to crises and the routine discipline that prevents crises gets skipped. "
        "The floor follows the rhythm you set."
    ),
    "leveled_production": (
        "Leveled production spreads output evenly across time to match a stable rate of demand. "
        "Spikes in production create spikes in material consumption, overtime, and stress — and the troughs that follow create idle time and confusion. "
        "A level schedule is harder to build but easier to sustain."
    ),
    "line_balancing": (
        "Line balancing distributes work across stations so each one takes roughly the same time per unit. "
        "An unbalanced line means some stations are always waiting while others are always behind — and the throughput is capped by the slowest one. "
        "Balancing starts with accurate time data, not guesses."
    ),
    "management_system": (
        "A management system is the set of routines — daily, weekly, monthly — that keep improvement from slipping back. "
        "Improvement without a management system is a project; improvement with one is a habit. "
        "The routines don't have to be complex, but they do have to happen reliably."
    ),
    "measurement_system": (
        "Your measurement system is the full chain: the instrument, the method, the operator, and the environment. "
        "Any one of those can introduce error that looks like process variation. "
        "You can't improve what you can't measure reliably — and a flawed measurement system will hide real problems behind noise."
    ),
    "near_miss_reporting": (
        "A near miss is a defect that didn't quite happen — an incident that almost caused harm but didn't. "
        "Near misses are free lessons. They tell you where the system is fragile before someone gets hurt. "
        "Organizations that report and act on near misses have fewer serious incidents; the ones that suppress them are building up debt."
    ),
    "operator_variation": (
        "When different operators produce different results on the same station, the process is not in control — it's operator-dependent. "
        "That's not a performance problem; it's a documentation and training problem. "
        "Standard work makes the best-known method visible and teachable, so consistency doesn't depend on who shows up."
    ),
    "overproduction": (
        "Overproduction — making more than is needed right now — is considered the worst of the seven wastes. "
        "It consumes material and capacity ahead of demand, creates inventory that hides defects, and complicates scheduling downstream. "
        "Pull systems and leveled schedules are the primary countermeasures."
    ),
    "performance_reporting": (
        "Performance reporting should reflect reality, not a sanitized version of it. "
        "Reports that consistently show green create two problems: the people who know the truth stop believing the system, and the people who don't know get surprised later. "
        "Accurate reporting starts with making it safe to report problems."
    ),
    "poka_yoke": (
        "A poka-yoke is an error-proofing device or method that makes the wrong action impossible — or at least immediately visible. "
        "A fixture that only accepts a part in the correct orientation is a poka-yoke. So is a checklist that won't advance until each step is confirmed. "
        "The goal is to make quality automatic rather than dependent on attention."
    ),
    "push_vs_pull": (
        "A push system produces based on a forecast and moves material whether downstream is ready or not. "
        "A pull system produces only in response to actual consumption — nothing moves until something is needed. "
        "Push creates buffers and hides demand signals; pull makes the real rate of consumption visible and keeps inventory minimal."
    ),
    "quality_gate": (
        "A quality gate is a defined checkpoint where work is verified before it passes to the next step. "
        "Without it, defects travel downstream and cost more to fix with each step they pass through. "
        "Effective quality gates stop defects at the source — the closer to the point of creation, the cheaper the catch."
    ),
    "replenishment": (
        "Replenishment is restocking triggered by consumption, not by schedule or forecast. "
        "When you replenish by schedule, you're guessing — sometimes overstocking, sometimes running out. "
        "Consumption-triggered replenishment keeps inventory proportional to actual use and makes shortages visible before they become stops."
    ),
    "rework_waste": (
        "Rework is one of the seven wastes — time and effort spent correcting something that should have been done right the first time. "
        "It occupies capacity without adding value, and because it's often invisible in reports, it can grow unnoticed for months. "
        "Rework reduction starts with identifying where in the process the defect is created, not where it's found."
    ),
    "safety": (
        "Safety is not a separate program — it's a condition for everything else. "
        "A team that's worried about injury can't focus on flow, quality, or improvement. "
        "Every near miss and every awkward posture is information the system is giving you; the question is whether you're listening."
    ),
    "shift_handover": (
        "A structured shift handover ensures the incoming team knows what the outgoing team knew. "
        "Without it, every shift starts cold — rediscovering problems that were already understood, losing time before the first unit moves. "
        "The handover doesn't need to be long; it needs to cover status, in-progress work, and any open issues."
    ),
    "shift_readiness": (
        "Shift readiness means a shift starts moving from the first minute, not after a half-hour of setup and discovery. "
        "Material staged, tools in place, status understood — preparation before the shift starts buys you time during it. "
        "Lost time at the start of a shift is some of the most expensive time in the day."
    ),
    "skill_matrix": (
        "A skill matrix maps each operator against each task and records their current level: trained, competent, or able to train others. "
        "It makes gaps visible — where is coverage thin? Where does the line depend on a single person? "
        "You can't manage flexibility you can't see."
    ),
    "standard_work": (
        "Standard work is the documented current best method: the sequence, the timing, and the WIP needed to do the job safely and right. "
        "It's not a rulebook — it's a baseline that makes improvement possible. You can't improve a process you haven't stabilized. "
        "Standard work belongs to the operators who do the job; they're the ones who know when it's out of date."
    ),
    "supplier_quality": (
        "Quality problems that start before your dock are the hardest to control and the easiest to ignore. "
        "Incoming inspection is a detection mechanism, not a prevention mechanism — you're sorting defects after the fact. "
        "Working upstream with suppliers to understand and control variation is the only way to stop the problem at the source."
    ),
    "tacit_knowledge": (
        "Tacit knowledge is the expertise that lives in someone's hands and head — built over years but never written down. "
        "When that person is absent, the process degrades. When they leave, the knowledge leaves with them. "
        "Converting tacit knowledge into documented standard work is one of the highest-leverage things a team can do."
    ),
    "variation": (
        "Variation is the gap between what you intended and what you got — in cycle time, quality, output, or any process parameter. "
        "Some variation is common cause: noise built into the system. Some is special cause: an assignable event. "
        "Treating one as the other makes things worse; SPC charts help you tell the difference."
    ),
    "version_control": (
        "Version control is knowing which document is current and making sure everyone is using that version. "
        "Outdated work instructions in use on the floor are a hidden source of variation — operators doing different things while believing they're following the same standard. "
        "Document control is boring until the day it isn't."
    ),
    "visual_management": (
        "Visual management makes the status of the system visible at a glance — without asking anyone. "
        "An andon light, a kanban board, a production tracking chart: the goal is that an abnormal condition is obvious before it becomes a crisis. "
        "If you need to check a system or ask someone whether things are normal, visual management is missing."
    ),
    "waste_muda": (
        "Muda is non-value-adding activity — anything a customer wouldn't pay for if they knew it was happening. "
        "There are seven types: transport, inventory, motion, waiting, overproduction, over-processing, and defects. "
        "Elimination starts with being honest about how much of each you have; most operations are surprised by the count."
    ),
    "waste_mura": (
        "Mura is unevenness — variation in workload, pace, or demand that stresses the system unevenly. "
        "A schedule that floods the line one day and starves it the next creates waste at both ends: overtime and idle time, rework and underuse. "
        "Leveling production and balancing lines are the primary countermeasures."
    ),
    "waste_muri": (
        "Muri is overburden — pushing people or machines beyond what they can sustainably deliver. "
        "It feels like productivity but it's borrowing from tomorrow: equipment wears faster, people make more mistakes, quality drifts. "
        "The fix is not to push less but to design work so that sustainable pace and required output are the same number."
    ),
    "workplace_organization": (
        "A well-organized workplace has everything in its place and a place for everything. "
        "When tools are hard to find or materials are in the wrong location, operators spend time searching instead of building. "
        "That search time is invisible in the numbers but visible the moment you walk the floor."
    ),
}
