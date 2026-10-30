"""tools/run_godot_tests.py: one Godot process per test file, and a crash,
a kill or a failed test never adds up to a green run."""
from __future__ import annotations

import stat
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
import run_godot_tests  # noqa: E402

# Stands in for godot: behaves by the test file it is asked to run (the last arg).
FAKE_GODOT = """#!{python}
import os, signal, sys
name = sys.argv[-1]
if "pass" in name:
    print("4 passed, 0 failed (1 files)")
    sys.exit(0)
if "fail" in name:
    print("FAIL test_fail.gd::test_x - expected 1, got 2")
    print("3 passed, 1 failed (1 files)")
    sys.exit(1)
if "crash" in name:
    print("half way")
    sys.stdout.flush()
    os.kill(os.getpid(), signal.SIGKILL)
if "hang" in name:
    import time
    time.sleep(30)
print("0 passed, 0 failed (0 files)")
sys.exit(1)
"""


@pytest.fixture
def fake(tmp_path: Path):
    def make(*names: str) -> list[str]:
        tests = tmp_path / "game" / "tests"
        tests.mkdir(parents=True, exist_ok=True)
        for name in names:
            (tests / name).write_text("extends TestCase\n")
        godot = tmp_path / "fake_godot"
        godot.write_text(FAKE_GODOT.format(python=sys.executable))
        godot.chmod(godot.stat().st_mode | stat.S_IEXEC)
        return ["--godot", str(godot), "--game", str(tmp_path / "game")]
    return make


def test_all_green_files_pass(fake, capsys):
    args = fake("test_pass_a.gd", "test_pass_b.gd")
    assert run_godot_tests.main(args) == 0
    assert "8 passed, 0 failed, 0 files not green (2 files)" in capsys.readouterr().out


def test_a_failing_file_fails_the_run(fake, capsys):
    args = fake("test_pass_a.gd", "test_fail.gd")
    assert run_godot_tests.main(args) == 1
    out = capsys.readouterr()
    assert "7 passed, 1 failed, 1 files not green" in out.out
    assert "FAIL test_fail.gd: 1 failed" in out.err


def test_a_crashed_file_fails_the_run_and_is_named(fake, capsys):
    args = fake("test_pass_a.gd", "test_crash.gd")
    assert run_godot_tests.main(args) == 1
    out = capsys.readouterr()
    assert "DIED test_crash.gd: no summary" in out.err
    assert "half way" in out.err, "the dead file's output is shown"


def test_a_hung_file_is_killed_at_the_timeout(fake, capsys):
    args = fake("test_hang.gd")
    assert run_godot_tests.main([*args, "--timeout", "1"]) == 1
    assert "killed after the 1s timeout" in capsys.readouterr().err


def test_the_filter_picks_files_and_an_empty_match_fails(fake, capsys):
    args = fake("test_pass_a.gd", "test_fail.gd")
    assert run_godot_tests.main([*args, "pass"]) == 0
    assert "(1 files)" in capsys.readouterr().out
    assert run_godot_tests.main([*args, "nothing"]) == 1


def test_the_slowest_files_of_the_last_run_start_first(fake, tmp_path):
    args = fake("test_pass_a.gd", "test_pass_b.gd")
    (tmp_path / "game" / ".godot").mkdir()
    assert run_godot_tests.main(args) == 0
    times = run_godot_tests.load_times(tmp_path / "game")
    assert set(times) == {"test_pass_a.gd", "test_pass_b.gd"}
    order = run_godot_tests.longest_first(["a", "b", "new"], {"a": 1.0, "b": 9.0})
    assert order == ["new", "b", "a"], "an unmeasured file counts as slow"
