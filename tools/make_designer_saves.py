"""Make the designer's jump-to-day saves (Phase 3 slice 3.0), one Godot process per save.

    python tools/make_designer_saves.py [persona] [seed]      # default: expert 11

The autoplay bot plays the campaign to each stop (a play day or the opening of an Act) and
the game is written to Godot's user://saves/designer/<slot>.save. Start the game with
`--designer` (or from the editor) and the main menu offers them. The slots and their stops
are DesignerSaves.SAVES (game/src/save/designer_saves.gd); a save made before the missions
changed shows a stale content hash, so make them again after a content change.

One process at a time (each run is several minutes). Never run by CI; needs `godot` on the PATH.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "game"
SAVES_FILE = GAME / "src" / "save" / "designer_saves.gd"


def slots() -> list[str]:
    """The slot names in DesignerSaves.SAVES, read from the source so there is one list."""
    return re.findall(r'\{"slot": "(\w+)"', SAVES_FILE.read_text(encoding="utf-8"))


def main(argv: list[str]) -> int:
    godot = shutil.which("godot")
    if godot is None:
        print("godot is not on the PATH; install Godot 4.7 or add it", file=sys.stderr)
        return 1
    persona = argv[0] if argv else "expert"
    seed = argv[1] if len(argv) > 1 else "11"
    names = slots()
    if not names:
        print(f"no slots found in {SAVES_FILE}", file=sys.stderr)
        return 1
    for slot in names:
        print(f"making {slot} ...", flush=True)
        done = subprocess.run(
            [godot, "--headless", "--path", str(GAME), "--script", "res://tools/make_saves.gd",
             "--", slot, persona, seed], check=False)
        if done.returncode != 0:
            print(f"{slot} failed (exit {done.returncode})", file=sys.stderr)
            return done.returncode
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
