# Character assets: sources and licences

The people of Spanning (`<id>.glb`), the character creator's parts (`parts/*.glb`) and the
shared skin, hair and eye textures (`textures/skin_*`, `textures/hairpack_*`, `textures/eye_*`)
are built by `tools/blender/build_character.py` (method `pack`, PLAN 1.3a) from the three free
packs below, re-dressed for Voltana. All three are **CC0 1.0 Universal (public domain
dedication)**: no attribution is required; we credit Quaternius anyway. The licence text in
each download was read before use (2026-10-16), and `tools/blender/fetch_pack.py` checks it
again, with each zip's SHA-256, on every fetch. The packs themselves are not in the repository
(`.pack/`, git-ignored); only what the game uses is.

| Pack | Version | Source | Licence | SHA-256 of the zip |
|---|---|---|---|---|
| Universal Base Characters [Standard] (Quaternius) | free Standard edition, files dated 2025 | https://quaternius.com/packs/universalbasecharacters.html, downloaded from https://quaternius.itch.io/universal-base-characters | CC0 1.0 (`License_Standard.txt`) | `fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40` |
| Universal Animation Library [Standard] (Quaternius) | Standard, files dated 2025-03-25 | https://opengameart.org/content/universal-animation-library | CC0 1.0 (`License.txt`) | `18ff1a7215f4852b320203e8aaf02a1578b5c8eef9027fbaedfcedc7b85a3ac2` |
| Universal Animation Library 2 [Standard] (Quaternius) | Standard, files dated 2026-01-23 | https://opengameart.org/content/universal-animation-library-2 | CC0 1.0 (`License.txt`) | `ec0e40d6d78fe9aaad59e322f40865a8675c22f0745e291622e54520391a9217` |

What is used from them:
- Universal Base Characters: the two bodies (`Superhero_Male_FullBody`, `Superhero_Female_FullBody`
  with their eyes and eyebrows), the hairstyles `Hair_Long`, `Hair_SimpleParted`, `Hair_Buzzed`,
  `Hair_BuzzedFemale`, `Hair_Buns`, `Hair_Beard`, and the skin, hair and eye textures (reworked into
  tintable maps at 1024/512/256 px).
- Universal Animation Library: `Idle_Loop`, `Idle_Talking_Loop`, `Sitting_Idle_Loop` (the seated
  torso; legs and typing arms are set by the builder), `Walk_Formal_Loop`, `Walk_Loop`,
  `Jog_Fwd_Loop`, retargeted onto the base characters' rig.
- Universal Animation Library 2: fetched and licence-checked with the others; it shares the base
  characters' rig, so its clips (folded arms, a phone call, nodding yes and no, carrying) retarget
  with no bone map (`Source(path, None)` in `pack_character.py`). Used since S1-C (people react):
  `Idle_FoldArms_Loop`, `Idle_TalkingPhone_Loop`, `Yes` (the nod), `Walk_Carry_Loop`; and from Library 1
  `Sitting_Talking_Loop`. Lean in, look away and the tired idle are Library 1 clips edited here.

Made here, not from the packs (also free to use under the project's licence): the clothes (cut
from the body's surface), the ponytail, the glasses, the Voltana logo and the fabric textures
(`textures/pique_*`, `twill_*`, `oxford_*`, `wool_*`, `knit_*`, `denim_*`, `leather_*`, `hivis_*`,
`logo_*`).

The character creator (PLAN 2.7b; `tools/blender/creator_build.py`, from `creator_options.json`):
the bodies `player_m.glb`, `player_f.glb` are the pack's two base bodies, shaped and animated as
the cast; `parts/outfit_*` are clothes made here; the hairstyles in `parts/hair_*` are the pack's
`Hair_SimpleParted`, `Hair_Buzzed`, `Hair_BuzzedFemale` and `Hair_Long` reshaped here (faded,
cropped, cut, lengthened, waved, curled with noise); `parts/beard_*` and `moustache_*` are the
pack's `Hair_Beard` trimmed; `parts/glasses_*` and the face-layer masks `textures/face_*` (stubble,
make-up, painted from the head's landmarks) are made here. No new download.
