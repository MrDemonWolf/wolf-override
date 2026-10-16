# add7 / beacons: item (d), real red lockdown beacons

## What main draws today (game-slice = round 6, identical to main for this code)
- `scripts/room_depth.gd`: `warning_lamps` (fractions of the far plate) place one `Beacon` node (z 1) and one `WarningGlow`
  Sprite2D (z 2, additive) per lamp on the Backdrop (far parallax layer). `Beacon._draw()` is code: a 2 px line, a
  14x9 dark rect with a 1 px grey-pink rim and a 10x5 red lens (`lens`, `#ff4a46`); the glow is a 90x90 radial sprite.
- Corridor (`scenes/main.tscn`, CorridorDepth): `warning_lamps = (0.341, 0.27), (0.659, 0.27)` -> far-plate px
  (654.72, 291.6) and (1265.28, 291.6); world (backdrop) (327.36, 224.3) and (632.64, 224.3).
- Live behaviour: glow alpha pulses 0.40 -> 0.22 -> 0.40 (1.3 s each way, sine, lamp 1 phased 0.5 s), and once the
  room's route is cleared the glow settles to 0.10 and the lens darkens 60% (`_settle_beacons`). Reduced Motion / room
  off-screen stops the tween. `tests/room_lights_test.gd` checks pulse, settle and lens colour.
- Both lamps are in the opening (o0-o8: the left lamp in every frame, both in o7/o8). Records and the junction use the
  same code with their own `warning_lamps` and are NOT changed here (no atlas -> they keep the drawn housing).

## What it becomes
Each lamp is a hazardous-location LED luminaire with a red glass globe and cast guard on a cast wall bracket
(proportions of the Crouse-Hinds EV LED, 0.44 m tall, 80 far-plate px per metre; see research/SOURCES.md):
- b0 (left, on the dark wall column): fed by 3/4 in rigid conduit from the ceiling cable tray straight down the column,
  connector at the tray, one-hole straps 0.29 m and 0.89 m above the bracket (NEC 344.30: within 0.9 m of a box),
  threaded hub into the bracket top. Dim ambient, soft contact shadow straight down the wall.
- b1 (right, under the existing pendant fitting and its back box): a short conduit nipple from that back box into the
  bracket hub; its top faces catch the cool lamp above; short shadow straight down.
- Nothing floats: bracket plate with two anchor bolts flush on the wall, arm, finned driver housing, guard collar, globe,
  guard (mid ring, foot ring, drain boss), feed visible to a real source.

Split into a static part and a small live part (one 256x156 RGBA atlas, lossless, no mipmaps, +0.036 MB):
| part | drawn by | live? |
|---|---|---|
| fixture (bracket, housing, conduit, straps, wall contact shadow) | `Beacon._draw`, plain | static |
| globe (greyscale glass) | `Beacon._draw`, tinted by `lens` | lens colour only (settle darkening) |
| guard (in front of the globe) | `Beacon._draw`, plain | static |
| light (glass emission, faint bloom, red wall spill, d/r^3 from a globe 0.32 m off the wall, blocked above by the housing, modulated by the wall texture) | `WarningGlow%d` Sprite2D, additive, `modulate = (warning_color, alpha)` | pulse / settle alpha, unchanged timing |

Fixture, globe and guard are one texture in one node, so both beacons batch. The red pool is real light from the globe,
so at the pulse peak it shows on the wall around the lamp only (about 0.3-0.4 m), not as a 2.25 m disc.

## Integration (exact)
Files to add to `apps/game/assets/props/`: `layers/corridor-beacons.png` and `layers/corridor-beacons.png.import`
(compress/mode=0 lossless, mipmaps off, fix_alpha_border off; the light regions carry white RGB padding so filtering never
pulls in black). Add `layers/manifest-entry.json` to `apps/game/assets/manifest.json` (rights status left pending).

Code: apply `beacons-code.diff` (room_depth.gd + main.tscn), i.e.
1. `room_depth.gd`: `const BEACON_ART_PARTS := 4`; exports `beacon_atlas: Texture2D`, `beacon_regions: Array[Rect2]`,
   `beacon_offsets: PackedVector2Array`; `Beacon` gains `art` and `parts` and draws fixture, lens-tinted globe and guard
   from the atlas when `art` is set (else the old housing); in `_ready`'s beacon loop, when the atlas is set and has
   `warning_lamps.size() * 4` regions, build the parts at `offset * _plate_scale()` (0.5) and make the glow a region
   Sprite2D of the atlas (`centered = false`, `offset` = the light's plate-px offset, `scale = 0.5`, additive,
   `modulate = Color(warning_color, BEACON_ALPHA)`) instead of `make_glow(...90x90...)`. Positioning, pulse, settle and
   node names (`Beacon%d`, `WarningGlow%d`) are unchanged, so `room_lights_test` needs no change.
2. `main.tscn`, CorridorDepth (ext id `23_beacons`; renumber if the door port has taken it):
```
beacon_atlas = ExtResource("23_beacons")
beacon_regions = Array[Rect2]([Rect2(2, 2, 25, 135), Rect2(242, 2, 11, 12), Rect2(212, 2, 13, 15), Rect2(29, 2, 77, 95), Rect2(187, 2, 23, 46), Rect2(2, 141, 11, 12), Rect2(227, 2, 13, 15), Rect2(108, 2, 77, 95)])
beacon_offsets = PackedVector2Array(-10.72, -108.6, -3.72, 4.4, -4.72, 4.4, -36.72, -30.6, -10.28, -18.6, -4.28, 4.4, -5.28, 4.4, -37.28, -30.6)
```
Order per lamp: fixture, globe, guard, light; offsets are far-plate px from the lamp's anchor. `layers/placement.json`
has every rect in atlas, plate and world coordinates. `warning_lamps` and `warning_color` stay as they are.
If the door job changes the far plate around (654, 183-326) or (1255-1286, 266-326) plate px, rerun
round 9's `fix2/beacons/tools/design.py` + `fix2/beacons/tools/cleanup.py` against the new plate (this round's `beacons/tools/design.py` and `beacons/tools/cleanup.py` are at ada83fa) (b1 hangs from the plate's painted back box).

## Checks run (private copy test-game = game-slice + this change)
- Headless: import twice, 13/13 test suites pass (`logs/test-game/`).
- render.sh (container, 1280x720), main = base-game (round 6), same driver as round 6:
  - Opening o0-o8 (`shots/diff/opening-v3.json`): the only changed clusters are the beacons (o0-o6 one lamp, o7/o8
    both, plus b0's 11 px conduit connector at the tray). WOLF's cage and everything else: 0 px over threshold 8;
    the corridor has no ambient dust, so there is no dust noise.
  - Corridor s1-s7 (`corridor-v3.json`): only the two lamps' areas change.
  - Budgets (`shots/*/A-720-perf*/_run.json`): draw calls s1 54 -> 47 (s2 60 -> 53, s4 56 -> 49, s7 58 -> 50; the
    drawn housing broke batching); additive items 7 -> 7; texture memory 73.868 -> 73.904 MB (+0.036); full-screen
    translucent layers unchanged (Haze, MidPlate).
- Review images: `shots/diff/main-vs-beacons-*.png` (top main, bottom new), `layers/preview-*-8x.png`
  (plate only / lockdown peak / trough / settled).
- Not done: hands-on play, device or export tests; frame times in the container are meaningless.

## Open issues
- Records and junction beacons still use the code-drawn housing (out of this track's scope; same atlas approach works).
- Glow alpha still pulses as main does (soft 2.6 s cycle). Real units are steady or 60 flashes/min; changing that is a
  timing change, so left alone.
- At 720p the globe is about 10 screen px tall: it reads as a caged red lamp, smaller and quieter than main's chip by
  design (true size). Nathanial should see it in the opening before it lands.
