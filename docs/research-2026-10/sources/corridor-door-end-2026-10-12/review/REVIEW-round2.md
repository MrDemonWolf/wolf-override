# Review, round 2: the corridor's door end (independent, adversarial)

**Verdict: fix needed. Do not show this to Nathanial yet.**

The fix pass made real progress. The door now stands in a concrete cross-wall at a slight angle, it opens onto a real room through a true hole, the stations stand on plinths with real contact shadows, and the round-1 floor seam, wall-light step, magenta fringe and tank/deck error are gone. But four things a first-time player would see in the current game still read as unreal, and the package Nathanial would open is out of date.

- **What I reviewed:** the fix-pass captures in `raw/slice/` (A-720, B-720, O-720, A-phone, B-phone, all taken 2026-10-12 03:21-07:27 on the art installed at 00:13) against the same frames in `raw/main/`. I looked at every frame at full size, in 2-5x crops and in greyscale, and ran REAL-LOOK section 3.
- **What I ran myself:** an opening re-diff, a C2PA and provenance check, a contact-shadow and value probe, and one fresh frame pair of render numbers in both copies (s1 and s5).
- **My evidence:** `scratchpad/review-r2-work/` (crops, the opening diff images, `opening.py`, `review_probe.gd` with `probe-main/` and `probe-slice/`).
- **Scope:** I edited nothing in `real-slice/` except this file. Running Godot touched only the copies' `.godot` caches and `home-realslice`; every Godot window I opened closed itself.
- **Validation:** nothing was played by hand, so I make no feel claims.

## Before anything is shown: the package is stale

The slice report for this round does not exist. Everything Nathanial would open shows round-1 art or old numbers.

- `shots/SLICE.md`, `sheet.png` and `pairs/` are timestamped 22:19-22:23 on 2026-10-11. They show the superseded frontal pier and the old bypass. `shots/round1/SLICE.md` is a byte-size copy of the same file.
- `perf.json`, `perf-table.md` and `opening-diff.json` are also from round 1. The fix-pass numbers exist only inside `raw/*/A-720-perf/_run.json` and `raw/*/B-720-perf/_run.json`.
- **Provenance gap.** Three fix-pass Codex sessions are missing from `provenance.txt`:
  - `01a12e59-e7ba-7630-b1dc-9448924148ef` (paint-far2)
  - `01a12e5c-eb97-7f63-b9cf-ec4e75fd8a9a` (paint-far2b)
  - `01a12e59-e7ba-7073-8a77-796f536bcc43` (paint-portal2)

  None of the three was archived: all three rollouts are still in `~/.codex/sessions/2026/10/11/`, and `codex/archive.log` lists only the round-1 sessions.
- **Missing file list.** The derived files are not listed anywhere: `layers/v2/`, `layers/tools/cleanup2.py`, `install2.py`, `design/portal2/`, `design/far-patch2/`, `paint/inputs2.json`, `codex/rules2.txt`.

**Fix:** after the fixes below, regenerate `pairs/`, `sheet.png`, the perf table and `opening-diff.json` from the final build, and rewrite SLICE.md for the cross-wall design. Add the three sessions to `provenance.txt`: ids, every output with its sha256, which were used and the derived files. Then run `codex archive` on each session and log it.

C2PA itself is fine. All eight Codex outputs, old and new, carry a `caBX` chunk with a `c2pa` JUMBF manifest. The three new used outputs are byte-identical to their files in `~/.codex/generated_images/`:

| Output | Generated file | sha256 starts |
|---|---|---|
| `far2-painted.png` | `exec-ed9ca3ee…` | `461867b3` |
| `far2b-painted.png` | `exec-a25a9051…` | `41e2232c` |
| `portal2-closed-painted.png` | `exec-a0bafe11…` | `2b05522a` |
| `portal2-open-painted.png` | `exec-91d0d25a…` | `9a7c71b7` |

## What holds up (verified, not taken from a report)

- **A true hole onto a real room.** Through the open doorway (s5) you see a cast back wall and a pump skid in the machinery room painted into the far plate, at the room's own light.
  - The mid plate's doorway is transparent: `report2.json` records a hole alpha maximum of 0, and the render confirms it.
  - The tucked bottom bar shows under the hood once the door is open.
  - s4 reads as a roller door winding up, and s5 is the best frame of the set.
- **The door is built like a real one.** The perspective is internally consistent. The slats, hood edge, bottom bar and `SECTOR 4B` all fall toward the design's vanishing point at world (21, 158.5) (overlay: `crops/s1-vp-overlay.png`). The opening is 3.05 m against the 1.75 m engineer.
- **Nothing in the corridor span floats.** I measured the floor 1-2 world px under each base against 8-12 px further out (s1):
  - **Relay:** 14 at the contact line rising to 34. Ratio about **0.53**; main reads 0.81.
  - **Safe point:** 20 rising to 36. Ratio about **0.67**; main reads 0.79.

  Both are darkest at the contact line, so both pass. The camera, wall pack, junction box, push-button box and lamp all sit on arms, brackets or plates, fed by conduit through one penetration plate. The tank stands on a plinth and the catwalk on a post.
- **Look 2 is unchanged.** Every fully opaque pixel of the approved relay and safe point matches the installed art at offset (16, 0), with 0 differing pixels. The on-screen size is the same as main.
- **The seam is fixed.** Floor: no column in the slice span has a persistent vertical step (main's own legacy steps are left of x 540). Wall at the column, rows 200-300: (25, 45, 53) left and (31, 49, 57) right.
- **Round-1 fixes confirmed in the renders:**
  - No violet fringe (`report2.json` records 0 violet pixels in an 8 px band).
  - The deck no longer cuts through the tank.
  - The upper wall is dark: p50 24.6.
  - The wheel rim out-values its wall: rim p90 92 against wall p90 30.
  - The crank hand lands on the rim.
  - The shut lens is dark glass.
  - The mirrored right near-strip is gone.
- **Text and marks.** `SECTOR 4B` and `DOOR 4B-07` are typeset at 12 world px and both are on the approved list. Nothing in the Codex art reads as lettering, and no keypad or card reader was added.
- **Nothing from the films.** There is no Skynet, Terminator or Cyberdyne name, logo, typeface or machine shape, no skull, red-eye or chrome look, and no model-number style. The camera is a generic box camera on a wall arm.
- **Headless tests:** 13 of 13 pass (`logs/tests-slice-fix/`). One relaxation, in `m0_scene_test`, is reasonable for the new wheel: the hub clearance went from 6 px to 3 px.

## Must fix before Nathanial sees it (ranked)

### 1. The near pier turns to glass whenever an actor is behind it

In s6 and s7 the whole near pier is drawn at 50% alpha (`PILLAR_FADE_ALPHA 0.5` via `cover_rect` 784..834 × 236..464). That is a 70 x 420 screen-px rectangle from y 135 to the floor.

- Through it you see the catwalk rail, the tank and the machinery wall: luminance goes from 23 to 45 in the same patch (s5 against s6).
- Its vertical edges carry on down across the floor (`crops/s6-door-3x.png`, `crops/phone-s7-feet-2x.png`).
- The live green lens and its glow stay at full strength, so a lamp hangs in mid-air inside see-through concrete.

This is the strongest "generated / composited" tell left in the slice. Main's fade was for a small pillar; on a full-height concrete pier it reads as glass.

**Fix:** keep the pier opaque. While an actor is behind it, draw that actor over the pier as a dim flat silhouette: one extra sprite with a flat-colour shader, shown only while covered. Or narrow the pier's walk-line cover so the safe-point user at x 831 is not behind it. If any fade stays, it must be a soft-edged window around the actor, never the whole rectangle, and the lens and its glow must fade with it. Re-capture s6 and s7.

### 2. The cross-wall still does not cross the corridor

The pier's foot ends at world y about 464 (screen y 540). Below that, the corridor's wet floor runs on in front of the wall, under the machinery room, to the right edge of the frame. On the camera model that is roughly 15 m of open floor nearer the camera than the wall's end.

- The machinery room's matte floor fades into the wet floor through a soft gradient (screen y 500-550) with no joint, threshold or wall foot (`crops/s1-base-3x.png`).
- As a first-time player: the door stops the walk line, but the floor plainly continues around the wall, so the heavy portal across the way blocks nothing. This was round-1 item 1's "either way" part, and it is still open.

**Fix:** make the pier the cut end of a wall that reaches the camera.

- In the front layer, carry the pier's cut section (dark cut concrete with its steel edge angle) from world y 464 down past the bottom of the view, to at least the mid plate's bottom bleed.
- Right of it, paint the machinery room's own floor down to the bottom of the frame, with a real floor joint or steel threshold, so the wet corridor floor ends at the wall.
- Combine this with fix 1, because actors will spend longer behind the section.

### 3. The MANUAL BYPASS is not wall-mounted, and its mechanism is hidden

The brief says "rebuilt as a real wall-mounted manual override". REAL-LOOK section 2 says "a 0.4-0.5 m handwheel on a wall gearbox with its centre at 1.05 m". The fix pass built a cast floor stand instead (a 0.12-0.16 m pedestal on a 0.45 m flange), with a 60 mm guard tube running diagonally through open air from the gearbox up to the door operator.

- At 1x it reads as main's "wheel on a pole" again, the very thing Nathanial objected to (`crops/s1-bypass-3x.png`, `crops/s1-shaft-contrast-4x.png`).
- The shaft is unsupported along its whole run.
- The `MANUAL BYPASS` plate, moved to x 712-826 and y 188-275, covers the shaft's upper U-joint and the whole door operator it drives, so wheel, shaft and operator never read as one machine (`crops/s1-operator-5x.png`).
- The wheel's hub is at about 0.92 m, not 1.05 m.

**Fix (or get Nathanial's explicit OK for a floor stand):**

1. Bolt a backplate (about 0.5 x 0.6 m, four anchors) to the cross-wall's far column face or to the corridor back wall.
2. Put the worm gearbox on it with the wheel centre at 1.05 m (world y 398).
3. Run the drive straight up the wall to the operator at 3.1 m, in a chain guard or an enclosed shaft held by two wall brackets. Do not run it diagonally through air.
4. Move the plate so the operator and the top of the drive are visible. Keep the existing collision, the reach and the hand-on-rim pose.

### 4. The opening is no longer pixel-identical to main (rule 5 regression)

My re-diff of the current `O-720` frames (`review-r2-work/opening.py`, images in `review-r2-work/opening/`) finds main's dust and also a second difference:

| Frames | Where (screen) | How big | How strong |
|---|---|---|---|
| o0, o1 | x 1270-1279, y 2-88 | 469 px | up to 2 levels |
| o4, o5, o6 | x 1245-1279, y 0-99 | about 2,300 px | up to 7 levels |

- **Where it sits:** in every case left of the screen position of world x 540.
- **What it is:** the slice is brighter, and red-dominant (for example main (11, 16, 17) against slice (16, 18, 19)). It is a soft round halo coming in from the frame edge (`crops/o4-topright-main-slice-diffx30.png`).
- **Likely cause:** the fix pass moved the corridor's second lockdown beacon from far x 0.659 to 0.62 (`main.tscn`, `warning_lamps`). Its red glow now reaches into the opening's framings.
- **Why it matters:** round 1's diff of o0-o6 was clean apart from dust, so this is new. It is invisible at a glance, but rule 5 says exactly as on main.

**Fix:**

- Put the beacon back at 0.659, or clip or position its glow so nothing reaches world x < 540 in any opening framing.
- Re-capture O-720 and re-diff with a check that fails any blob left of world x 540 that is brighter in the slice.

### 5. Compression blocking on the new calm concrete, and a pasted rectangle on the pier

The corridor mid plate is imported VRAM-compressed (`compress/mode=2`, `high_quality=false`, lossy 0.7), which is S3TC on desktop and ETC2 on phones. The new calm concrete is smooth and dark, so 4x4 blocks show as a faint checker over the cross-wall face and upper wall. They are clear under a contrast stretch (`crops/phone-text-5x.png`) and faintly visible at 1x on a bright phone screen. Main's grungy plates hide the same blocking.

The seal front layer is lossless (`compress/mode=0`). Where it meets the compressed mid plate, the pier shows a hard rectangle:

| Edge (s1) | Mid plate side | Front layer side | Step |
|---|---|---|---|
| Top edge, screen y 136 (x 985-1030) | 17.9 | 23.3 | +30% |
| Left edge, screen x 978 (y 150-250) | 22.8 | 30.2 | +32% |

See `crops/s1-frontbox-contrast-4x.png` and `crops/s1-top-3x.png`. In s6 and s7 this rectangle is the ghost's outline.

**Fix:**

- Keep the whole pier, top to foot, in one layer with one compression.
- Add fine grain (±2-3 levels) to large calm faces before import so DXT and ETC2 do not band.
- Check the ETC2 import (the mobile path), not only S3TC.
- Optionally use `high_quality` for this one plate if the memory budget allows.

## Smaller items (fix in the same pass)

1. **Draw calls go over budget in two states.** The fix-pass monitors read 61 in s2, and 60 (max 64) in s3. REAL-LOOK allows at most 60. Atlas the six seal and bypass textures (curtain, open bar, frame, front, lens, wheel) into one.
2. **Values and palette beyond the door.**
   - **Values:** the machinery room's back wall averages luminance 64 and the floor 51. That is brighter than the engineer (42) and WOLF (54), so the background is the brightest large mass in the frame (`crops/s1-grey.png`).
   - **Saturation:** it is far greyer than the corridor (0.19-0.23 against 0.54-0.58 on the old wall and floor), so the right sixth of the frame reads like a different game. The cross-wall sits between at 0.29-0.38.
   - **Fix:** darken the room beyond to about 35-45 with a defined pool under its visible high-bay, and let a little of the corridor's cold grade reach the cross-wall face.
3. **The tank's dome is lit from nowhere.** Under high-bay B, which hangs directly above it, the dome top is the tank's darkest part: 16-25, against 31-34 on the body. The body is lit only from the left. Light the dome's top from B (`crops/s1-machtop-3x.png`).
4. **The yellow floor line is missing.** The design (`wall--floor_line`) and REAL-LOOK section 8 item 3 ask for one yellow line at the door's travel, but there are 0 yellow pixels on the floor in s1 or s5. Only the bar's stripes are yellow. Restore it or drop it from the spec.
5. **Reds in view.** s1 shows two lit beacon housings and the e-stop. The beacons are on the live list, so this is acceptable, but section 8 asks for one red per view. Consider a grey stop button (no cap colour) on the push-button box, or confirm with Nathanial.
6. **The phone captures are not 20:9.** The project keeps aspect, so the saved "2400x1080" frames are the 1920x1080 viewport. Label them as such, or save the window with its pillar bars so Nathanial sees what a phone shows.
7. **The stencil bridges barely read at 1x.** The marks read as plain condensed type. That is fine, but it adds little to the military read (next item).

## Does it read as a near-future military base?

**Partly.** It now reads as a secure, machine-run utility area, and no longer as a sci-fi lab:

- a cast cross-wall
- a numbered gunship-grey door with hazard stripes
- a fixed camera on an arm
- a lockable junction box and grouped conduit through a penetration plate
- `SECTOR 4B`

The roller shutter and the tank-and-catwalk room still say "industrial plant" more than "hardened base". The 160 mm steel channel round the opening is in the spec but does not read at 1x.

Without new text or keypads, these would help, all subject to Nathanial:

- a visible armour frame or edge angles round the opening
- the section 8 vestibule with a closed inner blast door
- `RESTRICTED AREA` or `AUTHORIZED PERSONNEL ONLY` from the approved list, if he picks them

Nothing is taken from the Terminator films.

## AI-tell checklist (REAL-LOOK section 3, on the in-game captures)

| # | Item | Result |
|---|---|---|
| 1 | Vanishing lines | Pass. The door, hood, bar, marks and pier foot meet one vanishing point. The machinery room is in elevation. |
| 2 | One light logic | **Fail (small).** The tank dome is dark under its lamp (small item 3). The room beyond is evenly bright, mostly from a hidden high-bay (small item 2). |
| 3 | Every part has a job | Pass with a note: the diagonal drive shaft has no support (must-fix 3). |
| 4 | Nothing floats | Pass on bases: relay 0.53, safe point 0.67, plus the tank plinth and catwalk post. **Fail in s6 and s7**: the lens hangs inside a see-through pier (must-fix 1). |
| 5 | Scale | Pass. The opening is 3.05 m against the 1.75 m engineer, and the wheel is 0.525 m. Its hub is at about 0.92 m, not the specified 1.05 m. |
| 6 | Doors | Pass on the hole (alpha 0, its own room behind). **Fail** on blocking: the floor runs past the wall (must-fix 2). |
| 7 | No text | Pass. Typeset, listed marks only. |
| 8 | Detail and values | **Fail.** Compression blocks on calm faces, the pier rectangle step (must-fix 5), and the background brighter than the actors (small item 2). |
| 9 | Wear logic | Pass. A damp band at the wall foot, wear at the bar's centre and the threshold; no speckle. |
| 10 | No repeats | Pass. The mirrored near strip is gone. |
| 11 | Rule 5 | **Fail.** A red glow edge in o0, o1 and o4-o6 (must-fix 4). |
| - | Compositing | **Fail.** The ghosted pier with a floating lens, and the pasted rectangle edge on the pier. |

## Before and after, as a first-time player

| State | What changes |
|---|---|
| s1 at rest | **Before:** a garish red gate standing across the floor. **After:** a believable concrete cross-wall with a grey roller door, a camera and a lit room beyond. The open wet floor running past the wall's foot undercuts the blocking, and the bypass reads as a wheel on a stick. |
| s2 relay beat | The engineer stands at the door face correctly, in front of the curtain. The stations sit on plinths with real shadows. |
| s3 crank | The hand is on the rim (better than round 1). The wheel stands on a thin pedestal, and its drive vanishes behind the name plate. |
| s4 opening | It reads as a roller door winding up, with the real room appearing beneath the bar. Good. |
| s5 open | A real hole with a real room behind it. The best frame. |
| s6 walk through | The engineer stands in the doorway, which works, but the near pier goes translucent and the green lamp floats in it. |
| s7 safe point | The same ghost pier. WOLF stands on the threshold, and the engineer uses the safe point inside the machinery room. |
| Seam | Hidden. Values and floor match at the column, and the pipe run continues across it. The old grimy teal wall against the new calm grey still shows as a change of finish, which is acceptable as two different bays. |

## Render numbers: my own re-measure (desktop, Apple M1 Pro, GL Compatibility, 1280x720)

The machine was heavily loaded during my run (load average 62-78), so treat frame times as noise. Draw calls and memory are deterministic.

| State | Draw calls (main -> slice) | Texture MB | Video MB | Frame ms p50 / p99 | Render CPU p50 | World coverage | Full-screen translucent | Dust emitters |
|---|---|---|---|---|---|---|---|---|
| s1 door end at rest | 72 -> 56 | 72.0 -> 71.6 | 78.3 -> 78.0 | 1.96/5.92 -> 1.67/6.38 | 0.42 -> 0.35 | 3.63 -> 3.24 | 5 -> 2 | 2 -> 0 |
| s5 door open | 71 (max 75) -> 56 (max 60) | 76.7 -> 71.6 | 83.0 -> 78.0 | 1.99/5.94 -> 1.97/8.15 | 0.42 -> 0.41 | 3.57 -> 3.13 | 5 -> 2 | 2 -> 0 |

- **Full-screen translucent layers:**
  - Main: Haze, MidPlate, Grade, IntroAlarm and IntroFade.
  - Slice: MidPlate and Grade. The round-1 point about the intro quads is fixed, so this meets the budget of at most 2.
- **Agreement with the fix pass:** my numbers match the fix-pass monitors in `raw/*-perf/_run.json` (s1 56 draw calls, 71.61 MB). They do not match the stale SLICE.md (69.9 MB, 57 draw calls).
- **Still over budget, and should be stated honestly:**
  - Overdraw is about 3.1-3.2 against a target of 2.0.
  - Resident texture memory is 71.6 MB against 45 MB. This is structural, because every room is built at start.
  - Draw calls are over in s2 and s3 (small item 1).
- **No phone claim:** desktop frame times show no measurable change, and they prove nothing for phones.

## What I would need to pass it

1. Fixes 1-5 above, then fresh captures of all seven states at 1280x720 and in phone shape, plus the opening.
2. A clean opening re-diff showing only dust left of world x 540, with slice-brighter blobs treated as failures.
3. Regenerated pairs, sheet, perf table and SLICE.md.
4. `provenance.txt` completed, and the three sessions archived.

The small items should go into the same pass. Then a second reviewer, and only then Nathanial.
