# Round 9 additions: first-time player look (human review r3)

2026-10-13. I looked at round 9 the way someone playing for the first time would. I went in this order:
- the full 1280x720 frames with the HUD (`raw9/add/A-720`, `B-720`);
- the same frames without the HUD (`*-clean.png`);
- the 1920x1080 phone frames (`raw9/add/A-phone`);
- the package crops in `crops/`;
- my own 2x-5x crops of the same captures, in `scratchpad/human-r3-work/` (outside `real-slice/`).

These are rendered stills only. I did not play the game, so I can say nothing about motion, the beacon pulse, timing or feel. I edited nothing except this file.

**Verdict: fix-needed.** Every round-9 addition makes physical sense:
- both doors move to places you can see;
- nothing hovers;
- the crank pose reads as work;
- the coolant has a source.

One thing at the door end still reads wrong to a person: the knee-high wall in front of the safe-point room. At 1x it looks almost the same as round 8's step, so the question "why crank a blast door when I could step over that?" is still there. Everything else is should-fix or fine.

## What I think this place is

A wet, dark service corridor in a facility under lockdown. The objective says MAINTENANCE / LOCKDOWN, and two red caged lamps glow on the back wall. At the end is a concrete bulkhead marked SECTOR 4B and RESTRICTED AREA, with a camera, a riveted steel header and a roller shutter labelled DOOR 4B-07. It reads as a guarded government or military plant, not an office.

Here is what happens:
1. The robot wolf powers the coolant relay through the breaker.
2. I crank the MANUAL BYPASS wheel on the wall beside the door. While I crank, coolant spits out of a drain pipe on the relay.
3. The shutter rolls up into its hood, and a heavier striped steel leaf behind it slides sideways into the wall.
4. The lamp on the pillar goes from red to amber to green.
5. I walk through the door, behind the pillar, to the green SAFE POINT machine in the next room.

## What I would try next, and whether the picture tells me

- **Shut (s1-s3):** the wheel is the obvious thing to use. It sits right next to the shutter, a rod runs from it up toward the door head, and the red lamp says "locked". The picture tells me. Fine.
- **Opening (s4, s4b):** I can see the shutter going up and a second, thicker door sliding left behind it. It says "this takes two doors to open". Fine.
- **Open (s5-s7):** the green lamp, the clear doorway and the green SAFE POINT beacon tell me where to go. Fine.

## Points

### Must-fix

1. **The safe-point room is still closed off only by a knee-high wall (round 9's fix, changed only a little at 1x).**
   - **What I see:** in every state and in both shapes, a concrete band runs from the foot of the near pillar down to the bottom-right corner of the screen. It has steel edges and the wet corridor floor in front of it, and the lit safe-point room sits just behind it. Crops: `human-r3-work/s7-safe-point-clean-foot-3x.png`, `s6-2x.png`, and the package's `m1-cut-section-s7-2x.png`.
   - **How I read it:** as the raised lip of a platform, or a kerb. It is lower than the engineer's knee. Rounds 6 and 8 had a lighter sloped band in the same place, and at normal size round 9 looks much the same, just darker and with a crisper edge.
   - **The problem:** a tall pillar, a blast frame, a camera, a RESTRICTED AREA sign and a two-leaf door, and right beside them a wall I could step over. A thinking person asks why anyone would crank the door. In real sites a security line never drops to knee height next to its own blast door. Nathanial asked for no "missing weird doors" and to "think as a human", so I can't pass it.
   - **Fixes that keep the engineer's boots visible:**
     - A steel security fence (welded mesh or expanded metal, about 2 m tall, on posts bolted to the top of the low wall). Mesh is see-through, so the engineer and the SAFE POINT machine stay readable, and it suits a RESTRICTED AREA.
     - A plain two-rail guard rail on posts on top of the wall. Weaker: people climb rails, but they still read as "not this way".
     - Main had a foreground pipe rail in front of the safe point (`m1-cut-section-s7-2x.png`, first panel). Something like that, standing on the low wall, would also work.
     - A taller wall that hides the boots would be physically right but costs the read of the engineer at the save.

### Should-fix

2. **WOLF is left behind while his line says "We made it" (unchanged; needs Nathanial).** In s7 the engineer is at the safe point and WOLF stands about 600 px away on the far side of the relay, facing away from the door. A first-time player reads that as leaving the companion behind. Either let WOLF stand at or in the open doorway, or change the line.
3. **Inherited: COOLANT FAULT stays up through "Safe point saved ... We made it."** It reads as "something is still broken". Main fixed this in PR #63, so it should go away on rebase. Check it after the port.
4. **The red beacons sell the alarm only a little at normal size.**
   - **Close up:** they are real caged lamps. The left one hangs on a feed from the ceiling; the right one hangs under a back box below the short ceiling fitting. Nothing hovers. The new red wash on the wall is visible at 3x.
   - **At 1x:** on the laptop frame and the phone frame they are a few red pixels with a faint red haze. The dialogue says "the alarm keeps wailing". They look like warning lights, not an alarm going off.
   - **Not judged:** the pulse. If it reads in motion, this drops to fine.
5. **Inherited, minor: the shutter's slats look almost level, while its hood and hazard bottom bar follow the face's slope** (`s1-door-3x.png`). Most players won't notice. If the shutter art is redrawn, tilt the slats with the bottom bar.

### Fine

6. **Crank pose (f):** frames A and B (`s3A-crank-4x.png`, `s3B-crank-4x.png`) show both gloves on the left of the rim, low in A and high in B. The engineer leans in and the legs stay planted. It reads as heaving a stiff wheel round. Side-on to a wheel that faces the camera is a normal 2D convention.
7. **Coolant (g):** a thin pipe in clamps runs down the relay's right side. A short, pale jet comes out of its open end and fans faintly on the floor (`s3-spray-5x.png`). It has a source, it is faint, and it is not a glowing disc. It reads as a leaking drain or vent spitting coolant. At 1x it is a thin pale streak, which is enough while the line says "the hiss gets louder".
8. **Inner blast door (c):**
   - In s4/s4b a thick grey leaf with a hazard-striped leading edge stands behind the rising shutter and slides left. In s5 only its striped edge shows in the left jamb.
   - I can tell where it goes and how it moves. It never blocks the opening, and it looks heavier than the shutter.
   - Nit, only if I think hard: the bulkhead face left of the door is narrow for a full-width pocket. No first-time player will work that out.
9. **Blast frame (a), RESTRICTED AREA sign (b), SECTOR 4B and DOOR 4B-07 (e):**
   - The riveted steel header, the hood, the camera on its arm and the bolted RESTRICTED AREA plate together say "guarded".
   - The text is legible and spelled right.
   - SECTOR 4B is level while the plate follows the slope, but that only shows at 2x (inherited).
10. **Doors in general:**
    - The shutter goes up into its hood, and the leaf slides into the wall.
    - Once open, the doorway is clear and walkable. In s6 the near pillar hides the engineer as they pass behind it, which is correct.
    - Through the open door there is a back room with a motor on a plinth on the floor, so it is a real space.
    - Apart from point 1, no door is unexplained.
11. **Hovering check:** nothing floats. Each of these hangs on, stands on or is fixed to something:
    - both beacons;
    - the short fitting over the bypass (two rods to the ceiling) and its moved wall pool and floor streak, now under it (`m2-luminaire-pool-s5-1x.png`);
    - the door light (bracket to the conduit);
    - the camera (arm and conduit);
    - the seal lamp (on the pillar, on its conduit);
    - the wheel (gearbox plate and rod);
    - the relief pipe (clamps);
    - the pendant lamp in the safe room (rod);
    - the SAFE POINT machine (on the floor).
12. **Seal lamp:** red when shut, amber when opening, green when open, on the pillar beside the door. It's clear.
13. **Eye-pull:** nothing at the door end pulls my eye from the action. The brightest things are the green SAFE POINT beacon, which is the goal, and the shutter's hazard stripes. The floor reflections are soft.
