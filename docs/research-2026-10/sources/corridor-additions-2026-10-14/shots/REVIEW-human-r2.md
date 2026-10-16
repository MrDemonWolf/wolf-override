# Round 8 additions: first-time player look (human review r2)

2026-10-13. I looked at the round-8 frames the way someone playing for the first time would see them:
- first the full 1280x720 frames with the HUD (`raw8/add/A-720`, `B-720`, `O-720`);
- then the 1920x1080 phone frames (`raw8/add/A-phone`, `B-phone`);
- then the pairs and crops in `crops/`;
- then my own 2x-4x crops of the same captures. They are in `scratchpad/human-r2-work/`, outside `real-slice/`.

These are rendered stills only. I did not play the game, so I can say nothing about motion, pulse, timing or feel. I edited nothing except this file.

**Verdict: fix-needed.** Every round-8 addition now makes sense to a person. Nothing floats, no door blocks the way, and the engineer stays the same drawing while cranking. One thing at the door end still makes the door look pointless, and it is inherited, not an addition: the safe point's room is open to the corridor round the near pillar. A normal player would ask "why not just walk round?" Nathanial asked for no "missing weird doors", so I can't pass the door end while that stays. I also mark WOLF staying behind as a should-fix.

## What I think this place is

A wet, dark service corridor in a locked-down facility. The objective says MAINTENANCE / LOCKDOWN, small red caged lamps hang on the wall, and the corridor ends at a concrete bulkhead marked SECTOR 4B and RESTRICTED AREA. It has a camera, a riveted steel band over a roller shutter, and a status lamp, so it reads as a guarded, military or government site.

Here is how it plays out. The robot wolf takes the surge at the coolant relay. I crank the MANUAL BYPASS wheel on the wall beside the door, and coolant spits from a pipe on the relay while I do. The shutter rolls up into its hood, and a heavy grey door behind it slides sideways into the wall. The lamp goes red, then amber, then green. I walk through to the SAFE POINT.

## What I would try next, and whether the picture tells me

- **Shut (s1-s3):** the wheel is the obvious thing to use. It sits right next to the shutter, and a rod runs from it up toward the door head, so turning it plausibly opens the door. The red lamp and the closed shutter say "locked". Fine.
- **Open (s5-s6):** the green lamp, the clear doorway with the parked striped edge, and the green SAFE POINT beacon tell me where to go. Fine.

## Points

### Must-fix

1. **Inherited: the safe point's room is open to the corridor round the near pillar, so the door looks unnecessary.**
   - **What I see:** in every state and in both shapes, the green SAFE POINT machine stands in a lit room to the right of the concrete pillar. The open door shows that this is the same room: its floor and a machine on a plinth carry on behind the pillar (`human-r2-work/s5-room-3x.png`).
   - **The problem:** the bulkhead is only a pillar on the camera side. The corridor floor runs under its foot and meets a low step that leads straight up into the safe-point room (`s1-kerb-4x.png`). As a person I'd think "I can step round that column", and the whole crank-and-open sequence starts to feel staged.
   - **History:** round 6 and main have the same layout, and review r1 raised it as point 7.
   - **My view:** this is the one thing left that a first-time player would find odd at the door end.
   - **Fix:** close the gap on the camera side. Options are the pillar or a wall running down to the floor across the step, a solid barrier or railing with a reason to be there, or a front wall lip. Any of them should show the room can only be reached through DOOR 4B-07. It needs new art.

### Should-fix

2. **WOLF stays behind and then says "We made it" (round-8 change, needs Nathanial's OK).**
   - **What happens:** once the seal opens, WOLF walks back to the breaker side of the relay (x about 440 on screen). He stays there while the engineer goes through the door (s5, s6) and while the safe point saves (s7).
   - **What a player reads:** s7 shows the engineer at the safe point, WOLF about 600 px away on the far side of the door, and WOLF's line "We made it." That reads as the companion being left behind.
   - **Comparison:** round 7 had WOLF half behind the pillar. That looked cramped but read as following.
   - **Suggestion:** if WOLF can't fit at the door end, have him at least stand near the open door (left of the wheel, facing it) rather than back at the breaker. Or change the line so it doesn't claim "we".
3. **The red lockdown beacons still don't sell a lockdown at normal size (d).**
   - **Close up:** they are real caged lamps. The left one hangs on a strapped feed and the right one under its back box. Nothing hovers.
   - **At 1x:** on the laptop frame and in phone shape they are a few red pixels high. The new red pool shows as a faint red smear, not a pool. The dialogue says "the alarm keeps wailing", but the room doesn't look alarmed. I had to look for them.
   - **Not judged:** whether the pulse helps in motion. If it does, this drops to fine. From stills, a slightly wider and stronger red wash on the wall and pipes would help.
4. **Inherited: the COOLANT FAULT tag stays up through the open door and the safe-point save.** Next to "We made it" it reads as "something is still broken". Another branch clears it.
5. **Inherited, minor: SECTOR 4B is set level, while RESTRICTED AREA and DOOR 4B-07 on the same face follow its slope.** At 1x it only reads as slightly "pasted on". At 2x it is clear.

### Fine

6. **Crank pose (f): fixed, and it is the same person now.**
   - At 1x on both screens, the engineer in the red jacket leans in with both gloves on the left of the wheel's rim, and the next frame shows them a notch further round.
   - It reads as working a stiff wheel, not touching it.
   - The legs and boots don't change, and the face and trousers match the walking sprite.
   - The engineer stands side-on to a wheel that faces the camera, which is a normal 2D convention.
7. **Coolant (g): reads as coolant now.**
   - A relief pipe runs down the side of the relay in clamps. A short, pale jet sprays from its open end onto the floor by the relay's foot.
   - It has a clear source, sits at floor level away from the engineer's head, and shows only while cranking.
   - At 1x it looks like a hissing leak of water or coolant, not a glowing disc and not a wire.
   - The damp patch under it is barely visible, which is fine.
8. **Inner blast door (c): it makes physical sense and reads heavier.**
   - In s4/s4b, a grey steel leaf with weld seams, a box at its foot and a striped, thick leading edge with bolt receivers stands behind the shutter. In s5 it has slid into the wall on the left of the opening, leaving only its striped edge in the pocket mouth.
   - I can tell where it goes and how it moves, and it never blocks the doorway.
   - It looks clearly heavier than the shutter.
   - Small nit, not worth a round: the "bogie" box at the foot reads more like a vent box than rollers.
9. **Blast frame (a): reads now.**
   - At 1x there is a lighter riveted steel band over the shutter hood, and the door light above it is bright again.
   - It reads as a steel plate header more than as a full frame round the opening. The far jamb is subtle.
   - Together with the hood, the camera and the signs, it is enough to feel guarded. Not a blocker.
10. **RESTRICTED AREA sign (b) and the marks SECTOR 4B / DOOR 4B-07 (e):**
    - The sign is legible, correctly spelled and bolted on, and it follows the wall's slope.
    - It is a bit cleaner than the grimy wall, like a newer plate, which is believable.
11. **Doors:**
    - The shutter goes up into its hood, and the inner leaf goes sideways into a wall pocket.
    - The doorway is clear and walkable once open, and the engineer is properly hidden by the pillar as they pass behind it (s6).
    - No door is missing or unexplained, apart from point 1's way round.
12. **Hovering check:**
    - Nothing hovers. These are all fixed to something: the two beacons (feed and straps or back box); the short ceiling fitting near PAUSE and the one at the top of the door-end frames (two rods to the ceiling); the door light (bracket off the conduit); the camera (arm and conduit); the seal lamp (on the pillar on its conduit); the wheel (gearbox plate and rod); the relief pipe (clamps); and the machine behind the door (on a plinth on the floor).
    - The rod from the wheel ends under the MANUAL BYPASS label, so the label looks like a sign on that rod. That reads fine.
13. **Light by PAUSE (opening o8):** a short fitting on two rods, clear of the button. It no longer runs under the HUD. Fine.
14. **Eye pull:**
    - The brightest things at the door end are the green SAFE POINT beacon, the seal lamp and the UI labels, which is right.
    - The coolant jet is small and sits where the action is.
    - Nothing new pulls the eye away from the engineer and the wheel. The three hazard stripes in the open states (shutter bar, leaf edge, floor) are busy but realistic.

## Summary for Nathanial

- **Additions:** all of them now pass a "would a person find this odd?" look in stills. The engineer really works the wheel with the same drawing, the coolant comes from a visible pipe, the second door is heavy and slides into the wall, and nothing floats.
- **Before the door end is right:**
  - The safe point needs to be closed off on the camera side so the door is the only way in. This is inherited and needs new art.
  - Decide whether WOLF should stay back by the breaker while saying "We made it".
- **Still small:** the red beacons are too small to feel like an alarm at normal size, unless the pulse sells it in play.
