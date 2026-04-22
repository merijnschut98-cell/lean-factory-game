"""Credit balance and spend tracking."""
from __future__ import annotations


class CreditLedger:
    def __init__(self, balance: int = 0) -> None:
        self.balance = balance
        self.history: list = []

    def earn(self, amount: int, reason: str) -> None:
        self.balance += amount
        self.history.append({"type": "earn", "amount": amount, "reason": reason})

    def spend(self, amount: int, reason: str) -> bool:
        if self.balance < amount:
            return False
        self.balance -= amount
        self.history.append({"type": "spend", "amount": amount, "reason": reason})
        return True

    def can_afford(self, amount: int) -> bool:
        return self.balance >= amount
