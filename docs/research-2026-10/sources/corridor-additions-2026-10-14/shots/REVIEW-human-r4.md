# Round 10 additions: first-time player look (human review r4)

2026-10-14. I looked at round 10 the way someone playing for the first time would. I went in this order:
- the full 1280x720 frames with the HUD (`raw10/add/A-720`, `B-720`);
- the same frames without the HUD (`*-clean.png`);
- the 1920x1080 phone frames (`raw10/add/A-phone`, `B-phone`);
- the package crops in `crops/`;
- my own 2x-6x crops of the same captures, in `scratchpad/hr4-crops/` (outside `real-slice/`).

These are rendered stills only. I did not play the game, so I can say nothing about motion, the beacon pulse in motion, timing or feel. I edited nothing except this file.

Nathanial approved both of round 10's big changes on 2026-10-14: the clean cutaway and WOLF at the doorway. So I judged the cut wall as a cutaway, not as a wall.

**Verdict: pass.** I found nothing in the door end that a normal first-time player would stop on:
- every door has a place to go and moves there;
- nothing hovers;
- the engineer looks like they are turning the wheel;
- the coolant comes out of a pipe;
- the safe-point room's near wall now reads as a cutaway rather than a step-over kerb;
- WOLF is at the door when he says "We made it."

What is left are should-fix items, most of them inherited, plus one effect outside the door end (point 3) that a player would notice. That effect is identical on main.

## What I think this place is

A wet, dark service corridor in a facility under lockdown. The objective says MAINTENANCE / LOCKDOWN, and two red caged lamps hang on the back wall. The corridor ends at a concrete bulkhead with these on it:
- SECTOR 4B;
- a bolted RESTRICTED AREA plate;
- a camera on an arm;
- a riveted steel header over a roller shutter, labelled DOOR 4B-07;
- a red lamp on the pillar.

It reads as a guarded military or government plant.

Here is what happens:
1. The robot wolf powers the coolant relay through the breaker.
2. I crank the MANUAL BYPASS wheel on the wall beside the door, and coolant spits out of a drain pipe on the relay.
3. The shutter rolls up, and behind it a thicker striped steel leaf slides left into the wall.
4. The lamp goes red, then amber, then green.
5. I walk through to the green SAFE POINT machine in the next room. That room is shown cut open, the way This War of Mine or The Sims' "walls down" view shows a room.
6. WOLF follows to the doorway.

## What I would try next, and whether the picture tells me

- **Shut (s1-s3):** the wheel next to the shutter is the obvious thing to use. A shaft runs from its gearbox up toward the door head, and the red lamp says "locked". The picture tells me. Fine.
- **Opening (s4, s4b):** the shutter goes up into its hood, and a second, heavier door slides sideways behind it. It says "this takes two doors to open". Fine.
- **Open (s5-s7):** the green lamp, the clear opening and the green SAFE POINT beacon tell me where to go. In s7 the prompt "E: enter records access" points onward. Fine.

## Points

### Must-fix

None.

### Should-fix

1. **Inherited: COOLANT FAULT is still up at "Safe point saved ... We made it." (s7).** It reads as "something is still broken". Main fixed this in PR #63, so check it after the port.
2. **The red beacons are still small at normal size; I could not judge their pulse.**
   - **Close up:** they are real caged jelly-jar lamps. The left one hangs on a feed from the ceiling, the right one under a back box (`hr4-crops/beacons.png`). Nothing hovers.
   - **At 1x, on both the laptop and the phone frame:** each one is about a 10x20 px red spot with a red haze. The haze is a little stronger than in round 9.
   - **The 16-frame strip** (`crops/p-beacon-pulse-*-2x.png`) shows the wall wash swelling and fading over roughly 2.7 s, while the lamp itself stays lit. As a still sequence, that reads as a slow "breathing" glow, not an alarm going off. A real lockdown beacon rotates or strobes, about once a second.
   - **Judge in motion.** If the throb still reads as calm, speed it up or make it flash on and off, with no new art and no new additive items. This is not a must-fix: the dialogue ("the alarm keeps wailing") and the sound carry the alarm.
3. **Inherited, outside the door end: WOLF's surge effect at the relay in s2 looks stuck on.**
   - It is a soft pale-blue cloud with a thick, flat zigzag "M" drawn over WOLF's back (`hr4-crops/surge-both.png`; main on the left, round 10 on the right, identical).
   - It reads like a clip-art sticker, not current arcing from a contact.
   - It is the same "glowing disc with no source" problem that round 6 fixed for the coolant. It sits right where the action is, so a first-time player would notice it.
   - It is not part of this job (main draws it), so it doesn't block the door end. Suggested change: thin, bright, short-lived arcs from the relay's contact to WOLF's paw or shoulder, with no cloud.
4. **Inherited, minor: the RESTRICTED AREA plate is tilted to follow the door's slope, but SECTOR 4B above it and the conduit box beside it are level** (`hr4-crops/walllamp.png`). At 1x the plate looks slightly crooked on a level wall. Set the plate level, or set the whole face to one slope.
5. **Inherited, minor: the shutter's slats look almost level, while its hood and striped bottom bar follow the slope** (`hr4-crops/dz-s1-door-end-rest.png`). Most players won't notice.
6. **Minor: the steel blast frame (a) is quiet.** The riveted header plate reads, but the side jambs read as thin steel channels, not heavy armour plates. Together with the camera, the sign and the inner leaf, the end still says "guarded", so this is a nit, not a defect. If anything is strengthened, give the jambs a wider plate face with a visible bolt row, without adding draw calls.

### Fine

7. **Clean cutaway (decision 1):**
   - The safe room's near wall is now one flat, dark band (luma about 13). It runs from the pillar's foot toward the bottom right, with a clean top edge and no angles, ties or damp foot (`crops/c-cutaway-s7-2x.png`, `hr4-crops/cut-s1.png`).
   - At 1x it reads as the cut edge of a wall seen in a cutaway view. Its line follows the floor joints toward the camera, like the low wall stubs in The Sims. It no longer reads as a concrete kerb I could step over: there is no material to read, so there is no "build".
   - The engineer's boots and the SAFE POINT machine stay fully visible, and the floor marker draws above the band. In the phone shape the dialogue box covers most of it, which is fine.
   - Nit, not blocking: at 4x a faint lighter line along the band's upper face is still visible, so it is just barely two-tone. A truly single tone would be cleaner, but no player will see this at 1x.
8. **WOLF at the doorway (decision 2):**
   - In s7 he stands in the open doorway, at the threshold, facing the engineer, fully visible (`crops/w-wolf-doorway-s7-2x.png`; phone frame `A-phone/s7-safe-point.png`).
   - His head is inside the opening, he doesn't touch the jambs, and he doesn't overlap the engineer or the relay. He stands in front of the wall-mounted wheel, which is clearly on the back wall.
   - "We made it" now matches the picture. This closes my round-3 should-fix.
9. **Crank pose (f):** across A, B and the main crank frame (`hr4-crops/hands.png`), the gloves sit on the wheel's left rim, low, then high, then two-handed. The arms reach forward and the legs stay planted. On the phone frame the arm-to-rim contact is clear. It looks like someone heaving a stiff wheel round. Fine.
10. **Coolant (g):** a thin pipe in clamps runs down the relay's right side. A narrow, faint pale jet comes out of its open end and spreads a little on the floor (`crops/g-relief-spray-s3-3x.png`). It has a source, it points one way, and it is not a glowing disc. At 1x it is a thin pale streak, easy to miss but not wrong, and the hiss sound and the line "The hiss gets louder" carry it. It reads as coolant venting from a drain.
11. **Inner blast door (c):** in s4 a thick grey leaf with bolted bottom plates and a hazard-striped edge stands behind the rising shutter. It is clearly heavier than the shutter. In s4b it slides left behind the left jamb, and in s5-s7 only its striped edge shows, parked in the jamb. I can tell where it goes and how it moves, and it never blocks the opening. Through the opening there is a back room with a machine on a plinth on the floor, so it is a real space.
12. **Doors in general:**
    - The shutter goes up into its hood, and the leaf goes into the wall.
    - Once open, the doorway is clear and walkable. In s6 the near pillar hides the engineer's back edge as they pass behind it, which is correct.
    - The UI line from the MANUAL BYPASS tag down to the gearbox is a UI leader in the tag's colour, not a wire, so it reads as part of the tag.
    - No door is unexplained.
13. **Hovering check:** nothing floats. Each of these hangs on, stands on or is fixed to something:
    - both beacons (feeds and box);
    - the fitting over the bypass (two rods to the ceiling), with no dark box round it any more (`crops/m1-luminaire-box-r8-r9-r10-s5-4x.png`);
    - the light above the door (a bracket on its conduit);
    - the camera (an arm and conduit);
    - the seal lamp (on the pillar, on its conduit);
    - the wheel (gearbox plate and shaft);
    - the relief pipe (clamps);
    - the pendant lamp in the safe room (a rod);
    - the RESTRICTED AREA plate (four fixings);
    - the SAFE POINT machine, the relay and the breaker (on the floor).
14. **Military feel (a, b, d, e):**
    - Together, these say "restricted, guarded site": the RESTRICTED AREA plate (black stencil-style letters, legible, spelled right), SECTOR 4B, DOOR 4B-07, the camera, the caged red lamps, the hazard stripes and the two-leaf door.
    - The red-amber-green seal lamp on the pillar is clear.
15. **Eye-pull:** at the door end, nothing pulls my eye from the action. The brightest things there are the green SAFE POINT beacon (the goal), the seal lamp and the hazard stripes.
    - Inherited, left of the door end: the big ceiling light over the middle of the corridor is the brightest thing on screen, with streaky "dripping" light and a strong floor reflection. It is atmospheric, not wrong.
