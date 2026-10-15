# First-time player review, doors r3 (after fix round 2)

I looked at the frames in route order, the way a player would see them:
- first the full 1280x720 frames (the AFTER half of each `pairs/*.png`);
- then the 2400x1080 phone frames (`pairs/*-phone.png`);
- then the 3x crops in `crops/` and a few 2x zooms of my own.

I used `fix-r2/captures/after-1280/_run.json` only to confirm where the actors were when a frame doesn't show it. These are stills only. I played nothing.

**Verdict: fix-needed.** This is the best the doors have looked, and most of what players complained about is fixed:
- Every door now reads as a door in a wall across the path, and you visibly walk through each one.
- Nothing vanishes. WOLF is no longer cut by the exit jamb and no longer stands inside the valve.
- The ending reads in the right order: WOLF goes, then the engineer, then the card.

One thing in the ending would still make a normal player stop: **when you press "leave through the hatch" at the open door, the engineer goes back to the bolt console for the closing dialogue** (j12 to j13). A few smaller visual things still pull the eye: white slivers on the junction header pipe where it meets the new wall, and a flat grey floor patch under WOLF at the exit.

## Records entry (r01 to r03)

- **fine:** I arrive through a plain steel door in a dark concrete wall at the left. It stands open into the room (r01), swings shut (r02), and the lamp beside it goes red (r03). It reads as "the door I came in by". With the leaf hidden, the doorway shows only a lit passage (r01-noleaf), so there's no painted ghost door.
- **fine:** the leaf now has a lever and some edge light (crop `r01-arrival-records-entry-3x`). It's dark and plain, but it reads as a real painted steel door, not a placeholder.
- **fine (small):** above the door there's a lit box with a light under it (crop r01 to r03, about x 1170 to 1250, y 880 to 1040). At 1x it reads as a light over the door.
- **should-fix (small, was in r2):** the light batten on the stub wall at the far left still reads as a white dash at 1x (r01 to r03, about x 5 to 75, y 252). Its body and light pool only show in the 3x crop. The same goes for the one at the Records exit (r04 to r08, about x 1200 to 1280, y 252) and the small white tick at the junction's left edge (r09 to r11, about x 5 to 20, y 325). None of this is serious, but they're the brightest dots at the screen edges.

## Records copy point and exit (r04 to r08)

- **fine (was the "pod" must-fix):** the fake navy rectangle is gone. There's a real steel door in a cross-wall under an EXIT box sign, with a grey security container beside it, all grounded and in the room's light (r04, crop `r04-copy-point-records-exit-3x`).
- **fine:** securing the copy is a separate action from leaving:
  - after the copy, the door swings open into the room with the lamp going green (r05, r06, r07);
  - the next USE walks me through it, and the open leaf stays standing in the room (r08-walk-out-0 to 2);
  - WOLF follows behind me and passes behind the near column (r08-walk-out-1, 2).
  - Nothing pops.
- **should-fix (inherited text, awaiting Nathanial):** in r04 the hint says "E: secure the first copy." while I stand right at the door, and nothing ties the copy to the container. The container is behind WOLF's head on the phone (`r04-copy-point-phone`). A player could think they're doing something to the door. The drafted line ("lock the first copy in the security container") would fix it.
- **fine (small):** the open exit leaf in r07 is a broad, nearly black slab behind the engineer. It's correct (it swings toward the camera), but at 1x it reads as "a dark doorway" more than "an open door". The lit edge and the lever in r06 help.

## Junction entry (r09 to r11)

- **fine:** it's the same door design as Records. We arrive through it, it stands open showing a passage with shelving, then it closes and the lamp goes red (r09, r10, r11). The old vault hatch is gone, and with the leaf hidden (r09-noleaf) the opening is clean.
- **should-fix (look, new this round):** where the big hazard-striped header pipe meets the new wall, the pipe ends in a flat cut with **bright white slivers** above and below it:
  - r09 to r11 about x 195 to 235, y 115 and y 210 at 1x;
  - my 2x zoom; crop `r09-after-leaving-junction-entry-3x`, about x 1535 to 1730, y 305 to 335 and y 580 to 600;
  - on the phone, `j04-blown-phone` about x 290 to 400, y 168 and y 318.

  On main the pipe ran on into an elbow with no white edges. These read as rendering glitches or a pasted cutout, at the top left of the junction where the eye lands first. The "escutcheon" the notes describe doesn't read as a collar.
- **fine:** the wall is no longer a flat black box. The joints, the damp band and the light fitting over the door make it read as concrete.

## Junction blast door (j01 to j07)

- **fine:** before the blast (j01, j02), the SEALED DOOR is a steel door in a wall that runs right across the walkway. Its foot runs over the deck to the front edge, and a red lamp sits on the near column. I understand it's in my way and that the tank release is past it.
- **fine (small):** in the blast frame (j03), dust and chips fly out on the far side of the column, into the alcove, while the leaf is still drawn in the doorway. The clean frame (`fix-r2/captures/after-1280/j04-blown-clean.png`) shows the leaf thrown flat into the alcove, so the direction makes sense. It's one frame.
- **fine (was must-fix):** WOLF waiting at the rubble now stands on the deck in front of the valve (j04, j05, crop `j04-blown-junction-blast-3x`, `j04-blown-phone`). He reads as in front of it, not inside it.
- **fine (better):** after the blast (j04), the doorway now has a ragged dark tear at its head, a bent plate, broken material on the column and rubble on both sides. It reads as "the door is gone and the frame is damaged", not as a clean slot. The detail is still small at 1x, and the label does a lot of the work, but nobody would find it odd.
- **fine:** in j05 I walk through the blown doorway myself, past WOLF.
- **should-fix (small, inherited placement):** the thrown leaf (`j04-blown-clean`, j13 bottom left) still reads as a heavy steel plate rather than a door, and its left corner lies across the cross-wall's foot. The dialogue box hides most of it in normal play.

## Junction exit door (j08 to j13)

- **fine (was should-fix):** the exit is easy to find now. The cross-wall is lit by the corner fitting and has a wall pack, an amber lamp and a visible door (j08, `j08-exit-bolt-phone`). "Hatch" in the text still doesn't match a door (draft pending).
- **fine:** the door slides into its pocket. Its striped edge stays visible and the lit passage opens behind it (j10, j11). Nothing vanishes, and the bolt sparks are short orange streaks.
- **fine (was must-fix):** WOLF waits in front of the open door with his whole body clear of the jamb (j11, j12, j13, crop `j11-hatch-open-junction-exit-3x`). The closing shot no longer has a sliced wolf.
- **should-fix (look):** the floor between the exit wall's foot and the walk line is a **flat, smooth, lighter grey patch** with no wet sheen or deck pattern. WOLF stands on it in the held closing shot (j08 to j13 about x 1000 to 1170, y 470 to 505; crop `j08-exit-bolt-junction-exit-3x` about x 840 to 1480, y 1400 to 1510). Next to the wet, reflective deck it reads as a placeholder plane.
- **fine (small):** the four back-wall pipes that end in collars at the exit wall's corner read as a stack of black discs at 3x (crop j08 about x 935 to 985, y 680 to 910). At 1x they're barely visible.
- **fine (small):** there's a faint violet line along the bottom and hinge edge of the shut exit leaf (crop j08 about x 1285, y 1000 to 1510). It's invisible at 1x.

## Ending (j12 to j15)

- **must-fix (who leaves, and how):** at the door (j12) the engineer stands right beside the open exit, between the bolt panel and WOLF, and the hint says "E: leave through the hatch."
  - **What happens when I press it:** in the closing shot one second later (j13, `j13-closing-shot-phone`), the engineer is back on the far side of the bolt panel, between the fallen tank and the console. `_run.json`: engineer x 849 in j12, 747 in j13, with WOLF unmoved at 934.
  - **Why it matters:** pressing "leave" makes my character walk (or snap) away from the door, back to the console where they started. They stand there through the closing lines, then walk all the way forward again after CONTINUE (j14-walk-out-03 to 13). This is close to what the first players described: "USE fires the leave while the engineer is still at the bolt console".
  - **The fix:** the engineer should stay at the door, or take the step toward it, when I leave.
  - **A guess, not checked:** USE at x 849 may also be landing on the bolt panel's station, so the engineer steps out to its working side (BOLT_X 747). The driver pressed USE only once between j12 and j13.
- **fine:** the order reads:
  - after CONTINUE, WOLF turns and walks through the doorway, passing behind the near column (j14-walk-out-00 to 03);
  - then I walk up and into the doorway against the lit passage (walk-out-07 to 11);
  - I pass behind the column (walk-out-12), and the doorway stays empty for a beat (walk-out-13 to 15);
  - only then does END OF SLICE come up (j15).

  Nobody fades or blinks out, and the card comes after both have left. The old "nobody walks out" problem is fixed, apart from the backwards step above.
- **fine:** the walk-out is slower now, so WOLF can be seen stepping through. That was a should-fix in r2.

## Inherited, outside these doors (not new)

- **inherited:** the mint beam line still runs through the fallen tank and the crushed sentry (j10 to j14, clearly in j13). After the sentry is down it looks like a rendering glitch.
- **inherited:** the dialogue box covers the bottom quarter during both walk-outs and hides most of the thrown leaf.
- **inherited:** a half-faded "DOOR DOWN" label ghosts at the left edge in the closing shot (j13, j14, about x 20 to 140, y 262; also `j14-walk-out-11-phone`).
- **inherited:** the sentry's yellow beam band floats across the alcove (`j04-blown-phone` right edge; `j04-blown-clean` about x 1125 to 1280, y 430 to 450).
- **inherited text:** "hatch" in the exit lines, and the container hint, are both drafts waiting on Nathanial.

## Summary for a first-time player

They'd follow the route without trouble:
- the door I came in by closes behind me;
- I secure the copy, the exit swings open, and I walk out with WOLF behind me;
- the next door closes behind us;
- the sealed door blocks the way, gets blown, and I walk through the wreck of it;
- the exit slides open and WOLF waits in front of it;
- WOLF goes, then I go, then the card.

What they'd still notice:
1. Pressing "leave" at the exit sends my character back to the bolt console for the closing lines (j12 to j13). **must-fix**
2. White slivers on the header pipe where it meets the junction entry wall (r09 to r11, j01 to j04, phone). **should-fix**
3. The flat grey floor patch under WOLF at the exit in the closing shot (j08 to j13). **should-fix**
4. The copy hint doesn't point at the container (r04, text pending). **should-fix**
5. White light dashes at the screen edges (r01 to r08). **should-fix, small**
