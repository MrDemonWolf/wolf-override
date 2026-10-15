# add7 track DOOR: blast frame, RESTRICTED AREA sign, inner blast door, conduit strap

Scratch only, 2026-10-12. No Git repository, worktree or game copy was touched. Everything is in `real-slice/add7/door/`, plus one appended section in `real-slice/add7/provenance.txt`. Nothing under `real-slice/` that already existed was modified. Round 6's tools were imported read-only, with no bytecode written.

**How this was checked:**
- Python previews composed the way the game layers the pieces (`tools/compose7.py`).
- One headless Godot parse and maths check of the proposed `BlastLeaf` script, in a throwaway project (`door/integration/gdcheck/` at ada83fa; removed from the records, since its `blast_leaf.gd` was the proposal below).
- **Not done:** no render.sh capture and no in-game capture (the art is not in any game copy yet), nothing played, no phone. So this note makes **no in-game or feel claims**.

## What a player sees (think as a human)

- **Shut (s1).** The door is as before, now set in a heavy steel frame of bolted armour plates. The band of plates over the hood and the strip down the far jamb carry one row of anchor bolts each. Over the door is a white steel sign plate with the black stencil RESTRICTED AREA. SECTOR 4B stays above it, and DOOR 4B-07 stays on the hood.
- **Opening (s4).** The roller rises. Behind it is a second, much heavier door: a dark steel-faced slab, with its leading edge in yellow and black stripes. Once the roller is 40 % up, the slab slides back into the wall, away from the corridor, on wheels in a floor rail. The plant room appears behind it.
- **Open (s5).** The slab is home in a pocket in the wall. Its striped edge stays visible in the pocket's mouth, between two black rubber wiper seals, flush with the doorway's side, and the rail crosses the threshold into the pocket. Nothing blocks the way. It is clear where the heavy door went and how it moves.
- **Strap.** One saddle strap on the 1.54 m vertical lamp conduit at 3.45 m (1-2 px at 1x).

**Previews** (construction previews, not captures):
- `work/v7/strip-game-2x.png`: o = 0, 0.55, 0.70, 0.85 and 1 at 1280x720 scale.
- `work/cmp-r6-r7.png`: round 6 against round 7, shut and open.
- `work/v7/v7-o*-4x.png`: 4 px per world px.
- `work/strap-r6-r7-12x.png`: the strap.

## Design (construction first: `tools/portal7.py`, `design/spec.json`, `design/masks/`)

The design uses round 6's camera and the cross-wall's frame. Its lines meet the same second vanishing point, VP2 (21, 158.5). Measurements: a runs along the face from the walk line toward the back wall, t runs into the wall, h runs up, and the engineer is 1.75 m (1 m = 40 world px).

- **(a) Steel blast frame.**
  - Armour plates 25 mm proud of the concrete (36118, painted).
  - Jamb plate on the far column: 0.55 m wide from the jamb, 0 to 3.92 m, in three plates (joints at 1.30 and 2.60 m).
  - Head plate over the opening: 3.05 to 3.92 m, under the door light's bracket at 3.98 m. It shows above the hood from 3.5 m, in three plates (joints at a = -0.85 and 0.35 m). It is carried over the near column's 0.16 m approach face (`front--bf_near_head`), so the column stays exactly as slim as round 6's.
  - M24 anchor bolts at 300 mm pitch, one row on each visible plate edge. The rows under the guide and the hood are not drawn.
  - Real basis: blast-door frames and subframes are anchored into the concrete to carry blast and rebound into the structure [D1].
- **(b) RESTRICTED AREA sign.**
  - A 3.0 x 0.54 m steel plate at 4.80-5.34 m over the doorway, centred on the opening, with six anchors.
  - It is lusterless white 37875, weathered, measured at luma 48.6 in the layer. The stencil is black 37038, luma 11.
  - Text: exactly RESTRICTED AREA, typeset by script in the game's bundled Roboto (SIL OFL 1.1, `Roboto-OFL.txt`; no new font), wght 700, wdth 75, with stencil bridges cut by round 3's `bridges()`, in the face's own plane. Cap height 0.24 m = 9.6 world px = **17.3 px at 1280x720**.
  - Why over the door and not beside it:
    - The wall beside the door on the approach side is the far column. On screen it is 17 px wide and foreshortened to about 48 %, so 15 letters at 12 px or more do not fit.
    - The corridor wall left of it holds the bypass, its MANUAL BYPASS plate and the COOLANT FAULT tag.
    - Over the door is also the usual place for an entry sign on a boundary.
  - Colour: real US Army restricted-area signs are white with black and red lettering [S1]. No red is used here, because the beacons and seal lamp are this view's reds (REAL-LOOK section 8: at most one red element).
- **(c) Inner blast door.**
  - A **horizontal sliding blast leaf**, 3.95 m long, 3.2 m tall and 0.24 m thick: 10 mm steel faceplates (36081) on a concrete core.
  - It runs in a 0.28 m slot in the wall's thickness (t 0.20-0.48 m behind the face) on two flanged-wheel trucks on a flush crane rail.
  - Shut, its leading edge sits in a receiver in the near jamb (behind the column). It travels 3.654 m back along the wall into a pocket in the far side. The pocket extends past the corridor's back wall into the mass behind it.
  - Parts:
    - a 100 mm leading-edge channel;
    - weld seams at 1.3 m faceplate widths;
    - a 160 mm bottom rail with two bolted truck covers;
    - a rubber bottom sweep;
    - on the leading edge, two 50 mm steel angles with 45-degree yellow and black caught-between stripes between them (OSHA yellow [M9]);
    - rubber wiper seals at the pocket's mouth.
  - Real basis for sliding blast closures on rails:
    - the Minuteman launcher closure, 110 tons of reinforced concrete and steel, 3.5 ft thick, which slides on a steel track and is held shut by a large steel pin [D2];
    - bombproof hangar sliding doors, about 90 t per half, on undercarriages and flanged wheels on rails set in concrete [D3];
    - concrete-cored blast doors with steel faceplates and rubber perimeter seals [D1].
  - Why sliding and not rising or hinged:
    - A hinged leaf would swing either into the corridor or across the view of the plant room.
    - A leaf rising into the head would show nothing once open.
    - A pocket slide is physically possible here, and it leaves the door visible when open.
- **(h) Strap.** `lamp_conduit_strap2` at h 3.45 m (world 806.0, 310.4), painted with round 6's strap steel (sRGB 31, 39, 45).

## Paint and cleanup

**Paint.** One Codex session, built-in image tool in edit mode, with C2PA kept: `01a13367-ff5e-7032-9f9a-2a89354a3561`, archived. It painted:
- material on the new wall parts, in place (`codex/paint-door7/refs/`);
- the leaf's front and edge as flat elevations.

The tool returned 1254 px. Alignment was measured as a pure scale 1254/1024 at offset 0. It also repainted protected areas.

**Cleanup** (`tools/cleanup7.py`):
- Codex's paint is used **only as relative high-pass detail** (clamped to ±12-15 %) inside the design masks. Values are never taken from it.
- Each part's value is its albedo times the light round 6 already painted at that place:
  - the concrete face's light for the plates and the sign;
  - the steel reveal's light for the seals and the parked edge;
  - the threshold's light for the rail.
- Bolts, joints, bolt shadows, the sign's stand-off shadow and the stencil are deterministic.
- Outside the new masks, round 6's wall layer is untouched: **0 px changed** (`layers/report7.json`).

**The leaf's light belongs to the place, not to the moving leaf:**
- Front face: a 9 x 9 table of vertex colours on its plane (`design/spec.json` `leaf.light_table`). The light comes from the corridor luminaire, the door light and the floor bounce, each counted only where it sees the plane through the doorway.
- Edge: lit as the far reveal is, falling off while the gap behind it is small.
- In the layers, the leaf face reads luma 18-30 (curtain 30, plant room 23-45) and the parked stripes about 39, so nothing is brighter than the actors.

## Files

- **Design:**
  - `tools/portal7.py`: parts, masks and spec. `tools/stack.py` imports round 6's stack read-only.
  - `design/`: `spec.json`, `masks/`, `design-add-*.png`, leaf albedo elevations, `flat7/` (the flat design layer set).
- **Paint:** `codex/paint-door7/` (prompt, refs, `panels.json`, `out/door7-painted.png` with its C2PA, `notes.txt`, `run.log`, `session.txt`), `codex/run_job7.sh`, `codex/archive.log`. The edit target is built by `tools/codex_inputs7.py`.
- **Layers** (`tools/cleanup7.py`, in `layers/`):
  - `portal-wall.png`, `portal-front.png`, `leaf-front.png`, `leaf-edge.png`, `report7.json`;
  - copies of round 6's unchanged curtain, open bar, frame, wheel, lens, far and mid plates.
- **Game-ready** (`tools/install7.py`, `door/tools/install7.py` at ada83fa; round 10's `fix3/door/tools/install10.py` is the current packer; in `game/`; nothing copied into any game):
  - `corridor-seal-atlas.png` (1024x1024, as round 6);
  - `placement.json` (regions, world positions, owning nodes, the leaf's motion and maths);
  - `atlas-regions.json`;
  - far and mid plates, unchanged.
- **Integration:** `door/integration/blast_leaf.gd` at ada83fa (landed, revised, as apps/game/scripts/blast_leaf.gd) (the proposed `BlastLeaf` node) and `integration/main.gd.snippet`.
- **Previews:** `tools/compose7.py`, `tools/leafmesh.py` (the Python reference of the mesh), `work/`.
- **Research:** `research/ufgs-08-39-54.pdf` and `.txt`. Round 6's references were copied to `ref-round6/`.

## Integration (exact)

1. **Atlas.** Replace `res://assets/props/corridor-seal-atlas.png` with `game/corridor-seal-atlas.png`.
   - Every existing region and `*_AT` constant is **identical** to round 6's (checked).
   - Only two existing pieces change pixels: `CorridorSealWall` (25,729 px: frame, sign, pocket edge, seals, rail) and `CorridorDoorFront` (262 px: near head plate, bolt, strap).
   - New regions: `leaf_front` at (449, 705, 158, 256) and `leaf_edge` at (613, 705, 19, 256), with a 2 px extruded gutter.
2. **Code.** Add `door/integration/blast_leaf.gd` at ada83fa as `scripts/blast_leaf.gd` (it landed, revised, as apps/game/scripts/blast_leaf.gd), then apply `integration/main.gd.snippet`:
   - `BlastLeaf` is a door-body child drawn just before `SealLeaf`, with the same atlas, so it batches.
   - It is visible only while the seal slides.
   - The existing tween drives both leaves through `_set_seal_open`, with the same 1.0 s, quad in-out easing.
   - Slide fraction: f = clamp((open - 0.4) / 0.6, 0, 1).
   - Leading edge: a_lead = -2.19069 + 3.65417 f.
   - No collision, timing or gameplay change: the body still blocks until the tween lands.
   - The GDScript projection matches the Python reference to 0.001 px at o = 0, 0.55, 0.7, 0.85 and 1 (headless check).
3. **Import and re-capture.** Import twice headless, then re-capture with render.sh: s1, s4 (mid-slide), s5, s6, s7 and O-720 against main.

## Budgets (from the files; to be confirmed in game)

- **Draw calls:** s1, s5 and s7 unchanged. The leaf is hidden there, and the wall and column are the same sprites. While sliding, one more item of the same atlas sits between `CorridorDoorOpen` and `SealLeaf`, and should batch.
- **Additive items:** none added.
- **Texture memory:** +0 MB. The atlas is the same 1024x1024 image. Free space is left for others (`placement.json`).
- **Rule 5:** every change is right of world x 700, so the cage and the opening are unaffected.

## Open issues

- **Not seen in the game:** no render.sh capture yet, no review pass, and Nathanial has not seen it. The previews are Python composites of the layer files.
- **Speed:** the leaf slides 3.65 m in about 0.6 s, inside the existing 1 s opening. A real blast leaf this heavy takes tens of seconds. This is the same game-time compression the roller already has, and the brief forbids new timing.
- **Light during the slide:** the leaf's painted detail moves with it, while its light is per vertex (correct). The parked edge in the wall and the moving edge meet only at o = 1, when the mesh hides.
- **Sign placement:** the sign is over the door, not beside it (see (b)). If Nathanial wants real Army colours, the stencil can be red 31136 on the white plate, which would add a red element.
- **Second yellow element:** the parked edge's stripes are a second yellow element in the open view, the first being the roller's bar and the floor line. Both are the same caught-between marking, toned to luma about 39.
- **Far jamb armour is subtle:** on screen it shows 5-6 world px left of the far guide. The head band carries most of the "blast frame" read.
- **Strap:** 1-2 px at 1x, as the round-6 review expected.

## Sources

- [D1] UFGS 08 39 54, Blast Resistant Doors. It covers frames, anchors and subframes that carry blast and rebound reactions into the structure; 100 and 200 mm reinforced-concrete doors with faceplates and spall plates; and rubber perimeter gasket seals. https://legacy.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2054.pdf (text in `research/`)
- [D2] Minuteman launcher closure door: 110 tons, 3.5 ft reinforced concrete and steel, slides on a cogged steel track, held shut by a large steel pin. https://www.minutemanmissile.com/launcherclosuredoor.html
- [D3] US4407043A, undercarriages for very heavy sliding doors of bombproof hangars: about 90 t per half, flanged track wheels on rails set in concrete. https://patents.google.com/patent/US4407043A/show.php
- [D4] Sliding blast doors for defence facilities (single or double leaf, heavy-duty tracks, secure locking). https://www.internationalsecurityexpo.com/exhibitor-products/sliding-blast-door
- [D5] Titan II blast doors interlocked in pairs (REAL-LOOK [M2]). https://npgallery.nps.gov/NRHP/GetAsset/NHLS/92001234_text
- [S1] NPS, HM-69 "Security Down Range": a white Army restricted-area warning sign with black and red lettering. https://www.nps.gov/places/hm-69-security-down-range.htm
- [S2] DoD 5200.08-R, as cited by the DISA Traditional Security checklist: restricted-area signs posted at all access points, and in English. https://www.stigviewer.com/stigs/traditional_security_checklist/2026-06-17/finding/V-245866
- [S3] OSHA 29 CFR 1910.145 (sign colours; wording "easily read and concise"). https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.145
- [S4] ANSI Z535.2 legibility rule of thumb, 1 in of letter height per 25 ft (favourable conditions). https://www.accuform.com/files/damobject/File/White_Paper_Sign_Visibility.pdf
- [S5] USACE security sign guidance (18 in minimum sign width; AR 190-13 posting). https://corpslakes.erdc.dren.mil/employees/sign/security.cfm
- [M9] OSHA 29 CFR 1910.144 (yellow for caught-between). https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.144
- Font: Roboto, SIL Open Font License 1.1, bundled with the game (`apps/game/assets/fonts/Roboto-OFL.txt`).
