# First-time player review, doors r4 (after fix round 3)

## How I looked

I looked at the frames in route order, the way a player would see them:
- first the full 1280x720 frames (the AFTER half of each `pairs/*.png`);
- then the 2400x1080 phone frames (`pairs/*-phone.png`);
- then the 3x crops in `crops/`, the `-clean` captures in `fix-r3/captures/after-1280/` (no UI), and a few zooms of my own.

I used `_run.json` only to confirm where the actors were in the walk-out, and `junction_room.gd` only to learn how the blast door changes over.

These are stills only. I played nothing, so nothing below is a claim about motion or feel.

**Verdict: pass.**
- Every door now makes sense as a door: you can see where it is, how it opens, where it goes, and that you walk through it.
- The ending reads in the right order, and the engineer no longer walks back to the console.
- Nothing vanishes, hovers or looks pasted in any frame I checked.

Two things need a hands-on look or a decision from Nathanial:
- whether the blast door's 0.15 s change from "breaking" to "lying in the lane" reads as a throw in motion;
- the two pending text drafts.

Neither would make a normal player stop in these stills.

## Records entry (r01 to r03)

- **fine:** I arrive by a plain steel door at the left (r01, crop `r01-arrival-records-entry-3x`).
  - It stands open into the room as a lit grey leaf with a lever. It reads at once as "the door I came in by", no longer as a black slab.
  - It swings shut (r02), and the lamp beside it goes red (r03, crop `r03-arrival-closed-records-entry-3x`).
  - With the leaf hidden (r01-noleaf), the doorway is a real opening onto a lit passage.
- **fine (was should-fix):** the light batten on the stub wall at the far left is now a grey fitting, not a white dash (r01 to r03, about x 0 to 75, y 250). Nothing at the screen edge pulls the eye now.
- **fine (small):** the shut door is dark (r02, r03 about x 100 to 145, y 320 to 505). That is right for a door in shadow, and the red lamp beside it tells you it's shut.

## Records copy point and exit (r04 to r08)

- **fine:** the exit is a steel door in a concrete cross-wall, under an EXIT sign, with a grey security container beside it (r04, crop `r04-copy-point-records-exit-3x`). Nothing looks like a missing image.
- **fine:** the order works:
  - after I secure the copy, the door swings open toward me with its lever side showing, and the lamp goes amber (r06, crop `r06-exit-opening-2-records-exit-3x`), then green (r07);
  - the open leaf is now a lit grey door standing in the room (r07, crop `r07-exit-open-records-exit-3x`), not the near-black card it was in r3;
  - the next USE walks me past it and behind the near column, out of sight (r08-walk-out-0);
  - WOLF follows: in front of the open leaf, then behind the column (r08-walk-out-1, 2; phone `r08-walk-out-1-phone`).
  - Nothing pops and nobody blinks out.
- **fine (was should-fix):** the batten at the right edge is no longer a white dash (r04 to r08, about x 1195 to 1250, y 252).
- **should-fix (inherited text, awaiting Nathanial):** in r04 (and `r04-copy-point-phone`) the hint says "E: secure the first copy." while I stand next to the door, and nothing points at the container. A player could think USE does something to the door. The drafted line, "E: secure the first copy in the container.", would fix it.
- **fine (small):** the floor beyond the column, at the screen's right edge, is a plain grey plane with less wet sheen than the room's deck (r07, r08, about x 1180 to 1280, y 480 to 520). It is small, at the edge, and reads as the next room's floor in other light.
- **fine (not doors):** the camera pushes in a little for the copy beat (r05, r06) and comes back out (r07). That reads as a deliberate beat.

## Junction entry (r09 to r11)

- **fine:** it uses the same door design as Records.
  - The leaf stands open as a lit grey door with a lever, against a passage with shelving (r09, crop `r09-after-leaving-junction-entry-3x`).
  - It closes and the lamp goes red (r10, r11).
  - The opening is clean with the leaf hidden (r09-noleaf).
- **fine (was should-fix):** the white slivers on the big header pipe are gone. The pipe now turns up into its own elbow at the wall's edge (r09 to r11 and j04 at about x 225 to 260, y 95 to 200; my 3x zoom; `r09-after-leaving-phone`). It looks like the room's own pipework.
- **fine:** the edge where the dark concrete wall meets the pipe room is a straight vertical line (x 222). It reads as the front of a wall.

## Junction blast door (j01 to j07)

- **fine:** before the blast, SEALED DOOR is a steel door in a wall that crosses the walkway, with a red lamp on the column (j01, crop `j01-sealed-junction-blast-3x`). The pale threshold plank is gone. The sill now matches the deck.
- **fine:** "why did I have to blow it?" now has an answer on screen: the wall and its stub stand right across the deck (j02, `j02-fuse-clean`).
- **fine:** after the blast there's a torn, empty doorway in the wall (j04, crop `j04-blown-junction-blast-3x`).
  - The leaf lies thrown in the lane beyond as a heavy, bowed steel plate. Its corner is crushed and it rests on rubble (`j04-blown-clean`, my 2.5x zoom).
  - Concrete chunks lie at the foot of the wall.
  - It no longer reads as a clean slab, and it's clear of the wall's foot.
- **fine:** I walk through the wreck (j05). The engineer stands in the torn doorway, behind the near column, with WOLF on the rubble in front.
- **fine (was a newcomer must-fix):** the blast is grey-blue dust with orange sparks and chips (j03, crop `j03-blast-frame-junction-blast-3x`). The flat beige blob is gone.
- **should-fix (check in play; I can't judge it from stills):**
  - In j03, the moment of the blast, the doorway is already empty and the leaf is already lying in its final spot (`j03-blast-frame-clean`, x 1020 to 1280, y 500 to 585).
  - The code shows the breaking leaf for only 0.15 s (`DOOR_BREAK_SECONDS`), and then the leaf appears on the floor, about 150 screen px from the doorway, behind the wall's stub.
  - The screen flash and dust may hide that well enough, or a player may see the door "teleport". The dust in j03 is light and covers neither spot.
  - Someone needs to play this beat once. If it reads as a teleport, a few frames of the leaf in flight, or denser dust over the landing spot, would fix it.
- **fine (small):** the DOOR DOWN plate sits over the doorway's head (j03 to j07). It doesn't hide anything that matters. Moving it is Nathanial's call.

## Junction exit (j08 to j11)

- **fine:** the exit is a sliding steel door in a concrete wall at the right, with a lamp and a light over it (j08, crop `j08-exit-bolt-junction-exit-3x`). It reads as the same kind of door as the corridor one.
  - Popping the bolt sets off sparks at the panel, and the lamp goes green (j10).
  - The leaf slides back and shows a lit passage with a hazard-striped jamb (j11, crop `j11-hatch-open-junction-exit-3x`).
  - With the leaf hidden, the shut door is a real opening (j08-noleaf).
- **fine (was should-fix):** the floor under WOLF at the exit is now the room's wet, reflective deck (j08 to j13, about x 1000 to 1170, y 470 to 505). It no longer looks like a grey placeholder plane.
- **fine (was fine/small):** the four back-wall pipes now enter the exit wall through rings (crop j08 about x 935 to 985, y 690 to 910). At 1x they read as pipes going into the wall, not as black discs.
- **fine:** no violet line around the shut leaf at any zoom I tried.
- **fine (small):** the exit wall is a paler, greyer concrete than the blue room. It is the brightest big surface in the closing shot, so it pulls the eye to where I should go, which helps.
- **should-fix (inherited text, awaiting Nathanial):** the lines still say "hatch" ("The hatch is opening.", "The hatch slides open.", "E: leave through the hatch.") for something that now plainly looks like a door (j10 to j12). A player won't stop over it, but it's a mismatch.

## Ending (j12 to j15)

- **fine (was the r3 must-fix):** at the open door (j12) I stand beside the exit and the hint says "E: leave through the hatch."
  - When I press it, the closing shot (j13, `j13-closing-shot-phone`) keeps the engineer right there, between the bolt panel and WOLF, at the door.
  - `_run.json`: engineer x 849.2 in both j12 and j13.
  - He no longer walks or snaps back to the console.
- **fine:** who leaves, and in what order:
  - WOLF goes first: he walks right, his tail in front of the lit doorway and his head going behind the near column (j14-walk-out-00 to 02);
  - he's gone by 03;
  - then the engineer walks up, stands in front of the lit doorway (walk-out-07, `j14-walk-out-07-phone`) and passes behind the column (08);
  - the doorway stays empty for a beat (09 to 11);
  - then END OF SLICE comes up (j15).
  - Nobody fades, blinks out or overlaps a door frame.
- **fine:** where to go next is clear all the way through. The exit is the lit door at the right with a green lamp, the board says EXIT OPEN, and WOLF waits in front of it.

## Inherited, outside these doors (not new)

- **inherited:** the mint sentry beam line still runs through the fallen tank and the crushed sentry (j10 to j14, clearest in j13 and `j13-closing-shot-phone`). After the sentry is down, it looks like a rendering glitch.
- **inherited:** the sentry's yellow beam band floats across the alcove (j04 and j05 at the right edge; `j04-blown-phone` about x 1410 to 1600, y 530 to 570).
- **inherited:** a half-faded "DOOR DOWN" label ghosts at the left edge in the closing shot (j13, j14 about x 30 to 130, y 262; `j13-closing-shot-phone` about x 50 to 150, y 325).
- **inherited:** the dialogue box covers the bottom quarter during both walk-outs and hides much of the thrown leaf (j04 to j07, r08).

## Summary for a first-time player

They'd follow the route without anything looking wrong:
- the door I came in by closes behind me;
- I secure the copy, the exit swings open, and I walk out with WOLF behind me;
- the next door closes behind us;
- the sealed door blocks the way, gets blown, and its leaf lies bent in the lane while I walk through the hole;
- the exit slides open and WOLF waits in front of it;
- WOLF goes, then I go, then the card.

Still open:
1. The blast door's leaf goes from the doorway to the floor in 0.15 s (j03, j04). It needs one hands-on look. **should-fix (check in play)**
2. The copy hint doesn't point at the container (r04). The text draft is pending. **should-fix**
3. "Hatch" in the exit lines for what is now a door (j10 to j12). The text draft is pending. **should-fix**
4. The four inherited items above.
