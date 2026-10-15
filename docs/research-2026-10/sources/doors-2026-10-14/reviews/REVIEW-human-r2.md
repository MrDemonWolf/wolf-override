# First-time player review, doors r2 (after fix round 1)

I looked at the final frames in route order, the way a player would see them. First the full 1280x720 frames in `fix-r1/captures/after-1280/`, then the 1920x1080 phone frames in `after-phone/`, then the 3x crops in `shots/crops/`. I used `_run.json` only to confirm where WOLF and the engineer were when a frame doesn't show them. These are stills only. I played nothing.

**Verdict: fix-needed.** This is much better than r1. The bright pasted walls are gone. Every door opens in a way I can see, and nothing pops out of existence. The Records exit and the ending now read in the right order. Two things would still make a normal player stop and look:

- In the closing shot, the last image before the end card, WOLF is cut in half by the exit door's jamb, and his back half sticks out of the dark wall (j13).
- At the rubble, WOLF stands inside the valve (j04, j05).

The blown door also still doesn't look blown.

## Records entry (r01 to r03)

- **fine:** I arrive through a steel door that stands open behind me (r01). It swings shut (r02) and the lamp goes red (r03). It reads as "the door I came in by". Nothing vanishes.
- **fine (was should-fix):** the left strip is now dark, so it no longer jumps out as a pale clean wall.
- **should-fix (look):** the door leaf is a flat grey rectangle with no texture, wear or edge thickness, both open (crop `r01-arrival-records-entry-3x`) and shut (`r03`). It looks like a 3D placeholder next to the painted purge-queue machine.
- **should-fix (small):** the closer arm on top of the shut door reads as a grey sliver floating above the leaf (crop `r03-arrival-closed-records-entry-3x`).
- **should-fix (small):** the small white light tube at top left (r01 to r03, about x 30, y 253) reads as a stray white dash. At 1x I can't see a fitting holding it. The same thing appears at the Records exit (r04 to r08, about x 1235, y 253).

## Records copy point and exit (r04 to r08)

- **fine (was must-fix):** the exit wall is no longer a bright blank render. It sits in the room's darkness (r04, r07).
- **should-fix (look):** that right third is still a big smooth dark slab with almost nothing on it: two faint plates, the sign and the door (crop `r04-copy-point-records-exit-3x`). The rest of the room is all painted pipes, trusses and racks. It reads as "empty black area" more than "concrete wall".
- **fine:** EXIT now sits on a sign box above the door, so it no longer floats on a bare wall.
- **should-fix:** the security container is still a clean flat grey filing cabinet (r04 to r08). The dial helps a little, but it looks like a 3D office prop, and nothing says it is where the copy goes.
- **fine:** the exit door swings open into the room with the lamp turning green (r05, r06, r07). The next USE walks me through it into the lit passage on the right (r08-walk-out-0). WOLF follows: he is at the door in r08-walk-out-1, partly behind the near jamb as he goes through, and in the passage in r08-walk-out-2 before the cut. The old "WOLF teleports" problem is gone, and the order (me first, WOLF after) reads.
- **should-fix (small):** as in Records entry, the open exit leaf is a flat dark slab (crop `r06-exit-opening-2-records-exit-3x`).

## Junction entry (r09 to r11)

- **fine (was inherited problem):** the old camera-facing vault hatch is gone. I arrive in front of an open steel door that closes behind us (r09, r10, r11). It reads as "the door we just came through".
- **should-fix (look):** that door sits in a tall, plain, dark block at the left edge (crop `r09-after-leaving-junction-entry-3x`), set against the most detailed pipework in the slice. The open leaf in r09 is a pale flat panel. The junction's left edge now reads as a black box with a door in it.

## Junction blast door (j01 to j07)

- **fine (better):** before the blast (j01, j02), the "SEALED DOOR" reads as a door set in a wall turned across the walkway. The wall's foot runs out across the floor, and a red lamp marks the door. In j02 the red/black danger line runs right through it. I would now guess the door is in my way. It is still narrow and dark at laptop size.
- **should-fix (small):** a white tube light pokes out just above the "SEALED DOOR" label (j01, j02, r09 to r11, about x 825 to 850, y 280). At 1x it reads as a stray white tick.
- **fine (was should-fix):** the blast (j03) is grey dust, hard spark streaks and chips coming out past the column. The beige blob is gone.
- **should-fix:** after the blast (j04 to j07, crop `j04-blown-junction-blast-3x`), the doorway reads as a dark slot between the valve and the column with a rubble pile in front. At normal size I can't see the spalled concrete, rebar, sagging head or soot that the notes describe. Without the "DOOR DOWN" label I wouldn't know it had been blown. It looks like an open doorway with gravel in it.
- **should-fix:** the thrown leaf (clean frame `j07-tank-drop-clean`, phone `j13-closing-shot`, bottom left) reads as a big dark steel plate or pallet on the deck, not a blasted door. The bent bolts and hinge knuckles only show up close. It does sit on the deck and doesn't hover, and in normal play the dialogue box hides most of it.
- **must-fix (overlap):** WOLF's waiting spot at the rubble puts him right inside the valve (j04, j05, phone `j04-blown`, crop `j05-walking-through-junction-blast-3x`). His feet are on the valve's base line, his body covers the pipes and base, and the wheel sticks up through his back. He is out of the column now, but this is the same "WOLF overlaps things" look the first players named. On the phone it is one of the most noticeable things on screen.
- **fine (was should-fix):** in j05 I can see the engineer in the doorway as he walks through. He is no longer hidden behind the column.

## Junction exit door (j08 to j13)

- **should-fix:** j08 and j09 say "pop the exit bolt by the hatch". The exit is now on screen, but it is a dark door in a dark wall, with a small amber lamp as the only sign (j08, phone `j08-exit-bolt`, about x 1090 to 1180). I'd find it only because the lane ends there. The word "hatch" still doesn't match a door (text draft pending, noted).
- **should-fix (look):** the exit's cross-wall (x 995 to 1280) is the same smooth dark slab as Records, next to the painted, lit room.
- **fine (was should-fix):** the bolt sparks (j10, crop `j10-hatch-opening-junction-exit-3x`) are short orange streaks now, not floating mint bubbles.
- **fine:** the door slides open, its striped edge stays in the pocket, and the opening shows a lit passage (j10, j11). Nothing vanishes.
- **must-fix (overlap, final shot):** in j11, j12 and the closing shot j13 (crops `j12-at-the-door-junction-exit-3x`, `j13-closing-shot-junction-exit-3x`, phone `j13-closing-shot`), WOLF stands across the threshold. His head and front legs are in the doorway, the near jamb hides his middle, and his back legs and tail stand out to the right of the jamb, against what reads as solid dark wall. I see a wolf sliced by the door frame with his rear coming out of the wall. The passage beyond is too dark to read as space he could be standing in. This is the frame held on screen while I read the last dialogue, so it gets the longest look of anything in the slice.

## Ending (j13 to j15)

- **fine:** the order reads. After CONTINUE, WOLF is already through and out of sight (j14-walk-out-00; `_run.json` shows him walking on to x 1073 and then 1098 behind the stub, so he goes rather than blinks out). I then walk to the doorway (j14-walk-out-01), step in and pass behind the near jamb (walk-out-02 shows just a red sliver), and the doorway is empty for a beat (walk-out-03) before END OF SLICE comes up (j15). WOLF leaves first and I follow, through the door I opened, and nobody fades or pops.
- **fine (was should-fix):** the tighter closing camera makes the exit a proper part of the frame, especially on the phone.
- **should-fix (small):** I never see WOLF take a step through. He is in the doorway in j13 and gone in the first walk-out frame. In play the walk may show, but in these stills it looks like a cut.
- **should-fix (small):** at walk-out-02 I disappear behind the jamb rather than visibly into the lit passage. It works, but walking a step into the light would read more like "leaving".

## Inherited, outside these doors

- **inherited:** the mint (earlier yellow) beam line still runs through the fallen tank and crushed sentry from j10 to j14. After the sentry is down it looks like a rendering glitch.
- **inherited:** the dialogue box covers the bottom quarter during both walk-outs and hides most of the thrown leaf.
- **inherited:** in j13 to j14, a half-faded "DOOR DOWN" label ghosts at the far left edge (about x 30 to 150, y 262).
- **inherited:** the sentry's yellow beam band in phone `j04-blown` (right edge) floats across the alcove.

## Summary for a first-time player

They'd follow the route without trouble:
- the door I came in by closes behind me;
- the copy is secured and we both walk out of Records;
- the sealed door is in the way, gets blown, and I walk through it;
- the exit slides open, WOLF goes, then I go, then the card.

That part is fixed. What they'd still notice:
1. WOLF cut in half by the exit jamb in the closing shot, with his rear standing in the wall (must-fix).
2. WOLF standing inside the valve while he waits (must-fix).
3. The blown doorway and the thrown leaf don't look blasted (should-fix).
4. The new walls are now dark rather than bright, but they are still empty smooth slabs next to the painted rooms. The door leaves and the container are flat, clean 3D shapes (should-fix).
5. The junction exit is hard to spot before the bolt (should-fix).
