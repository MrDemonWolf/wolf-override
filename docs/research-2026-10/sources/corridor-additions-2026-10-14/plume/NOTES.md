# add7 / plume: the coolant relief jet (item g)

Round 6's review found that the coolant hiss while cranking (BypassHandle/CoolantHiss, FxPresets.steam(): 24 soft
dots, alpha 0.35, core luma about 204-230) reads as a glowing pale disc with no source. This track replaces it with a
real fitting and a real discharge: a spring-loaded safety relief valve on the crown of the coolant relay's side pipe,
with a short open tailpipe turned down, and a narrow, faint jet from that tailpipe's mouth.

Nothing here was played by hand. Every frame below is a render.sh capture or a composite onto one, so this makes no
claims about feel.

## How the real thing looks (sources)

- **Valve placement and tailpipe.** Emerson, *Kunkle Pressure Relief Valves: Operating and Safety Instructions*
  (KUKDR-0001-EN-1305), installation steps 1-2:
  - "Mount the valve in a vertical position so that the valve body is self draining."
  - "The inlet piping should be as short as possible, with no elbows."
  - "Discharge piping, other than a short tailpipe, must be supported."

  https://www.pdblowers.com/wp-content/uploads/2017/10/Emerson-Kunkle-Installation-and-Operation-VCOSI-01867-EN.pdf
  (saved as work/dl/kunkle.pdf; sha256 213e479c... matches a fresh download).
- **Which way the discharge points.** Apollo (Conbraco) safety relief valve tag I352500, item 7 and items 8a, 8d and 8e:
  - The valve is "mounted in a vertical, upright position directly to a ... tapped opening in the top of the ...
    equipment".
  - The discharge line is "directed downward to a safe point of discharge" and is "as short and straight as possible".
  - It "terminates freely to atmosphere where any discharge will be clearly visible".

  https://media.distributordatasolutions.com/xlsx_apollo_valves/2021q4/documents/e0033e647de5e0e76a516dab48f6d07afdc702cb.pdf
  (saved as work/dl/apollo.pdf; sha256 ef709c58... matches a fresh download).
- **What the discharge looks like.** TLV, *Trap Leaking Live Steam?*:
  - "Live steam is invisible ... the short distance of space between the pipe outlet and visible vapor will tend to be
    clear and of relatively higher velocity."
  - "If the vapor seen is lower velocity and appears visible immediately at the pipe outlet, then it is most likely
    flash steam."

  Hot coolant (water or glycol) that relieves to air flashes, so it is visible right at the mouth: faint white, low
  speed, gone within a short distance.
  https://www.tlv.com/steam-info/steam-theory/steam-basics/trap-leaking-live-steam
- **How fast a jet widens.** Bauersfeld et al., *Robotics meets Fluid Dynamics* (arXiv 2403.13321), citing S. B. Pope,
  *Turbulent Flows* (CUP 2000): "the spreading angle is commonly around 12 deg and is weakly dependent on the flow
  Reynolds number." https://arxiv.org/html/2403.13321
  The in-game jet measures about 1.6 px at the mouth and about 6 px wide after about 19 px of travel, which is about
  14 degrees.

## The fitting (art)

It sits on the relay's side pipe, not on the bypass gearbox. The engineer stands at x 674 facing right toward the
wheel at (700, 398), so a port on the gearbox would point at their hands or face. The relay's side pipe is behind
them and to the left.

Its construction (tools/design.py, exact masks at 8x supersampling; design/parts.npz, construction.png and
construction-8x.png), bottom to top:
- a socket-weld boss on the crown of the side pipe's upper elbow, with a fillet bead
- a hex inlet nut
- a cast bronze body with a side outlet and a steel hex fitting
- a tapered spring bonnet, a cap, and a test lever with a knob
- the tailpipe: a nipple with a union, a long-radius 90-degree elbow, and a short drop ending open, pointing DOWN

Sizes: 1 relay art px is about 6 mm (0.25 scale, about 42 world px per metre). The valve is about 240 mm tall, a
1-1/4" valve (discharge OD 6.5 art px, about 40 mm) on an approximately 8" line. The tailpipe runs about 0.36 m to
the right, so its mouth clears the pipe loop.

How it was painted: Codex built-in image tool, edit mode, one session (01a1335a-f620-7b42-ae60-ce8dce78c082),
recorded in add7/provenance.txt and archived (codex/archive.log). The original output is kept byte-identical with
its C2PA caBX chunk at codex/paint-relief/out/relief-valve-painted.png.

Cleanup (tools/cleanup.py, report in layer/cleanup-report.json):
- registration shift (-0.5, 0) at 1024 px
- paint is used only inside the masks, with value gains (bronze 0.92, steel 1.0) back to the construction's value plan
- **938 relay px changed, 0 outside the mask**, all inside art box (291, 52)-(356, 94)

Files:
- `layer/corridor-coolant-relay.png`: the full replacement prop, 368x408 RGBA, SHA-256 fb192cc2...
  It is identical to game-plume's copy.
- `layer/relief-valve-layer.png`: the fitting alone, 368x408 RGBA, transparent outside bbox (291, 52, 356, 94), in
  case the relay art is re-based.
- `layer/check-8x.png`: an 8x review crop.

Placement: there is no new node and no new texture. The relay sprite in main.tscn is unchanged (position
(607.625, 389), scale 0.25, region 0,0,368,408), so its art origin is world (561.625, 338.0):
- fitting bbox in world: (634.4, 351.0)-(650.6, 361.5)
- tailpipe mouth: art (352, 92) = **world (649.625, 361.0)**
- from the BypassHandle node at BYPASS_WHEEL (700, 398): (-50.375, -37.0)

## The jet (runtime)

It is one CPUParticles2D, the same single node and draw as before, with normal blending (no additive, no glow) and
no new layer. It is a new preset, `FxPresets.relief_jet()`:

| param | value | why |
|---|---|---|
| amount / lifetime | 16 / 0.36 s | a short, continuous stream (was 24 / 0.75) |
| direction / spread | (0, 1) / 5 deg | straight down out of the drop, narrow |
| initial velocity | 62-72 px/s | |
| damping | 55-70 | it slows as it mixes, so its travel is about 20 px (about 0.45 m) |
| gravity | (0, -10) | slight buoyancy of warm vapour |
| particle_flag_align_y | true | each streak stretches along its travel |
| texture | GradientTexture2D 10x16, radial, alpha 1 / 0.4 / 0 at offsets 0 / 0.45 / 1 | a soft ellipse, not a dot |
| scale min / max | 0.98 / 1.15 | |
| scale curve | (0, 0.174), (0.3, 0.478), (1, 1.0) | it starts pipe-narrow and flares to about 11 px |
| color | (0.84, 0.90, 0.93, 0.18) | faint, white to clear, a touch cool |
| color ramp alpha | 0.8 / 1 / 0.45 / 0 at 0 / 0.12 / 0.45 / 1 | visible at the mouth (flash), gone by the end |

The mock used scale 0.85-1.0 with a curve peaking at 1.15. Godot curves clamp to 0..1, so the code moves the 1.15
into scale_amount. The result is identical.

Measured in the render.sh capture (mock/stats-720.json and stats-phone.json agree with it):

| | round 6 disc | relief jet |
|---|---|---|
| peak luma near the relay | about 230 | about 86-90 |
| mean lift in the jet | | about 25 over the wall's about 25 |
| peak alpha | | 0.29 |
| visible length | | 18-20 world px |
| visible width | | 5.5-6.7 world px |
| x extent | | x 646.1-653.3, all left of the engineer's body (left edge about 660) |

## Code changes (patch, not applied)

- `patch/plume.patch`: the full patch, generated with `git diff --binary` against game-slice. It contains:
  - manifest.json: modifications and implementation_status of the relay entry
  - corridor-coolant-relay.png: a literal binary hunk, preimage blob 38bfcf9
  - bypass_handle.gd
  - fx_presets.gd
- `patch/plume-code.patch`: the same, without the PNG hunk.

Changes:
- **fx_presets.gd**:
  - adds `static func relief_jet() -> CPUParticles2D`, with the parameters above
  - adds `static func _streak_texture(width, height) -> GradientTexture2D`
  - updates the class doc
- **bypass_handle.gd**:
  - `HISS_OFFSET` is replaced by `const RELIEF_OUTLET := Vector2(649.625, 361.0)`, the world point of the tailpipe
    mouth
  - `_init()` builds `coolant_hiss = FxPresets.relief_jet()`, keeping the node name `CoolantHiss`, and drops the
    per-instance overrides
  - `place()` sets `coolant_hiss.position = RELIEF_OUTLET - wheel_centre`
  - the `venting` setter is unchanged, so it still toggles `emitting`: no new timing and no gameplay change
  - doc comments are updated
- Unchanged: `FxPresets.steam()` itself, which the junction's vent_steam and coolant_cloud still use.

To integrate, from the root of game-slice, or of main after round 6 lands:
`git apply --check <plume>/patch/plume.patch && git apply <plume>/patch/plume.patch`.
I checked it here against a copy of game-slice: it applies cleanly and reproduces game-plume's four files byte for
byte. If the binary hunk refuses because the relay PNG's base changed, apply `plume-code.patch` and copy
`layer/corridor-coolant-relay.png` over `assets/props/corridor-coolant-relay.png`. If the relay art itself changed,
re-run tools/cleanup.py on the new base instead, since it merges only inside the masks. The manifest hunk touches
only the coolant relay entry. Then import twice headless.

## Checks

- **Headless** (game-plume, own HOME, after two imports): all 13 suites pass (logs/*_test.log). These are chapter
  scene, follow spacing, hold use, impact, junction, m0 scene, m0 state, room depth, room lights, sentry, settings,
  sfx bank and UI controls.
- **render.sh** (`--name add7-plume`, round 6's driver and arguments, tools/capture.sh): shots/B-720, shots/B-phone
  (s3), shots/B-720-perf and shots/A-720-perf (s1, s2, s4-s7).
  - Every perf number equals round 6: s1 54 draw calls, s3 63, additive items 7, texture 73.87 MB, video 80.24 MB,
    full-screen translucent layers 2.
  - The perf sample in s3 caught the jet off in both runs (particles_emitting 0), so the jet's own cost is not in
    that number. By construction it is one node and one draw call, as before, with fewer and smaller particles.
- **s3 against round 6** (720p): 17,271 px changed, x 654-800, y 297-463. Every one is darker than round 6, since
  the disc and its fringe are gone; no pixel is brighter by more than 10.

## Frames

- **mock/sheet-before-after.png** (rebuilt 2026-10-13 from the final captures): it compares round 6, the mock, and
  this track's render.sh capture. Each row shows 720p context at 1.5x, 720p at 4x, and phone shape at 3x.
- **mock/s3-720-after-0..2.png and s3-phone-after-0..1.png**: three moments of the simulated jet (tools/jet_sim.py
  re-implements CPUParticles2D's update and draw), composited onto round 6's s3 capture with the disc removed
  (tools/clean_bg.py).
- **mock/s3-720-valve-nojet.png and s3-phone-valve-nojet.png**: the valve without the jet.
- **work/jet-zoom-mock-720-phone.png**: the mock, the in-game 720p frame and the in-game phone frame side by side.
- **work/phone-r6-vs-plume.png**: the full phone frame, round 6 above and this track below.

## Open issues

1. **Scale.** At 720p the valve is about 29x19 screen px. A first-time player reads it as "a fitting with a pipe the
   coolant comes out of", not as a named relief valve. The test lever is sub-pixel, and the bronze bonnet reads as a
   thin upright stub. That is enough for the jet to have a visible source. Making it bigger would make it oversized
   for a 1-1/4" valve.
2. **Tailpipe run.** The horizontal run (about 0.36 m) is drawn level. Kunkle asks for self-draining discharge, so a
   real fitter would pitch it slightly down. That is invisible at this scale.
3. **Stale manifest text.** The relay entry still says "0.221x (89 px tall, as before)", which comes from main and
   predates this track. The sprite is drawn at 0.25 (92x102 world px for the region). This patch leaves that wording
   alone.
4. **Motion not reviewed in game.** Only one in-game moment of the jet (s3, tick 4) was captured. Its motion was
   judged from jet_sim's three mock frames, not from a played or recorded sequence.
5. **The junction still uses steam().** The junction room's vent_steam and coolant_cloud still use the old soft-dot
   steam(). They are outside this track and were not reviewed for the same sourceless-disc tell.
6. **Merge order with sibling tracks.** The crank track (main.gd, floor_reflection.gd) and the beacons track
   (room_depth.gd, main.tscn) touch none of these files. If the door track also edits manifest.json, its entries
   differ, but hunk offsets may need a 3-way apply (`git apply -3`).
