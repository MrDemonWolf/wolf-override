# Round 11 additions: first-time player look (human review r5)

2026-10-14. I looked at round 11 as someone playing for the first time. I went in this order:
- the full 1280x720 frames with the HUD (`raw11/add/A-720`, `B-720`, `O-720`);
- the 1920x1080 phone frames (`raw11/add/A-phone`, `B-phone`);
- the package crops in `crops/` (jambs, beacon strips and curves, relief spray, cutaway, WOLF at the doorway);
- my own 2x-5x crops of the same captures, in `scratchpad/hr5-crops/` (outside `real-slice/`).

These are rendered stills only. I did not play the game, so I can say nothing about motion, the beacon flash in motion, timing or feel. I edited nothing except this file.

Nathanial approved the clean cutaway and WOLF at the doorway on 2026-10-14, so I judged the safe room's near edge as a cutaway, not as a wall.

**Verdict: pass.** A normal first-time player would find nothing odd in the door end:
- every door has a place to go, and you can see it go there;
- nothing hovers;
- the engineer's gloves are on the wheel;
- the coolant comes out of a pipe;
- the red lamps, the sign and the frame make it feel like a guarded site.

Round 11's two visible changes, the flashing beacons and the jamb plates, add nothing odd. What is left are should-fix items. Two of them are inherited and sit where the action is: WOLF's surge cloud, and COOLANT FAULT staying up at the safe point.

## What I think this place is, and what happens here

A wet, dark service tunnel in a plant under lockdown. The objective says MAINTENANCE / LOCKDOWN. The tunnel ends at a thick concrete bulkhead with these on it:
- SECTOR 4B;
- a bolted RESTRICTED AREA plate;
- a camera on an arm;
- a wall light;
- a riveted steel header over a roller shutter, labelled DOOR 4B-07;
- a red lamp and a push-button box on the near pillar.

Two caged red lamps on the tunnel wall say "alarm". The green SAFE POINT machine stands in the next room, which is shown cut open. That room is clearly on the far side of the bulkhead: the near pillar comes all the way down to the floor, so the only way in is through the door.

Here is what happens:
1. Flip the breaker.
2. Either WOLF takes the surge at the coolant relay, or I crank the MANUAL BYPASS wheel beside the door while coolant spits out of a pipe on the relay.
3. The shutter rolls up, and a heavier striped steel door behind it slides sideways into the wall.
4. The pillar lamp goes red, then amber, then green.
5. I walk through to the SAFE POINT, and WOLF comes to the doorway.

## What I would try next, and whether the picture tells me

- **Shut (s1-s3):** the wheel next to the shutter, the "MANUAL BYPASS" tag and the red pillar lamp point me straight at it. The picture tells me. Fine.
- **Opening (s4, s4b):** the shutter goes up into the header, and a second, thicker door is behind it. Then that door's striped edge moves left and the room appears. I can tell this door takes two steps to open. Fine.
- **Open (s5-s7):** the green lamp, the clear opening, the machine in the room beyond and the green SAFE POINT lamp say "go right". Then "E: enter records access" points onward. Fine.

## Points

### Must-fix

None.

### Should-fix

1. **Inherited, outside the door end, but right at the action: WOLF's surge at the relay (A route, s2) looks like a sticker.**
   - It is a soft pale-blue cloud with a thick zigzag drawn over WOLF's back (720p x 590-690, y 360-420).
   - On both laptop and phone it is the first thing I look at in that frame. It reads as clip art, not as current jumping from a contact.
   - It is unchanged from main and from round 10, and not part of this job. Same fix as before: thin, short-lived arcs from the relay's contact to WOLF, with no cloud.
2. **Inherited: COOLANT FAULT stays up at "Safe point saved ... We made it." (s7).** It says "something is still broken" just as the game says I succeeded. Main fixed this in PR #63, so check it after the port.
3. **The red beacons are still small at normal size, but now they flash like an alarm in the stills.**
   - **At 1x:** each is about a 10x20 px red lamp. In frames caught mid-flash, a red wash spreads over the wall around it (s5 right lamp; s1 left lamp).
   - **The 1/30 s strip** (`crops/p-beacon-pulse-right-2x.png`, `p-beacon-curves.png`):
     - the lamp and its wash now jump up together and fall back;
     - the globe itself goes dark between flashes;
     - the two lamps are out of step.
   - That reads like a rotating red beacon, not breathing, and it closes my round-4 point. Whether about 1.5 flashes a second feels urgent or nervous can only be judged in motion.
   - Close up, both lamps are properly hung:
     - the left one on a feed with couplings from the ceiling (`hr5-crops/beaconL-s1-5x.png`);
     - the right one under a back box on a conduit, beside the hanging fitting (`hr5-crops/beaconR-s1-5x.png`).
   - Not a must-fix. The alarm line and the sound carry it.

### Fine (with notes)

4. **New this round: the jamb plates.**
   - At 1x the side plates are subtle: a slightly lighter bolted band each side of the shutter (`crops/j-jambs-s1-2x.png`, `j-jambs-s5-2x.png`).
   - They make the frame read a bit more like heavy steel than round 10's thin channel, and they look fixed, not stuck on.
   - The near pillar's plate carries the lamp and push-button box naturally.
   - A player won't notice them as a change, and they don't look odd.
5. **Doors:**
   - **Shutter:** it goes up into the DOOR 4B-07 header and its striped bottom bar stays under the header.
   - **Inner blast door** (`hr5-crops/s4-leaf-4x.png`, `s4b-leaf-4x.png`):
     - in s4 it is a grey two-panel steel leaf with bottom plates and a striped edge;
     - in s4b its striped edge has moved left across the opening, with the next room showing to its right;
     - in s5-s7 only the striped edge shows, parked at the left side of the opening.
   - I can tell where each door goes and how it moves. Neither blocks the way when open.
   - Nit: in a single open-door still, the parked striped edge could read as a striped post at the side of the doorway. Having seen s4b, it reads as the door's edge in its pocket, which is how a real sliding blast door looks.
   - Nit: at 1x the inner leaf is half hidden behind the engineer in s4, so its weight mostly comes across in s4b.
6. **Hovering check:** nothing floats. Each of these is held up by something:
   - both beacons;
   - the fitting over the bypass (two rods);
   - the wall light under RESTRICTED AREA (on its conduit);
   - the camera (arm and conduit);
   - the RESTRICTED AREA plate (fixings);
   - the pillar lamp and push-button box;
   - the wheel (gearbox plate and shaft);
   - the relief pipe (clamps);
   - in the safe room, the tank (stands on the floor; `hr5-crops/saferoom-s1-3x.png`) and the back-wall railing (on a gallery ledge);
   - the SAFE POINT machine, relay and breaker (on the floor).
7. **Crank pose (f)** (`hr5-crops/crank-4x.png`, `crankA-4x.png`, `crankB-4x.png`, and the phone `B-phone/s3-crank-B.png`):
   - The gloves sit on the wheel's rim, at a different spot in each frame, low then high.
   - The arms reach forward and the legs stay planted.
   - It looks like someone hauling a stiff wheel round. The side-on facing is the normal 2D-game convention.
8. **Coolant (g)** (`crops/g-relief-spray-s3-3x.png`):
   - A thin pipe tees off the top of the relay and runs down its side in clamps.
   - A narrow, faint pale jet comes out of its open end and splashes on the floor.
   - It has a source and a direction, and it is not a glowing disc. At 1x it is easy to miss, but it is not wrong. With "The hiss gets louder", it reads as coolant venting.
9. **Military feel (a, b, d, e):** these together read as a restricted, guarded site:
   - the RESTRICTED AREA plate (spelled right, legible on laptop and phone);
   - SECTOR 4B and DOOR 4B-07;
   - the camera and the caged red lamps;
   - the hazard stripes and the two-leaf door;
   - the red-amber-green pillar lamp.
10. **Cutaway (decision 1)** (`crops/c-cutaway-s7-2x.png`):
    - The safe room's near edge is a solid dark band with a clean top, like a building cut open.
    - The engineer, the SAFE POINT machine and the floor marker stay fully visible above it.
    - In the phone shape the dialogue box covers most of it.
11. **WOLF at the doorway (decision 2)** (`hr5-crops/s7-wolf-3x.png`, phone `A-phone/s7-safe-point.png`):
    - He stands in the open doorway with his front paws at the threshold, facing the engineer, fully visible.
    - He is clear of the jambs, the machines and the engineer. "We made it" matches the picture.
12. **Eye-pull:** at the door end, the brightest things are the green SAFE POINT lamp (the goal), the pillar lamp and the hazard stripes. That is the right order. Nothing new competes with the action.

### Inherited nits (not blocking)

13. The big ceiling light over the middle of the tunnel is still the brightest thing on screen, with its streaky "dripping" light. It is moody, not wrong.
14. The RESTRICTED AREA plate follows the wall's perspective slope while SECTOR 4B looks level. Nobody will stop on it.
15. The "SAFE POINT" label overlaps the top of the machine's green lamp cap, at 720p and more so on the phone (`hr5-crops/saferoom-s1-3x.png`). This is UI placement, identical to earlier rounds.
16. The shutter's slats sit nearly level while the header and bottom bar slope (s4). This is only visible zoomed in.
17. Outside the door end, the opening's cage (o4) is drawn simply in flat code shapes, unchanged from main and out of scope.
