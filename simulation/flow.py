"""
Material flow between stations.

In the base (push) model, wip_out from station N becomes wip_in for station N+1
each time the factory calls propagate().

When Kanban is active on a link, flow is gated by a pull signal (max WIP limit
between stations). This logic is wired by the maturity/countermeasure system.
"""
from __future__ import annotations
from typing import Dict, List, Optional

from simulation.station import Station


class FlowLink:
    """Directed connection from one station to the next."""

    def __init__(
        self,
        upstream_id:   str,
        downstream_id: str,
        kanban_limit:  Optional[int] = None,   # None = push; int = pull with WIP cap
    ) -> None:
        self.upstream_id   = upstream_id
        self.downstream_id = downstream_id
        self.kanban_limit  = kanban_limit
        self._transit_units: int = 0   # units currently "in transit" between stations

    @property
    def is_pull(self) -> bool:
        return self.kanban_limit is not None

    def propagate(self, upstream: Station, downstream: Station) -> int:
        """
        Move units from upstream.wip_out to downstream.wip_in.
        Returns the number of units transferred.
        """
        available = upstream.wip_out
        if available <= 0:
            return 0

        if self.is_pull:
            # Pull: only move if downstream WIP-in is below limit
            space = self.kanban_limit - downstream.wip_in
            transfer = max(0, min(available, space))
        else:
            transfer = available

        upstream.wip_out   -= transfer
        downstream.wip_in  += transfer
        return transfer

    def to_dict(self) -> dict:
        return {
            "upstream_id":   self.upstream_id,
            "downstream_id": self.downstream_id,
            "kanban_limit":  self.kanban_limit,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "FlowLink":
        return cls(
            upstream_id=d["upstream_id"],
            downstream_id=d["downstream_id"],
            kanban_limit=d.get("kanban_limit"),
        )


class MaterialFlow:
    """Manages all links between stations in station flow order."""

    def __init__(self, station_order: List[str]) -> None:
        self._order = station_order
        self._links: Dict[str, FlowLink] = {}
        for i in range(len(station_order) - 1):
            up   = station_order[i]
            down = station_order[i + 1]
            self._links[f"{up}->{down}"] = FlowLink(up, down)

    def propagate_all(self, stations: Dict[str, Station]) -> None:
        """Push / pull all units forward by one step."""
        # Propagate in reverse order to avoid double-moving in one tick
        for i in range(len(self._order) - 2, -1, -1):
            up_id   = self._order[i]
            down_id = self._order[i + 1]
            key     = f"{up_id}->{down_id}"
            link    = self._links[key]
            link.propagate(stations[up_id], stations[down_id])

    def set_kanban(self, upstream_id: str, downstream_id: str, limit: Optional[int]) -> None:
        key = f"{upstream_id}->{downstream_id}"
        if key in self._links:
            self._links[key].kanban_limit = limit

    def inject_units(self, station_id: str, stations: Dict[str, Station], count: int = 1) -> None:
        """Add new raw-material units directly to a station's wip_in (used by Receiving)."""
        if station_id in stations:
            stations[station_id].wip_in += count

    def to_dict(self) -> dict:
        return {k: v.to_dict() for k, v in self._links.items()}

    def from_dict(self, d: dict) -> None:
        for key, link_d in d.items():
            if key in self._links:
                self._links[key].kanban_limit = link_d.get("kanban_limit")
