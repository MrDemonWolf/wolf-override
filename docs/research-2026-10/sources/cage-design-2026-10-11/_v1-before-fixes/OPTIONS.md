# WOLF's containment: the three options, judged

Private scratch, 2026-10-11. This is an independent review of the three proposals in `option-a/`, `option-b/` and `option-c/`, written for Nathanial to pick from. It answers "Make sure the wolf cagte design makes sense" and "Can we add some pin codes and make it feel more like a furttgrue milialry base like iin skynet". The Terminator films are a mood reference only, and none of the options borrows anything from them.

**Nothing changes in the game until Nathanial picks.** Today's cage stays exactly as it is on main ("the cage for the wolf should been the same 100% the same before"). No Git repository or worktree was touched.

**The pick sheet** is `sheet.png`. Each option gets one row with three beats from main's real opening, cropped to the unit, plus its own front elevation. The recommended row is marked.

**What this judgement rests on:**
- every option's DESIGN.md, strip, construction drawing, beat renders and raw capture logs;
- the audit, the research, REAL-LOOK.md (including §8, Military base), the approved opening lines and the private context files;
- my own side-by-side of the same beats in all four runs (main, A, B, C): `judge/compare.png`, `judge/standby_1to1.png` and a greyscale copy;
- a contrast measurement that uses WOLF's sprite alpha as the mask (`judge/contrast.py`);
- the gate-opening values and render counters read from each run's `_log.json`.

These are still frames, code and measurements only. Nobody played anything by hand, listened to sound, exported a build or tested on a phone.

## Ranking

| Rank | Option | Score | Verdict in one line |
|---|---|---|---|
| **1** | **C: standby dock in a guarded bay** | **7.5 / 10** | The most real idea: a combat robot is held by its power state first and by steel second. It also has the best match to the room and the cheapest measured cost. Its big flaw is that WOLF is hard to see in standby, which can be fixed. |
| 2 | B: sealed armoured cell | 6.5 / 10 | The best read on a phone, and every approved line becomes literal. But a blue-lit glass box is the stock sci-fi "pod" image, the glass has highlights with no light source, and the biggest panels are the weakest material. |
| 3 | A: secure barred cage | 5.5 / 10 | Mechanically sound and closest to today's look. But the latch failure is invisible (the gate is half open 4 frames after the tap), standby hardware can't be seen, it needs two approved lines changed, it still reads as a kennel, and its phone cost is unmeasured. |

Scores by criterion. The overall score is my judgement and sits close to the mean.

| Criterion | A | B | C |
|---|---|---|---|
| Engineering: could be built, holds him, fails from inside, anchored, powered | 7 | 6 | 8 |
| First-time player read at 1280x720 and on a phone | 5 | 8 | 6 |
| Story and approved lines | 5 | 8 | 7 |
| REAL-LOOK (not AI-looking, nothing floats, values) and phone cost | 5 | 4 | 8 |
| Feels like a near-future military base run by machines | 5 | 6 | 8 |
| Hard constraints from the audit | 8 | 8 | 9 |

## Recommendation: C, taking two things from B and two from A

**From C, keep everything** at its own sizes:
- the belly cradle, the umbilical on a spring reel, and the dock lamp (amber for standby, then blue for awake with motors still locked out, then off);
- plate back, ends and roof, with four telescoping mesh leaves on top tracks;
- the fail-secure guard lock that tears off its mount and **stays hanging by its cable**;
- the status lamp, which stays green until the breach and then flashes red;
- the 0.15 s break hold followed by the 0.5 s slide (0.65 s in total, so WOLF's timing is unchanged);
- the node plan: one new `IntroBay` node at z 1, with the existing z values and the single `opening` drive kept.

**Take from B:**
1. **The lock pilaster.** This is a 0.30 m steel column at the latch end that carries the guard lock, the keypad backplate at 1.2 m (y 392), the status lamp, and a conduit run into a floor box. Today, C's keypad station and camera hang on a 50 mm conduit pole beside the post. Research [15] says a keypad must be "securely fastened to a wall or other fixed structure", and REAL-LOOK §8 says every device sits on a backplate or bracket.
2. **B's phone-size check** (`option-b/render/phone-check.png`, 534x300). Redo it for C, and add a check in motion for shimmer on the 3 px mesh.

**Take from A:**
1. **A lighter backdrop behind WOLF in standby.** A's light lining gives the clearest dark silhouette of the three. In C, paint the back plate behind him as lit by a fitting you can see in the bay roof. That keeps one light logic and adds no new glow.
2. **A's hook bolt.** A hook bolt resists both sliding and prying, so an outward shove loads it. An outward shove is the only push WOLF's side-view sprite can show. Make C's guard-lock bolt a hook bolt, so his forward drive is what tears the module off.

**From A and B together (Nathanial's call, because it changes beat 3's staging):** walk WOLF about 20 px right inside the unit, to the latch edge, before the break. Both A and B proposed this to stop his rear end popping through the parked leaf. It also fixes the problem the three options share below: it makes him the visible cause of the slide.

## Each option: where it does not make sense

### C: standby dock in a guarded bay (rank 1)

**Engineering.** This is the strongest case for why the unit holds him and why it fails:
- A guard lock is rated at about 2,000 N (the Euchner MGB [35]). C estimates WOLF's shove at 1.7-3.4 kN. Motor lockout is the primary hold, and once he wakes himself the steel is under-rated for him.
- The unit is fail-secure, its wiring is on the outside, it is anchored with plates and bolts, and it has a contact shadow.

Problems:
- The keypad and camera are mounted on a 50 mm conduit pole, not on a structure.
- The 1.22 m clear depth means he leaves by sidestepping 0.8 m. That works for a robot that can strafe, but it is unusual, and the side view only shows his 8 px step down.
- The "conductive gasket / RF shield" reasoning for "seal" is invented. The 1 px gasket can't be seen, and an RF shield hints at a story fact (why would he be shielded?). With a mesh front, "containment seal" holds only loosely, as it does in A.

**First-time player.**
- Beats 2 and 3 read well:
  - a blue light appears inside the unit;
  - sparks fly at the lock, the lock drops and hangs, the lamp turns red, and 3 m of leaves slide aside;
  - after that, the empty cradle and the wound-up cable say "he was plugged in".
- **Beats 0-1 fail the audit's "the dark WOLF clearly inside it" frame.** Measured contrast between WOLF and what is right around him (`judge/contrast.py`): **C 1.14**, against main 1.28, A 1.24 and B 1.31. At 1:1 he is a faint shape behind the mesh.
- The amber dock lamp reads as a dot floating in the cage, because the 2 px cable and connector disappear against the dark back plate.
- The cradle reads as a lectern or pedestal.
- In the 0.2 s frame the sparks spray across the Director's coat.
- C produced no phone-size image, only calculations.

**Story and lines.**
- "Wakes himself" becomes WOLF overriding his own motor lockout. "Under his own power" becomes literal: he is on battery once the umbilical lets go. Both are the best fit of the three for an independent machine treated as equipment.
- No line needs changing, but "seal" is loose (see Engineering).

**REAL-LOOK and cost.**
- C's values sit closest to the painted room: nothing looks pasted on, and the greyscale is quiet.
- The stencils are 6.4 px, under the 8 px minimum in §8.
- C's beat images have caption bands printed over the game's top card and PAUSE button. The sheet uses C's clean raw captures instead.
- Measured cost: **47 draw calls at beat 1, against main's 71** (and 40-43 in the later beats). It uses 2 persistent glows, within the budget of 4. Desktop only.

**Hard constraints.** All are kept: footprint x 23-213 and y 330-445, floor y 440, camera, WOLF's start, exit and timing, the Director's spot, and the `opening` drive. It is the smallest change to the scene: one node, with no z swap. Problem 20 is unchanged.

### B: sealed armoured cell (rank 2)

**Engineering.**
- The good parts:
  - the lock pilaster is right: fail-secure bolt, manual back-up key, keypad on a backplate, conduit into a floor box;
  - the inflatable seal is real hardware [42-44];
  - the cell is anchored.
- Two very large ballistic glass panes (1.6 x 1.5 m each) put the weakest material over the largest area of a cell built for a combat robot. A real secure cell has small vision panels. B chose big panes for readability, but an engineer would break the glass, not the keeper.
- The keeper tears out of a sliding leaf, but nothing says which way he pushes.

**First-time player.**
- B reads best on a phone (`phone-check.png`).
- Beat 2 is the strongest wake of the three: the whole cell turns blue and the stack light goes amber.
- B's sine easing holds the leaf near shut (opening 0.15 at 0.13 s, which B's drawing maps to a 2 px move) while the sparks and red lamps show the break.
- But **amber at beat 2 warns the Director** before the line says he "freezes at the sound of the seal opening" (B flags this itself).
- WOLF is less crisp behind glass, and his legs are hidden by the kick plate.

**Story and lines.** Every approved line is literal, including "containment seal" and "the sound of the seal opening". Only B gets "seal" right.

**REAL-LOOK and cost.**
- The diagonal glare streaks on the glass are highlights with no light source behind them (checklist 2). They read as clip-art glass.
- The whole-cell blue flood is far brighter than WOLF's small body lights could make. Behind glass it reads as a sci-fi tank or stasis pod. REAL-LOOK §8 rules out generic sci-fi glow, and REAL-LOOK §1 records "no pod" after the round 3 hatch. This is the "AI sloop" risk Nathanial named.
- After the breach there are three red elements in view: the stack light, the lock lamp and the room beacon. §8 allows one.
- The `KEEP CLEAR` stencil is 6.4 px.
- Cost: baked to textures, **38-42 draw calls (main 67-71)**, with 1 glow. Measured, desktop only.

**Hard constraints.** All are kept. It needs a z swap between `IntroCage` and `IntroGate`, a new back node, and a different easing curve with the same 0.65 s duration.

### A: secure barred cage (rank 3)

**Engineering.** A is sound:
- plate back, ends and roof;
- 75 mm bar gaps instead of today's 300 mm, which counts as whole-body access;
- one leaf on trolleys that parks over the fixed bay, so no bars overlap and nothing shrinks;
- a fail-secure hook bolt whose keeper tears off when he drives his shoulder into it (the best force path of the three);
- anchors.

The keypad hangs on the conduit pole, the same flaw as C.

**First-time player.**
- **The latch failure can't be seen.** A keeps main's cubic ease-out. In A's own log the gate is **50% open 4 frames (0.07 s) after the tap**, still under main's 0.09 s white flash. A proposed a hold but did not render it.
- **Standby has no visible hardware.** The dock lamp is dark, and the 2 px cable can't be seen at game size.
- WOLF's silhouette in standby is the clearest of the three, because the lining behind him is light.
- It still reads as a large dog kennel: the first thing the audit's first-time player asked.

**Story and lines.** A barred cage has no seal, so A asks for **two approved lines to be reworded** ("seal" to "unit" and to "gate"). Otherwise those lines are only loosely true. Nathanial signed off all 123 lines.

**REAL-LOOK and cost.**
- The unit is the brightest large mass in the frame. It is pale and flat, and it competes with the actors (see the greyscale copy).
- Its red lock lamp means "locked", but §8 keeps red for danger only.
- The stencils have a 0.15 m (about 6 px) cap height, under the 8 px minimum.
- **No render counters were recorded.** About 290 code-drawn primitives were counted; the baked cost is only estimated.

**Hard constraints.** All are kept. It needs a z swap and two child layers.

## Problems all three share

1. **Nothing on screen moves the leaf after the lock fails.** WOLF stands still while the leaf slides by itself. The fix is the staging change in the recommendation, with WOLF at the latch edge so his drive starts the slide, or a short push from him at the start of the slide.
2. **His rear end crosses in front of the parked leaf** when he steps out. This is clear in A and B, whose openings are 2.0 m against his 2.9 m length. It is small in C, whose opening is 3.0 m (about 18 px of tail).
3. **The sign text breaks two REAL-LOOK rules.** Checklist 7 says no text in art, and every mark is under §8's 8 px minimum except B's `CU-01`. Each mark needs 8 px caps or a blank plate, plus Nathanial's yes.
4. **REAL-LOOK §8 says "No new keypads or card readers until Nathanial picks the PIN design."** All three put a keypad on the lock, as hardware only, with no code entered. That is allowed by this job's brief but conflicts with the written art rule, so Nathanial decides. Every keypad sits at 1.2 m (y 392), as §8 asks. Keypad digits can't be read at game zoom in any option, so PIN gameplay will need a close-up or on-screen UI.
5. **Unchanged from main and still Nathanial's call:**
   - the unit vanishes at the fade;
   - WOLF ends 2 px from the Director's coat at beat 3;
   - at beat 6 he walks left with no exit (problem 20).
6. **All three are flat vector renders.** How real they finally look depends on the REAL-LOOK paint pipeline. This judgement is about construction, staging and values, not finish.

## Must fix before Nathanial sees them

**On the sheet (done):** clean frames with no caption bands over the game UI; every image labelled as a design drawing, not final art; sign text and keypads labelled as proposals.

**C (recommended):**
1. Raise WOLF's standby contrast to at least main's level (at least 1.28 by `judge/contrast.py`), using light from a fitting you can see in the bay roof. Re-check at 534x300.
2. Make the umbilical and connector readable (cable at least 3 px and lighter than the back plate), so the dock lamp is attached to something.
3. Make the cradle read as a robot stand: a base plate with anchors, a contact pad on the saddle, and conduit to the cabinet.
4. Move the keypad station and camera onto a lock pilaster fixed to the latch post (from B).
5. Make the guard-lock bolt a hook bolt (from A).
6. Narrow the spark spray so it stays off the Director's coat.
7. Stencils at 8 px caps (with a 14 px beam) or blank plates. Drop the RF-shield reasoning, and say plainly that "seal" is loose with a mesh front.
8. Re-caption the beat images below the frame, and add a 534x300 phone check.

**B (if he leans to B):**
1. Remove the glare streaks.
2. Keep the stack light green until the breach.
3. Pull the blue back to a pool around WOLF's body lights instead of a whole-cell flood.
4. Drop the 6.4 px `KEEP CLEAR`.
5. Limit red to one element per view.

**A (if he leans to A):**
1. Render a 0.1-0.15 s break hold, so the latch failure can be seen.
2. Show standby with an amber dock lamp and a visible cable.
3. Bring the unit's values down to the room's plan, while keeping a lighter backdrop behind WOLF.
4. Use green for locked, not red.
5. Mount the keypad on a backplate.
6. Measure the baked draw calls.
7. Put the two "seal" wording changes to him as a question, not as part of the design.

## Decisions only Nathanial can make

- Which option, or the C-plus-parts combination above. Until then, today's cage stays.
- The beat-3 staging change: WOLF walks to the latch edge before the break. It changes his timing.
- Whether "containment seal" may stay as a loose phrase (A and C) or must be literal (B).
- Sign text: `CU-01`, `KEEP CLEAR` and A's `KEEP CLEAR 2 M`, as an exception to checklist 7, or blank plates.
- A keypad now as lock hardware, or a blank 1.2 m backplate until the PIN design is picked.
- Whether the broken unit stays in the room after the fade (the purge display and both spawn points sit in its footprint), and problem 20.

## Files

- `sheet.png`: the pick sheet (2520 x 1891).
- `judge/sheet.py`: builds the sheet from the options' own captures and drawings. Nothing in it is generated.
- `judge/compare.png`: the same six beats in main, A, B and C, side by side.
- `judge/standby_1to1.png` and `judge/standby_1to1_grey.png`: beat 1 at 1:1, in colour and in greyscale.
- `judge/contrast.py`: WOLF's standby contrast, measured with his sprite alpha as the mask.
- Each option's full material is in `option-a/`, `option-b/` and `option-c/` (DESIGN.md, strip.png, the construction drawing, renders, and `shots/*/_log.json`).
