# First-time player review, doors r5 (after fix round 4)

## How I looked

I looked at the frames in route order, the way a player would see them:
- the full 1280x720 frames first (`fix-r4/captures/a5-1280/*.png`, the same frames as the AFTER half of `pairs/*.png`);
- then the 1920x1080 phone frames (`a5-phone`, the `pairs/*-phone.png` frames);
- then the 3x crops in `crops/`, the `-clean` captures with no UI, and my own 2x to 4x zooms. The zooms are named in backticks below. They were temporary and are deleted; to remake one, crop the matching `-clean` capture.

I read `junction_room.gd` (`_set_door_flight`) and the capture driver only to work out why two blast frames looked wrong.

These are stills only. I played nothing, so nothing below is a claim about motion or feel.

**Verdict: pass.**
- Every door still reads as a real door: you can see where it is, how it opens, where it leads, and that you walk through it.
- The round 4 swing leaves no longer go black.
- The ending reads in the right order: WOLF leaves first, then the engineer, then the card.
- Nothing vanishes, hovers or looks pasted on in the frames I checked.

The one new problem is in the evidence, not the game:
- In both packaged runs, `j03-blast-frame` shows no blast.
- `j03-flight-20` shows the leaf nearly landed, so the packaged flight runs backwards from 20 to 45.

The game code and the separate `checks/round-4/flight-sequence.png` show the throw in the right order. The thrown leaf still needs the hands-on check already listed.

## Records entry (r01 to r03, swing frames)

- **fine:** I come in by a plain steel door on the left. It stands open as a lit grey leaf with a lever (r01, crop `r01-arrival-records-entry-3x`).
  - It swings shut, and the lamp goes red (r02, r03).
  - With the leaf hidden, the doorway is a real opening onto a lit passage (r01-noleaf).
- **fine (was must-fix M1):** the swing frames now read as one door turning on its hinge:
  - at 50 % open, a lit grey face (`r01-swing-50`);
  - at 30 %, nearly edge-on, a thin dark edge with the lit reveal beside it (`r01-swing-30`);
  - at 20 % and 10 %, a dark leaf, the same tone as the shut door in r03 (`r01-swing-20`, `r01-swing-10`).

  It no longer turns into a black slab partway. A door in shadow that goes darker as it closes looks right.

## Records copy point and exit (r04 to r08)

- **fine:** the exit is a steel door in a concrete cross-wall, under an EXIT sign, with a dark security container beside it (r04, crop `r04-copy-point-records-exit-3x`).
- **fine:** after the copy, the door swings toward me with its lever showing, and the lamp goes amber (r06, crop `r06-exit-opening-2-records-exit-3x`), then green (r07).
  - Open, the leaf is a lit grey door standing in the room (r07, my 4x zoom `r07-exit-open-z`).
  - It is a touch lighter than the concrete now (the 5 % the builder flagged). You can't see that as a player; it just reads as painted steel catching the wall light.
- **fine:** the walk-out works (r08-walk-out-0/1/2, zooms `r08-walk-out-0-z`, `r08-walk-out-2-z`).
  - I go past the leaf, through the doorway, and behind the near column into the space beyond.
  - WOLF follows: its tail crosses in front of the open leaf, its back legs are in the doorway gap, and its body is past the column.
  - Nobody pops out of view, and nothing overlaps wrongly.
- **fine (small):** a hairline of light sits along the top of the open leaf near the hinge (r07/r08, about x 1105-1130, y 347). At normal size it reads as the leaf's top edge.
- **should-fix (inherited text, awaiting Nathanial):** in r04 the hint says "E: secure the first copy." while I stand at the door. The drafted "…in the container." would fix it.
- **fine (small, inherited):** the floor beyond the column at the right edge is plain grey (r07, r08). It reads as the next room.

## Junction entry (r09 to r11, swing frames)

- **fine:** it uses the same door design as Records.
  - Open, it is a lit leaf against a passage with shelving (r09).
  - It closes (r10), and the lamp goes red (r11).
  - The swing strip (`r09-swing-10/20/30/50`, my strip `r09sw`) reads as a door turning, with no black frame.
- **fine (was should-fix S1):** the steam no longer stops on a ruler-straight line at the wall corner. It drifts a little over the concrete edge (r09, crop `r10-entry-closing-junction-entry-3x`, about 3x x 1600-1630).

## Junction blast door (j01 to j07)

- **fine:** SEALED DOOR is a steel door in a concrete wall that crosses the walkway, with a red lamp on the column (j01, crop `j01-sealed-junction-blast-3x`). "That door is our way through" (r09) makes sense.
- **should-fix (evidence, not the game): the packaged blast and flight frames are wrong or out of order.**
  - `j03-blast-frame` is the same picture as `j02-fuse`: only 302 pixels differ at 1280, and the phone frames match too. It shows no blast at all.
  - `j03-flight-20` shows the leaf low and nearly flat at the far right, almost the same as `j03-flight-90` (465 pixels differ at 1280, against about 1,300 for any other pair). Then `j03-flight-45` shows it standing up again by TANK RELEASE.
  - The phone run does the same (my strip `phone-flight.png`).
  - Read in order, the leaf seems to land, jump back up, then fall again.
  - The game code doesn't do that. `_set_door_flight(0.2)` gives about 12° of tip, near the doorway. `checks/round-4/flight-sequence.png`, from another run, shows the right order: breaking in the doorway, barely tipped by the column, then 33°, 56°, 76°, landed.
  - So the driver's first frozen pose seems to show the tween's own late pose instead of 0.2.
  - Please recapture j03-blast-frame and j03-flight-20, or drop them from the package, so the next reader isn't misled.
- **fine (stills only):** 45, 70 and 90 tip further each time and come nearer the camera (my strips `fl1`, `fl2`), and the leaf lands as a flat steel slab in a dust burst (`j03-landed`, `c-landed`).
  - Lying in j04 (zoom `j04z`), it looks like a heavy door slab on the deck, with no gap under it and no hover.
  - Whether the throw reads in motion still needs the hands-on check.
- **fine:** the blown doorway is a real opening, and I walk through it: in j05 the engineer stands in the doorway, half hidden by the torn jamb (zoom `j05z`).
- **fine:** the rubble at the foot of the column and the lying leaf give "WOLF heads for the rubble" something to point at (j03-landed, j04).
- **inherited:** the sentry's amber beam band floats across the alcove (j03-landed, j04, j05; phone j04, about x 1690-1850).
- **inherited:** the hint and dialogue boxes cover most of the lying leaf and the landing (j03-landed, j04, j05).

## Junction exit door and the ending (j08 to j15)

- **fine:** the exit is a sliding steel door in a concrete wall, with a wall lamp, a lamp box and a hazard-striped edge.
  - It slides back into its pocket as it opens (j10, crop `j10-hatch-opening-junction-exit-3x`).
  - Open, it shows a lit passage (j11, crop `j11-hatch-open-junction-exit-3x`).
  - Nothing vanishes. WOLF stands in front of the wall, so covering part of the frame is natural.
- **fine:** the order of the ending is right.
  - j12 and j13: I am at the bolt console. The prompt says "E: leave through the hatch", and WOLF waits by the door.
  - j14-walk-out-00 to 04: WOLF goes first. Its tail crosses in front of the doorway, its body goes behind the near column, and its head comes out in the space beyond (zoom `wz-a`). It is gone by 05.
  - j14-walk-out-05 to 09: I walk to the door, step into the doorway, and turn behind its right jamb (zoom `wz-b`).
  - 10 to 12: the empty doorway holds for a beat.
  - j15: END OF SLICE comes after both of us are out.

  That is the first time this ending reads like people leaving.
- **should-fix (inherited text, awaiting Nathanial):** the lines say "hatch" (j08 "pop the exit bolt by the hatch", j10, j12) while the picture is a door. The drafted change to "door" would fix it.
- **inherited:** the mint sentry beam line still runs through the fallen tank and the crushed sentry (j10 to j14, phone j14).
- **inherited:** a half-faded DOOR DOWN label ghosts at the left edge (phone j14-walk-out-02, about x 70-170, y 390).
- **inherited:** the dialogue box sits over the floor during the whole walk-out. It doesn't hide either actor.

## Is it clear where to go next?

Yes, at every step:
- Records: the EXIT sign and the green lamp;
- the junction: "That door is our way through", SEALED DOOR, then DOOR DOWN;
- the end: EXIT OPEN, and the lit passage behind the slid-back door.

Phone frames match the laptop ones.

## Summary

| Mark | Item | Frames |
|---|---|---|
| should-fix (evidence) | j03-blast-frame shows no blast; j03-flight-20 shows the near-landed pose, so the packaged flight runs out of order | j02 vs j03-blast-frame, j03-flight-20 vs -90, both resolutions |
| should-fix (inherited text, Nathanial) | "secure the first copy" at the door; "hatch" for a door | r04; j08, j10, j12 |
| needs hands-on | the thrown leaf in motion, and the walk-outs at speed | j03, r08, j14 |
| inherited | beam band in the alcove; beam line through the tank; DOOR DOWN ghost; boxes covering the leaf | j03-j05; j10-j14; phone j14 |
| fine | all four swing leaves, both walk-outs, the blast doorway, the sliding exit, the ending order and the card | r01-r11, j01, j04-j15 |
