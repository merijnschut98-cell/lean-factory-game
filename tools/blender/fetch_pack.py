"""Download the CC0 character pack the builder uses into .pack/ (not committed).

    python3 tools/blender/fetch_pack.py            # -> .pack/ubc, .pack/ual1, .pack/ual2

Three free (CC0 1.0) packs by Quaternius (game/assets/characters/LICENSES.md):
- Universal Base Characters [Standard]: two base bodies (man, vrouw) on one humanoid rig, six
  hairstyles, a beard, eyebrows. Only on itch.io: its free "No thanks, just take me to the
  downloads" button asks the page for a short-lived file link, which points at itch.io's file
  storage (itchio-mirror.<id>.r2.cloudflarestorage.com).
- Universal Animation Library 1 and 2 [Standard], on opengameart.org.

Each zip is checked against the SHA-256 recorded when the pack was adopted (2026-10-16) and its
licence file must say CC0 before anything is unpacked; a mismatch stops the script.
Only quaternius.itch.io, itch.io's file storage and opengameart.org are contacted.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
import urllib.parse
import urllib.request
import zipfile
from http.cookiejar import CookieJar
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / ".pack"
ITCH = "https://quaternius.itch.io/universal-base-characters"
UBC_UPLOAD = "15861669"   # "Universal Base Characters[Standard].zip"
PACKS = {
    # name: (url or None for the itch flow, sha256, folder inside the zip)
    "ubc": (None, "fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40",
            "Universal Base Characters[Standard]"),
    "ual1": ("https://opengameart.org/sites/default/files/universal_animation_librarystandard.zip",
             "18ff1a7215f4852b320203e8aaf02a1578b5c8eef9027fbaedfcedc7b85a3ac2", "Animation Library[Standard]"),
    "ual2": ("https://opengameart.org/sites/default/files/universal_animation_library_2standard.zip",
             "ec0e40d6d78fe9aaad59e322f40865a8675c22f0745e291622e54520391a9217",
             "Universal Animation Library 2 [Standard]"),
}
ALLOWED_HOSTS = re.compile(r"^(quaternius\.itch\.io|opengameart\.org|itchio-mirror\.[0-9a-f]+\.r2\.cloudflarestorage\.com)$")


def _opener() -> urllib.request.OpenerDirector:
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(CookieJar()))


def _get(opener, url: str, data: dict | None = None) -> bytes:
    host = urllib.parse.urlparse(url).hostname or ""
    if not ALLOWED_HOSTS.match(host):
        raise SystemExit(f"refusing to contact {host}: not an approved download host")
    body = urllib.parse.urlencode(data).encode() if data is not None else None
    with opener.open(urllib.request.Request(url, data=body, headers={"User-Agent": "spanning-fetch"}), timeout=600) as r:
        return r.read()


def _itch_file_url(opener) -> str:
    """The free download's file link: the page's csrf token, then the upload's file endpoint."""
    page = _get(opener, ITCH).decode("utf-8", "replace")
    token = re.search(r'name="csrf_token" value="([^"]+)"', page)
    if not token:
        raise SystemExit("itch.io page has no csrf token (the page changed?)")
    reply = json.loads(_get(opener, f"{ITCH}/file/{UBC_UPLOAD}?source=view_game&as_props=1&after_download_lightbox=true",
                            {"csrf_token": token.group(1)}))
    if "url" not in reply:
        raise SystemExit(f"itch.io gave no file link: {reply.get('errors')}")
    return reply["url"]


def fetch(name: str, opener) -> None:
    url, sha, folder = PACKS[name]
    target = PACK / name
    if target.exists():
        print(f"{name}: already in {target}")
        return
    data = _get(opener, url or _itch_file_url(opener))
    digest = hashlib.sha256(data).hexdigest()
    if digest != sha:
        raise SystemExit(f"{name}: sha256 {digest} is not the adopted {sha}; check the new version's licence first")
    zpath = PACK / f"{name}.zip"
    PACK.mkdir(exist_ok=True)
    zpath.write_bytes(data)
    with zipfile.ZipFile(zpath) as z:
        licence = next(n for n in z.namelist() if re.search(r"License[^/]*\.txt$", n))
        if "CC0" not in z.read(licence).decode("utf-8", "replace"):
            raise SystemExit(f"{name}: {licence} does not say CC0")
        for member in z.namelist():
            if not member.startswith(folder + "/") or ".." in Path(member).parts:
                raise SystemExit(f"{name}: unexpected path {member} in the zip")
        z.extractall(PACK / f"{name}.tmp")
    (PACK / f"{name}.tmp" / folder).rename(target)
    (PACK / f"{name}.tmp").rmdir()
    zpath.unlink()
    print(f"{name}: {len(data) / 1e6:.0f} MB, CC0, into {target}")


def main() -> None:
    opener = _opener()
    for name in sys.argv[1:] or PACKS:
        fetch(name, opener)


if __name__ == "__main__":
    main()
