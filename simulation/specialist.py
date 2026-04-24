"""Specialist hiring — zone-level OEE bonus from hired expertise."""
from __future__ import annotations
from dataclasses import dataclass

SPECIALIST_COST = 500

# Zone → (role_id, display_name, description, avail_bonus, perf_bonus, qual_bonus)
ZONE_SPECIALIST: dict = {
    "z1": ("maintenance_engineer", "Maintenance Engineer",
           "+6% availability — reduces equipment downtime at Receiving & Dock.",
           0.06, 0.0,  0.0),
    "z2": ("lean_engineer",        "Lean Engineer",
           "+6% performance — improves flow efficiency at Component Prep.",
           0.0,  0.06, 0.0),
    "z3": ("lean_engineer",        "Lean Engineer",
           "+6% performance — improves flow efficiency at Parts Manufacturing.",
           0.0,  0.06, 0.0),
    "z4": ("quality_engineer",     "Quality Engineer",
           "+6% quality — reduces defect rate at Final Assembly.",
           0.0,  0.0,  0.06),
    "z5": ("quality_engineer",     "Quality Engineer",
           "+6% quality — reduces defect rate at Testing.",
           0.0,  0.0,  0.06),
    "z6": ("lean_engineer",        "Lean Engineer",
           "+6% performance — improves throughput at Packaging & Dispatch.",
           0.0,  0.06, 0.0),
}


@dataclass
class Specialist:
    zone_id:      str
    role_id:      str
    display_name: str
    description:  str
    hired_day:    int
    avail_bonus:  float
    perf_bonus:   float
    qual_bonus:   float

    @classmethod
    def for_zone(cls, zone_id: str, hired_day: int) -> "Specialist":
        role_id, name, desc, av, pf, ql = ZONE_SPECIALIST[zone_id]
        return cls(zone_id, role_id, name, desc, hired_day, av, pf, ql)

    def to_dict(self) -> dict:
        return {
            "zone_id":      self.zone_id,
            "role_id":      self.role_id,
            "display_name": self.display_name,
            "description":  self.description,
            "hired_day":    self.hired_day,
            "avail_bonus":  self.avail_bonus,
            "perf_bonus":   self.perf_bonus,
            "qual_bonus":   self.qual_bonus,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "Specialist":
        return cls(
            zone_id      = d["zone_id"],
            role_id      = d["role_id"],
            display_name = d["display_name"],
            description  = d["description"],
            hired_day    = d["hired_day"],
            avail_bonus  = d.get("avail_bonus", 0.0),
            perf_bonus   = d.get("perf_bonus",  0.0),
            qual_bonus   = d.get("qual_bonus",  0.0),
        )
