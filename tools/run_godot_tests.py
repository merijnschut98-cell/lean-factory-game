"""Run the Godot logic tests one file per process, a few at a time.

One Godot process for the whole suite grew past 5 GB and was killed by the
OOM killer on a shared machine, printing no summary at all. Here every
game/tests/test_*.gd runs in its own process (bounded parallel), the summaries
are added up, and the run fails on any failed test *or* any file whose process
ended without a summary: a crash or a kill never reads as green.

    python tools/run_godot_tests.py              # whole suite, 2 at a time
    python tools/run_godot_tests.py -j 3 dialog  # files whose name has "dialog"

The job count also comes from SPANNING_TEST_JOBS. One file straight through
Godot still works: godot --headless --path game --script
res://tests/run_tests.gd -- /test_x.gd
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "game"
SUMMARY = re.compile(r"^(\d+) passed, (\d+) failed \(\d+ files\)$", re.MULTILINE)


@dataclass
class FileResult:
    name: str
    returncode: int
    output: str
    seconds: float
    peak_rss_mb: float
    passed: int = 0
    failed: int = 0
    has_summary: bool = False

    @property
    def ok(self) -> bool:
        return self.has_summary and self.failed == 0 and self.returncode == 0


def run_file(godot: str, game: Path, name: str, timeout: float) -> FileResult:
    """Runs one test file in its own Godot process and parses its summary."""
    cmd = [godot, "--headless", "--path", str(game), "--script", "res://tests/run_tests.gd", "--", "/" + name]
    start = time.monotonic()
    with tempfile.TemporaryFile("w+", encoding="utf-8", errors="replace") as log:
        try:
            proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
        except OSError as e:
            return FileResult(name, -1, f"could not start {godot}: {e}", 0.0, 0.0)
        timed_out = threading.Event()
        timer = threading.Timer(timeout, lambda: (timed_out.set(), proc.kill()))
        timer.start()
        try:
            returncode, peak_kb = _wait(proc)
        finally:
            timer.cancel()
        log.seek(0)
        output = log.read()
    if timed_out.is_set():
        output += f"\n[run_godot_tests] killed after the {timeout:.0f}s timeout"
    result = FileResult(name, returncode, output, time.monotonic() - start, peak_kb / 1024)
    summaries = SUMMARY.findall(output)
    if summaries:
        result.has_summary = True
        result.passed, result.failed = (int(n) for n in summaries[-1])
    return result


def _wait(proc: subprocess.Popen) -> tuple[int, int]:
    """The exit code and, where the OS reports it (Linux: wait4), the child's own peak RSS in KB."""
    if not hasattr(os, "wait4"):
        return proc.wait(), 0
    _, status, usage = os.wait4(proc.pid, 0)
    proc.returncode = os.waitstatus_to_exitcode(status)
    return proc.returncode, usage.ru_maxrss


def test_files(game: Path, name_filter: str) -> list[str]:
    return sorted(p.name for p in (game / "tests").glob("test_*.gd") if name_filter in p.name)


def _times_path(game: Path) -> Path:
    # game/.godot is git-ignored and per checkout: the last run's seconds per file.
    return game / ".godot" / "test_times.json"


def load_times(game: Path) -> dict[str, float]:
    try:
        data = json.loads(_times_path(game).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    if not isinstance(data, dict):
        return {}
    return {k: float(v) for k, v in data.items() if isinstance(k, str) and isinstance(v, (int, float))}


def save_times(game: Path, times: dict[str, float]) -> None:
    try:
        _times_path(game).write_text(json.dumps(times, indent=1, sort_keys=True), encoding="utf-8")
    except OSError as e:  # only an ordering hint: never fail a run over it
        print(f"[run_godot_tests] could not save file times: {e}", file=sys.stderr)


def longest_first(names: list[str], times: dict[str, float]) -> list[str]:
    """The slowest files start first, so a long one does not start last and
    run alone; a file with no time yet counts as slow (it may be new and big)."""
    return sorted(names, key=lambda n: -times.get(n, float("inf")))


def describe(r: FileResult) -> str:
    if not r.has_summary:
        return f"DIED {r.name}: no summary (exit code {r.returncode}; a crash, a kill or the OOM killer)"
    return f"FAIL {r.name}: {r.failed} failed (exit code {r.returncode})"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("filter", nargs="?", default="", help="run only files whose name contains this")
    parser.add_argument("-j", "--jobs", type=int, default=int(os.environ.get("SPANNING_TEST_JOBS", "2")))
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--game", type=Path, default=GAME, help=argparse.SUPPRESS)
    parser.add_argument("--timeout", type=float, default=1800.0, help="seconds per file (default 1800)")
    parser.add_argument("-v", "--verbose", action="store_true", help="print each file's time and peak memory")
    args = parser.parse_args(argv)

    names = test_files(args.game, args.filter)
    if not names:
        print(f"no test files match {args.filter!r}", file=sys.stderr)
        return 1
    times = load_times(args.game)
    start = time.monotonic()
    results: list[FileResult] = []
    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        jobs = [pool.submit(run_file, args.godot, args.game, n, args.timeout) for n in longest_first(names, times)]
        for job in as_completed(jobs):
            r = job.result()
            results.append(r)
            if args.verbose:
                print(f"  {r.name:<36} {r.passed:>4} passed {r.seconds:>7.1f}s {r.peak_rss_mb:>7.0f} MB", flush=True)
    results.sort(key=lambda r: r.name)
    save_times(args.game, times | {r.name: round(r.seconds, 1) for r in results if r.has_summary})

    bad = [r for r in results if not r.ok]
    for r in bad:
        print(f"\n===== {r.name} =====\n{r.output.rstrip()}", file=sys.stderr)
    for r in bad:
        print(describe(r), file=sys.stderr)
    passed = sum(r.passed for r in results)
    failed = sum(r.failed for r in results)
    peak = max(results, key=lambda r: r.peak_rss_mb)
    print(f"{passed} passed, {failed} failed, {len(bad)} files not green ({len(results)} files)"
          f" in {time.monotonic() - start:.0f}s; peak {peak.peak_rss_mb:.0f} MB ({peak.name})")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
