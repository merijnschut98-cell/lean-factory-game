"""Problem state machine transitions — Phase 3 stub."""
from problems.problem import Problem, ProblemState


def investigate(prob: Problem, entity_id: str, metric: str) -> None:
    if prob.state == ProblemState.ACTIVE:
        prob.state = ProblemState.UNDER_INVESTIGATION
    prob.investigation_log.append({"entity": entity_id, "metric": metric})


def apply_countermeasure(prob: Problem, countermeasure_id: str, day: int) -> None:
    prob.applied_countermeasure = countermeasure_id
    prob.state = ProblemState.COUNTERMEASURE_APPLIED


def resolve(prob: Problem, score: dict, day: int) -> None:
    prob.score     = score
    prob.solved_day = day
    prob.state     = ProblemState.RESOLVED


def regress(prob: Problem) -> None:
    prob.state = ProblemState.REGRESSED
