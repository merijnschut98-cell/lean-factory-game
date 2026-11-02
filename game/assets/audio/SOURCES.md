# Audio sources

Every sound in this folder, where it comes from and its licence. All are **CC0** (public
domain dedication, no attribution required; credited here anyway), downloaded from
opengameart.org only (2026-10-21). Converted to mono Ogg Vorbis with ffmpeg; loops get a
seamless crossfade of their tail into their head; the filters per file are listed.
The build script lives outside the repo (the session's scratchpad); the filters below are
enough to redo it.

| File | Source page | Author | Licence | Original file, what was done |
|---|---|---|---|---|
| office_room_tone.ogg | https://opengameart.org/content/the-shop | LEGIT Audio | CC0 | `01 - ... convenience_store_drinks_fridge_drone.mp3`; low-pass 500 Hz, -6 dB, loop (an air-handling hum) |
| office_murmur.ogg | https://opengameart.org/content/crowd-shoutingspeaking-ambience | StarNinjas | CC0 | `crowd_shouting_0.ogg`; band-pass 120–650 Hz, compressed, short room echo, loop (voices across the floor, words not readable) |
| office_keys.ogg | https://opengameart.org/content/keyboard-soundpack-1-typing-and-single-keystrokes | unicaegames | CC0 | `Human Typing/human_vel-002, -003, -005.wav` joined; low-pass 6 kHz, short echo, loop |
| phone_far.ogg | https://opengameart.org/content/crank-movie-telephone-ringtone | cyberdyne | CC0 | `crank_ringtone.mp3`, first 3.6 s; low-pass 1.8 kHz, room echo, fade out (a phone across the floor) |
| door_open.ogg | https://opengameart.org/content/door-open-door-close | Iwan Gabovitch (qubodup) | CC0 | `door.7z: door-06.flac` |
| door_close.ogg | https://opengameart.org/content/door-open-door-close | Iwan Gabovitch (qubodup) | CC0 | `door.7z: door-01.flac` |
| lift_ding.ogg | https://opengameart.org/content/elevator-ding | fvcalderan | CC0 | `elevatording_0.ogg` |
| lift_door.ogg | https://opengameart.org/content/elevatordoor | PagDev | CC0 | `elevator_door.wav` |
| shutter.ogg | https://opengameart.org/content/camera | themightyglider | CC0 | `photo.ogg` (itself from a CC0 archive.org recording, per the page) |
| street_evening.ogg | https://opengameart.org/content/high-traffic-road-sounds | IgnasD | CC0 | `gatve Varniu_2.ogg`, 4–12 s; low-pass 2.5 kHz, fade in and a long fade out (the street outside the front door, going home) |
| van_start.ogg | https://opengameart.org/content/car-sound-effects-pack-low-quality | GGBotNet | CC0 | `Car_Engine_Start_Up.ogg`; low-pass 3 kHz |
| van_drive.ogg | https://opengameart.org/content/car-sound-effects-pack-low-quality | GGBotNet | CC0 | `Car_Acceleration.ogg`; low-pass 2.5 kHz, fade out |
| step_tile_1.ogg … step_tile_4.ogg | https://opengameart.org/content/footsteps-0 | GboxMikeFozzy | CC0 | `01-footstep_0.ogg`, `02-` … `04-footstep.ogg`; high-pass 80 Hz |
| step_carpet_1.ogg … step_carpet_4.ogg | https://opengameart.org/content/footsteps-0 | GboxMikeFozzy | CC0 | the same four steps, low-pass 700 Hz, -4 dB (muffled: carpet) |

Every file is peak-normalised to -3 dBFS; the game sets the levels.

Made for Spanning, no third-party source (no CC0 vibration was found on the approved sites):

| File | Source | Author | Licence | How |
|---|---|---|---|---|
| phone_buzz.ogg | synthesised with ffmpeg (`aevalsrc`) | Spanning | the project's own | two 0.32 s pulses of a 172 Hz tone with two harmonics and a 31 Hz flutter, low-pass 1.8 kHz: a phone vibrating on a desk |
| van_cab.ogg | synthesised with ffmpeg (`aevalsrc`, `anoisesrc`) | Spanning | the project's own | 8 s loop for the van ride's cab: a 62.5 Hz diesel drone with two harmonics and a slow swell, brown noise for the tyres and the road, low-pass 900 Hz (the cab, heard from inside) |
