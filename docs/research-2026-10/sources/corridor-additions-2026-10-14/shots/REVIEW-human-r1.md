# Round 7 additions: first-time player look (human review r1)

2026-10-13. I looked at the additions frames as a first-time player would. I started with the full 1280x720 frames (`raw7/add/A-720`, `B-720`) and the 2400x1080 phone frames (`pairs/phone/add-*`). Then I looked at the three-way pairs and the 3x crops, and made my own 2x-4x crops of the same captures (kept outside `real-slice/`, in `scratchpad/review-human-r1-work/`). These are rendered stills only. I did not play the game, so I can say nothing about motion, timing or feel. I edited nothing except this file.

**Verdict: fix-needed.** The door end now reads as a real, guarded door, and none of the additions floats or blocks the route. One addition still breaks the scene: the engineer visibly turns into a different drawing while cranking.

## What I think this place is

It is a dark, wet service corridor deep inside a locked-down facility. Two things tell me this: the objective panel says MAINTENANCE / LOCKDOWN, and the red lamps are on. The corridor ends in a thick concrete bulkhead marked SECTOR 4B and RESTRICTED AREA. Set into it is a roller shutter, DOOR 4B-07, with a small red status lamp beside it. My robot wolf powers the coolant relay, I crank a manual bypass wheel on the wall, the shutter rolls up, and a second, heavier door slides aside behind it. The status lamp goes amber, then green, and I walk through to the safe point.

## What I would try next, and whether the picture tells me

- **Shut (s1, s2):** the MANUAL BYPASS wheel is the obvious thing to touch. It sits on the wall right next to the door and has a rod running up toward the door head, so I can see why turning it would open the door. Fine.
- **Open (s5, s6):** the green lamp, the clear doorway and the green SAFE POINT pillar tell me where to go. Fine.

## Points

### Must-fix

1. **The engineer changes into someone else while cranking (f).** This is the worst point in the slice.
   - **What changes:** when cranking starts, the figure goes from the broad 3/4 engineer with near-black trousers to a thinner, side-on figure with grey, lit trousers and a different face and hair. When the crank stops, they change back.
   - **Where it shows:** I can see it at 1x on the laptop frame and in phone shape (my crops `eng-compare.png` and `phone-eng.png`). It is not just visible at 3x.
   - **Why it matters:** this happens exactly where the player is looking, while they hold E for several seconds.
   - **Fix:** either draw the crank pose from the same sprite the rest of the game uses, or land it together with the matching idle, walk and jog frames, as the builder already suggests. Until then I would keep round 6's standing pose rather than ship the switch.

### Should-fix

2. **The pose itself is acceptable, but only just (f).**
   - The near glove does land on the wheel's rim, and the arm reaches out to it. At 2x it reads as "working the wheel".
   - The far glove rests above the wheel on the gearbox. At 1x it reads as a raised hand, not as a brace.
   - The body stays upright, with no lean or weight behind the push, so it looks like touching the wheel rather than heaving on a stiff valve.
   - Judge this again in motion once point 1 is fixed.
3. **The inner blast door does not look heavier than the roller door (c).**
   - **What works:** it is easy to follow. A second door is behind the shutter, slides sideways into the wall, and leaves only its striped edge in the opening. It never blocks the way once open. Nothing about it is "weird" or missing.
   - **What does not:** the leaf is a flat, almost black slab with one seam. It shows no visible thickness, no edge seal, no rollers or track, and no bolts. Only the yellow-black edge reads, so it looks like a dark partition panel, not a blast door. (See `crops/c-inner-leaf-s4b-3x.png`.)
   - **Fix:** a lit top or end face to show its thickness, a visible bottom track or guide rollers, and a few plate seams with bolts. Lift the front face slightly above the shadow of the opening.
4. **The steel blast frame is invisible (a).**
   - At 1x, and even in my 4x crop, the "armour head plates" are only a faint row of bolt dots and a slightly different patch of concrete. Nobody playing would see a heavy steel frame.
   - The plates also cover the lower edge of the small wall lamp above the door, and that lamp's tube is now clearly dimmer than in round 6 (`lamp-compare.png`). It looks half off, yet it still lights the wall the same.
   - **Fix:** give the frame real steel: a lighter, cooler face, a lit edge, and plates that read as separate from the concrete. Keep the lamp's tube as bright as in round 6, and keep the plates clear of it.
5. **The red lockdown beacons look real but are too small and faint to read as an alarm (d).**
   - **Close up (crops):** each is a proper caged lamp. The left one hangs on a conduit from the ceiling, and the right one hangs under its back box below the strip light. Both are fixed by visible hardware, so nothing hovers.
   - **At 1x:** they are a few red pixels high on a dark wall. In phone shape I had to look for them.
   - **Why it matters:** the text says "the alarm keeps wailing", but the room does not look like it is in lockdown.
   - **Fix:** a slightly larger lens, plus a stronger red pool on the wall and the pipes below it, painted into the art (a pulse can stay live).
   - Not judged: I cannot tell from stills whether they flash.
6. **The coolant is barely there (g).**
   - **What works:** the glowing pale disc is gone, which is right. The relief valve on the relay's side pipe, with a goose-neck tailpipe pointing down, looks like a real fitting.
   - **What does not:** the jet is a faint, thin vertical line. At 1x it is close to invisible, and in phone shape it could be taken for a hanging wire or a drip.
   - **Fix:** a short, slightly wider, brighter spray right at the tailpipe mouth that fades within about 20-30 px. A few drops on the floor below would help.
   - Not judged: whether it moves, since I saw only stills.
7. **Inherited: the safe point stands beside the door, not behind it.**
   - **What a player sees:** in every frame and both shapes, the green SAFE POINT pillar sits in an open, lit room to the right of the concrete bulkhead. A step edge runs from the bulkhead's corner toward the camera, so that room's floor looks reachable from the corridor floor, around the corner (`phone-end-3way.png`).
   - **Why it matters:** a person will ask "why open the door at all, why not walk round it?" This is the one "door that makes no sense" question I had. Round 6 already drew it this way, and main had the same layout, so it is not an addition.
   - **Fix:** close the gap between the bulkhead's corner and the right-hand room. A low wall, a railing, or the near column running down to the floor across the step would show that the only way in is through DOOR 4B-07.

### Fine

8. **RESTRICTED AREA sign (b):**
   - It is crisp, legible, correctly spelled, and stencil-like, on a bolted plate above the door.
   - It sits over the door rather than beside it. That reads naturally, since signs are hung over doors all the time.
   - It is black on grey, which is fine. Red lettering would add urgency but is not needed.
   - SECTOR 4B and DOOR 4B-07 (e) still read well.
9. **Guarded military feel:** the bulkhead, the sector and door marks, the restricted sign, the wall camera and the caged red lamps together read as a guarded government or military plant. Points 4 and 5 are what is missing for it to feel like a blast-rated door.
10. **Opening sequence (s4 to s5):** the shutter rolls up into its hood, and the leaf slides into a pocket on the left side of the opening, behind the jamb.
    - The leaf stands on the floor, and its parked striped edge stays in the pocket's mouth, out of the way.
    - The floor rail across the threshold makes sense.
    - Once it is open, the doorway is clearly walkable.
    - A small wedge of the roller's striped bottom bar shows under the head at top right. It reads as the shutter's bottom bar and does no harm.
11. **Strap (h) and lamp conduit:** invisible at 1x, and right when looked for. No complaints.
12. **Hovering objects:** none in the additions. I checked the two beacons, the sign, the valve and the leaf, and each one is held by a conduit, a box, bolts, a pipe or the floor.
13. **Eye pull:** nothing in the additions pulls the eye from the engineer, WOLF or the wheel. The brightest things at the door end are still the UI labels and the green safe-point lamp, which is correct. The three hazard stripes in the opening states (roller bar, leaf edge, floor) are busy but realistic.
14. **Inherited, fine:**
    - The near column overlaps WOLF in s7. It is a believable foreground pillar.
    - The COOLANT FAULT label stays up after the relay is fixed. This is a UI wording question, not art.

## Summary for Nathanial

The door end now makes sense as a real place:
- It is a restricted door in a bulkhead, opened by a wheel next to it.
- There is a second door behind the shutter, and you can see where it goes.
- Nothing floats or blocks the way.

Before this lands:
- **Must:** the engineer must not change drawing style while cranking (point 1).
- **Should:** the blast frame and the inner door need visible steel and thickness to look heavy (points 3 and 4). The red lamps and the coolant spray should be easier to see (points 5 and 6).
- **Inherited:** the safe point standing beside the door rather than behind it (point 7) is the one thing likely to make a player ask why the door is there.
